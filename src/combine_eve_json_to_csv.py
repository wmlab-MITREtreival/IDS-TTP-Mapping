import argparse
import hashlib
import json
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import pandas as pd

FILE_MAP: Dict[str, Tuple[str, str]] = {
    'eve_1.json': ('malicious', 'L1P1'),
    'eve_2.json': ('malicious', 'L1P2'),
    'eve_3.json': ('malicious', 'L1P3'),
    'eve_4.json': ('malicious', 'L1P4'),
    'eve_5.json': ('malicious', 'L1P5'),
    'eve_l2_1.json': ('malicious', 'L2P1'),
    'eve_l2_2.json': ('malicious', 'L2P2'),
    'eve_l2_3_ex_4.json': ('malicious', 'L2P3'),
    'eve_l2_4.json': ('malicious', 'L2P4'),
    'eve_l3_1.json': ('malicious', 'L3P1'),
    'eve_l3_2.json': ('malicious', 'L3P2'),
    'eve_wifi.json': ('malicious', 'WiFi'),
    'eve_normal.json': ('normal', 'NormalTraffic'),
}


def make_alert_id(filename: str, line_number: int, entry: dict) -> str:
    basis = f"{filename}|{line_number}|{entry.get('timestamp', '')}|{entry.get('src_ip', '')}|{entry.get('dest_ip', '')}|{entry.get('flow_id', '')}"
    digest = hashlib.sha256(basis.encode('utf-8')).hexdigest()[:12]
    return f"ALERT-{digest}"


def iter_logs(folder: Path, file_map: Dict[str, Tuple[str, str]]) -> Iterable[dict]:
    skipped_files = 0
    bad_lines = 0

    for filename, (label, level_phase) in file_map.items():
        path = folder / filename
        if not path.exists():
            print(f"[WARN] Missing file: {path}")
            skipped_files += 1
            continue

        with path.open('r', encoding='utf-8') as f:
            for line_number, line in enumerate(f, start=1):
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    bad_lines += 1
                    continue

                entry['label'] = label
                entry['level_phase'] = level_phase
                entry['subsystem_type'] = 'NIDS'
                entry['alert_id'] = make_alert_id(filename, line_number, entry)
                entry['source_file'] = filename
                yield entry

    print(f"[INFO] Missing input files: {skipped_files}")
    print(f"[INFO] Bad JSON lines skipped: {bad_lines}")


def main() -> None:
    parser = argparse.ArgumentParser(description='Combine all log files and flatten them to CSV.')
    parser.add_argument('--input-dir', default='.', help='Directory containing EVE & alerts JSON files.')
    parser.add_argument('--output-json', default='combined_ids_logs.json')
    parser.add_argument('--output-csv', default='combined_ids_logs.csv')
    args = parser.parse_args()

    folder = Path(args.input_dir)
    combined_logs: List[dict] = list(iter_logs(folder, FILE_MAP))

    if not combined_logs:
        raise RuntimeError('No logs were combined. Check input directory and filenames.')

    output_json = Path(args.output_json)
    with output_json.open('w', encoding='utf-8') as f_out:
        for entry in combined_logs:
            f_out.write(json.dumps(entry, ensure_ascii=False) + '\n')

    flat_records = pd.json_normalize(combined_logs)
    flat_records.to_csv(args.output_csv, index=False, encoding='utf-8-sig')

    print(f"[OK] Combined JSON: {output_json}")
    print(f"[OK] Flattened CSV: {args.output_csv}")
    print(f"[OK] Total records: {len(flat_records)}")
    if 'label' in flat_records.columns:
        print(flat_records['label'].value_counts(dropna=False))


if __name__ == '__main__':
    main()
