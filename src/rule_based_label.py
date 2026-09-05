import argparse
import json
from typing import Any, Dict, List, Tuple
import pandas as pd


def safe_str(value: Any) -> str:
    return "" if pd.isna(value) else str(value).strip().lower()


def load_rule_config(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        config = json.load(f)
    print(f"[OK] Loaded rule labeling config: {path}")
    return config


def detect_kill_chain_stage(text: str, kc_dict: Dict[str, List[str]]) -> Tuple[bool, List[str]]:
    matched_stages = []
    for stage, keywords in kc_dict.items():
        if any(k.lower() in text for k in keywords):
            matched_stages.append(stage)
    return (len(matched_stages) > 0, matched_stages)


def apply_rules(row: pd.Series, config: Dict[str, Any]) -> Tuple[int, str]:
    # -------- Required fields --------
    event_type = safe_str(row.get("event_type"))
    alert_category = safe_str(row.get("alert.category"))
    alert_signature = safe_str(row.get("alert.signature"))
    http_uri = safe_str(row.get("http.uri"))
    wazuh_desc = safe_str(row.get("rule.description"))
    proto = safe_str(row.get("proto"))

    severity_raw = row.get("alert.severity")
    signature_id_raw = row.get("alert.signature_id")

    # -------- Normalize numeric fields --------
    try:
        severity = int(severity_raw) if pd.notna(severity_raw) else None
    except (TypeError, ValueError):
        severity = None

    try:
        signature_id = int(signature_id_raw) if pd.notna(signature_id_raw) else None
    except (TypeError, ValueError):
        signature_id = None

    # -------- Condition 1: event_type = alert --------
    cond_event_type = (event_type == "alert")

    # -------- Condition 2: severity high risk --------
    cond_severity = severity in config["high_risk_severity_values"]

    # -------- Condition 3: category trusted --------
    trusted_categories = {c.lower() for c in config["trusted_threat_categories"]}
    cond_category = alert_category in trusted_categories

    # -------- Condition 4: signature_id in known simulated signatures --------
    known_sig_ids = set(config["known_simulated_signature_ids"])
    cond_signature_id = signature_id in known_sig_ids

    # -------- Condition 5: kill chain stage can be associated --------
    combined_text = f"{alert_signature} {http_uri} {wazuh_desc} {proto}"
    cond_kc, matched_stages = detect_kill_chain_stage(
        combined_text.lower(),
        config["kill_chain_keywords"]
    )

    # -------- Final conjunctive rule --------
    is_malicious = all([
        cond_event_type,
        cond_severity,
        cond_category,
        cond_signature_id,
        cond_kc
    ])

    inferred_stage = "|".join(matched_stages) if matched_stages else ""

    return (1 if is_malicious else 0, inferred_stage)


def main():
    parser = argparse.ArgumentParser(description="Compliant rule-based IDS alert labeling")
    parser.add_argument("--input-csv", default="combined_ids_logs.csv")
    parser.add_argument("--output-csv", default="rule_labeled_ids_logs.csv")
    parser.add_argument("--config-file", default="config/rule_label_config.json")
    args = parser.parse_args()

    df = pd.read_csv(args.input_csv)
    config = load_rule_config(args.config_file)

    results = df.apply(lambda row: apply_rules(row, config), axis=1)
    df["rule_based_label"] = results.apply(lambda x: x[0])
    df["rule_inferred_kill_chain_stage"] = results.apply(lambda x: x[1])

    df.to_csv(args.output_csv, index=False, encoding="utf-8-sig")

    print(f"[OK] Saved rule-labeled dataset: {args.output_csv}")
    print("\nRule-based label distribution:")
    print(df["rule_based_label"].value_counts(dropna=False))


if __name__ == "__main__":
    main()