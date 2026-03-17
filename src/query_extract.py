import argparse
import pandas as pd


DEFAULT_COLUMNS = [
    'alert_id',
    'src_ip',
    'dest_ip',
    'timestamp',
    'alert.signature',
    'alert.category',
    'proto',
    'app_proto',
    'flow_id',
    'alert.severity',
]


def main() -> None:
    parser = argparse.ArgumentParser(description='Extract malicious alerts for OpenCTI lookup.')
    parser.add_argument('--input-csv', default='classification_predictions.csv')
    parser.add_argument('--output-csv', default='opencti_query_keywords.csv')
    args = parser.parse_args()

    df = pd.read_csv(args.input_csv)

    label_col = 'predicted_label' if 'predicted_label' in df.columns else 'final_label'
    if label_col not in df.columns:
        raise ValueError("Input CSV must contain 'predicted_label' or 'final_label'.")

    malicious_df = df[df[label_col] == 1].copy()
    available_columns = [c for c in DEFAULT_COLUMNS if c in malicious_df.columns]
    if not available_columns:
        raise ValueError('No expected OpenCTI query columns found in the input CSV.')

    keywords_df = malicious_df[available_columns].copy()
    dedupe_subset = [c for c in ['alert_id', 'src_ip', 'dest_ip', 'alert.signature'] if c in keywords_df.columns]
    if dedupe_subset:
        keywords_df = keywords_df.drop_duplicates(subset=dedupe_subset)

    keywords_df.to_csv(args.output_csv, index=False, encoding='utf-8-sig')
    print(f'[OK] Saved OpenCTI query input: {args.output_csv}')
    print(keywords_df.head())


if __name__ == '__main__':
    main()
