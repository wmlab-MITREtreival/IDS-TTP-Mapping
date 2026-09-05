import argparse
import os
import time
from typing import Dict, List, Optional

import pandas as pd
import requests

OPENCTI_URL = os.getenv('OPENCTI_URL', 'http://localhost:8080/graphql')
OPENCTI_TOKEN = os.getenv('OPENCTI_TOKEN', '').strip()

GRAPHQL_QUERY = """
query SearchAll($term: String!) {
  globalSearch(search: $term, first: 10) {
    edges {
      node {
        id
        entity_type
        __typename
        ... on AttackPattern {
          name
          description
          aliases
          killChainPhases {
            id
            phase_name
            x_opencti_order
          }
          externalReferences {
            edges {
              node {
                source_name
                url
                external_id
              }
            }
          }
        }
      }
    }
  }
}
"""

TEXT_COLUMNS = ['alert.signature', 'alert.category']


def build_headers() -> Dict[str, str]:
    if not OPENCTI_TOKEN:
        raise ValueError('OPENCTI_TOKEN is not set. Export it as an environment variable before running.')
    return {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {OPENCTI_TOKEN}',
    }


def search_opencti(term: str, headers: Dict[str, str], retries: int = 2) -> dict:
    for attempt in range(retries + 1):
        try:
            response = requests.post(
                OPENCTI_URL,
                headers=headers,
                json={'query': GRAPHQL_QUERY, 'variables': {'term': term}},
                timeout=30,
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException:
            if attempt == retries:
                raise
            time.sleep(2)
    raise RuntimeError('Unexpected retry failure')


def best_attack_pattern(edges: List[dict]) -> Optional[dict]:
    for edge in edges:
        node = edge.get('node', {})
        if node.get('__typename') == 'AttackPattern':
            return node
    return None


def extract_attack_pattern_fields(node: dict) -> dict:
    aliases = node.get('aliases', [])
    aliases_str = ' | '.join(aliases) if isinstance(aliases, list) else str(aliases)

    kcp_list = node.get('killChainPhases', [])
    phase_names = sorted({x.get('phase_name', '') for x in kcp_list if isinstance(x, dict) and x.get('phase_name')})

    ext_edges = node.get('externalReferences', {}).get('edges', [])
    mitre_ids: List[str] = []
    mitre_urls: List[str] = []

    for ext in ext_edges:
        ext_node = ext.get('node', {})
        if ext_node.get('source_name') == 'mitre-attack':
            if ext_node.get('external_id'):
                mitre_ids.append(ext_node['external_id'])
            if ext_node.get('url'):
                mitre_urls.append(ext_node['url'])

    return {
        'match_id': node.get('id', ''),
        'entity_type': node.get('entity_type', ''),
        'typename': node.get('__typename', ''),
        'name': node.get('name', ''),
        'description': node.get('description', ''),
        'aliases': aliases_str,
        'kill_chain_phases': ' | '.join(phase_names),
        'mitre_ids': ' | '.join(sorted(set(mitre_ids))),
        'mitre_urls': ' | '.join(sorted(set(mitre_urls))),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description='Query OpenCTI and preserve alert-to-technique mapping.')
    parser.add_argument('--input-csv', default='opencti_query_keywords.csv')
    parser.add_argument('--output-csv', default='opencti_ttp_results_final.csv')
    args = parser.parse_args()

    df = pd.read_csv(args.input_csv)
    if 'alert_id' not in df.columns:
        raise ValueError("Input CSV must contain 'alert_id'.")

    available_text_columns = [c for c in TEXT_COLUMNS if c in df.columns]
    if not available_text_columns:
        raise ValueError(f'No query text columns found. Expected one of: {TEXT_COLUMNS}')

    headers = build_headers()
    rows: List[dict] = []

    for _, row in df.iterrows():
        alert_id = row['alert_id']
        base_info = {
            'alert_id': alert_id,
            'timestamp': row.get('timestamp', ''),
            'src_ip': row.get('src_ip', ''),
            'dest_ip': row.get('dest_ip', ''),
            'flow_id': row.get('flow_id', ''),
        }

        matched = False
        for source_col in available_text_columns:
            term = str(row.get(source_col, '')).strip()
            if not term or term.lower() == 'nan':
                continue

            try:
                result = search_opencti(term, headers=headers)
                errors = result.get('errors', [])
                edges = result.get('data', {}).get('globalSearch', {}).get('edges', [])

                if errors:
                    rows.append({**base_info, 'source_column': source_col, 'query_text': term, 'status': 'error', 'error_message': ' | '.join(e.get('message', '') for e in errors)})
                    continue

                node = best_attack_pattern(edges)
                if not node:
                    continue

                mapped = extract_attack_pattern_fields(node)
                rows.append({
                    **base_info,
                    'source_column': source_col,
                    'query_text': term,
                    'status': 'found',
                    **mapped,
                    'error_message': '',
                })
                matched = True
                break  # keep the best first AttackPattern match per alert
            except Exception as exc:
                rows.append({**base_info, 'source_column': source_col, 'query_text': term, 'status': 'error', 'error_message': str(exc)})

        if not matched:
            rows.append({**base_info, 'source_column': '', 'query_text': '', 'status': 'not_found', 'error_message': ''})

    out_df = pd.DataFrame(rows)
    out_df.to_csv(args.output_csv, index=False, encoding='utf-8-sig')
    print(f'[OK] Saved OpenCTI mapping output: {args.output_csv}')
    print(out_df.head(20))


if __name__ == '__main__':
    main()
