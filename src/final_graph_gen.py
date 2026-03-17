import argparse
import textwrap

import matplotlib.pyplot as plt
import networkx as nx
import pandas as pd


PATH_COLORS = [
    'red', 'blue', 'green', 'purple', 'orange',
    'brown', 'magenta', 'cyan', 'olive', 'black',
]


def wrap_label(text: str, width: int = 16) -> str:
    return '\n'.join(textwrap.wrap(str(text), width=width))


def main() -> None:
    parser = argparse.ArgumentParser(description='Generate Alert -> Technique -> Kill Chain graph.')
    parser.add_argument('--input-csv', default='opencti_ttp_results_final.csv')
    parser.add_argument('--output-png', default='precedence_graph_clear.png')
    parser.add_argument('--limit', type=int, default=10)
    args = parser.parse_args()

    df = pd.read_csv(args.input_csv)
    required_cols = ['alert_id', 'mitre_ids', 'kill_chain_phases']
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise ValueError(f'Missing required columns: {missing}')

    df = df.dropna(subset=['mitre_ids', 'kill_chain_phases']).copy()
    sort_cols = [c for c in ['timestamp', 'alert_id'] if c in df.columns]
    if sort_cols:
        df = df.sort_values(sort_cols)
    df = df.head(args.limit)

    G = nx.DiGraph()
    alert_labels = []
    tech_labels = []
    phase_labels = []
    edge_colors = []
    edge_list = []

    for idx, (_, row) in enumerate(df.iterrows()):
        color = PATH_COLORS[idx % len(PATH_COLORS)]
        alert = wrap_label(f"Alert {row['alert_id']}")
        technique = wrap_label(str(row['mitre_ids']).split('|')[0].strip())
        phases = [p.strip().lower() for p in str(row['kill_chain_phases']).replace(',', '|').split('|') if p.strip()]
        if not phases:
            phases = ['unknown']

        G.add_node(alert, node_type='alert')
        G.add_node(technique, node_type='technique')
        if alert not in alert_labels:
            alert_labels.append(alert)
        if technique not in tech_labels:
            tech_labels.append(technique)

        G.add_edge(alert, technique)
        edge_list.append((alert, technique))
        edge_colors.append(color)

        for phase in phases:
            phase_node = wrap_label(f'KC: {phase}')
            G.add_node(phase_node, node_type='phase')
            G.add_edge(technique, phase_node)
            edge_list.append((technique, phase_node))
            edge_colors.append(color)
            if phase_node not in phase_labels:
                phase_labels.append(phase_node)

    pos = {}
    for i, node in enumerate(alert_labels):
        pos[node] = (0, len(alert_labels) - i)
    for i, node in enumerate(tech_labels):
        pos[node] = (1.8, len(tech_labels) - i)
    for i, node in enumerate(phase_labels):
        pos[node] = (3.6, len(phase_labels) - i)

    plt.figure(figsize=(18, 10))
    nx.draw_networkx_nodes(G, pos, nodelist=alert_labels, node_size=2800, node_color='skyblue')
    nx.draw_networkx_nodes(G, pos, nodelist=tech_labels, node_size=3200, node_color='orange')
    nx.draw_networkx_nodes(G, pos, nodelist=phase_labels, node_size=2800, node_color='lightgreen')
    nx.draw_networkx_labels(G, pos, font_size=9, font_weight='bold')
    nx.draw_networkx_edges(
        G,
        pos,
        edgelist=edge_list,
        edge_color=edge_colors,
        arrows=True,
        arrowstyle='-|>',
        arrowsize=18,
        width=2.2,
    )

    plt.title('Alert → Technique → Kill Chain Mapping Graph', fontsize=14)
    plt.axis('off')
    plt.tight_layout()
    plt.savefig(args.output_png, dpi=300, bbox_inches='tight')
    print(f'[OK] Graph saved: {args.output_png}')
    plt.show()


if __name__ == '__main__':
    main()
