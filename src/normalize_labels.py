import argparse
import pandas as pd


LABEL_MAP = {
    'malicious': 1,
    'normal': 0,
    'benign': 0,
    '1': 1,
    '0': 0,
    1: 1,
    0: 0,
}


def normalize_label(val):
    if pd.isna(val):
        return pd.NA
    if isinstance(val, str):
        val = val.strip().lower()
    return LABEL_MAP.get(val, pd.NA)


def compute_final(row: pd.Series):
    dataset_label = row.get('label_num', pd.NA)
    rule_label = row.get('rule_based_label_num', pd.NA)

    # If either source marks malicious, final is malicious
    if dataset_label == 1 or rule_label == 1:
        return 1

    # If both are explicitly benign, final is benign
    if dataset_label == 0 and rule_label == 0:
        return 0

    # If one is benign and the other missing, keep benign
    if dataset_label == 0 and pd.isna(rule_label):
        return 0
    if rule_label == 0 and pd.isna(dataset_label):
        return 0

    # If both missing, mark unknown (or change to 0 if you prefer)
    return pd.NA


def main() -> None:
    parser = argparse.ArgumentParser(description='Normalize labels and compute final_label.')
    parser.add_argument('--input-csv', default='rule_labeled_ids_logs.csv')
    parser.add_argument('--output-csv', default='final_labeled_ids_logs.csv')
    args = parser.parse_args()

    df = pd.read_csv(args.input_csv)

    if 'label' not in df.columns:
        raise ValueError("Missing 'label' column in input CSV.")
    if 'rule_based_label' not in df.columns:
        raise ValueError("Missing 'rule_based_label' column in input CSV.")

    df['label_num'] = df['label'].apply(normalize_label)
    df['rule_based_label_num'] = df['rule_based_label'].apply(normalize_label)
    df['final_label'] = df.apply(compute_final, axis=1)

    df.to_csv(args.output_csv, index=False, encoding='utf-8-sig')

    print(f"[OK] Saved normalized labeled dataset: {args.output_csv}")
    print("\nFinal label distribution:")
    print(df['final_label'].value_counts(dropna=False))


if __name__ == '__main__':
    main()
    
    