##IDS Alert Correlation and Threat Intelligence Enrichment Framework

This repository provides the implementation and experimental setup used in the paper:

"Mapping IDS Alerts to MITRE ATT&CK Techniques and Cyber Kill Chain Stages using Deep Learning and CTI Enrichment"

The framework integrates Network-based IDS (Suricata), Host-based IDS (Wazuh), OpenCTI threat intelligence, and a SecureBERT + BiLSTM deep learning model to classify alerts, enrich them with threat intelligence, and reconstruct adversarial kill chain stages.

Repository Structure
.
├── dataset/                # Sample IDS alerts used in experiments
│   ├── sample_alerts.json
│   ├── extracted_features.csv
│
├── models/
│   ├── securebert_bilstm.py
│   ├── training_script.py
│
├── preprocessing/
│   ├── log_parser.py
│   ├── feature_extraction.py
│
├── opencti/
│   ├── graphql_queries.py
│   ├── opencti_config.md
│
├── testbed/
│   ├── attack_simulation.md
│   ├── network_topology.png
│
├── evaluation/
│   ├── performance_metrics.py
│
├── README.md
└── requirements.txt
System Overview

The proposed framework consists of the following pipeline:

1️⃣ IDS Monitoring

Suricata (Network-based IDS)

Wazuh (Host-based IDS)

2️⃣ Alert Collection

Logs from IDS sensors are aggregated and stored as structured JSON alerts.

3️⃣ Alert Classification

Alerts are processed using a SecureBERT + BiLSTM deep learning model that classifies events as malicious or benign.

4️⃣ CTI Enrichment

Alerts classified as malicious are enriched using OpenCTI GraphQL queries, mapping them to MITRE ATT&CK techniques.

5️⃣ Kill Chain Inference

A symbolic reasoning engine reconstructs the Cyber Kill Chain stages by analyzing temporal relationships between detected techniques.

Experimental Testbed Setup

The experiments were conducted in a virtualized cybersecurity testbed consisting of the following systems:

Machine	Role
Kali Linux	Attack simulation
Ubuntu Server	Target host
Suricata	Network IDS
Wazuh	Host IDS
OpenCTI	Threat intelligence platform

The environment was used to simulate multi-stage adversarial campaigns.

Attack stages included:

Reconnaissance

Initial Access

Execution

Privilege Escalation

Lateral Movement

Command and Control

Data Exfiltration

The simulation generated:

38,506 IDS alerts

154 MITRE ATT&CK techniques

5 multi-stage attack scenarios

IDS Configuration
Suricata (NIDS)

Install Suricata:

sudo apt install suricata

Main configuration file:

/etc/suricata/suricata.yaml

Enable rules:

emerging-threats.rules
custom_attack_rules.rules

Run Suricata:

sudo suricata -c /etc/suricata/suricata.yaml -i eth0

Alert output location:

/var/log/suricata/eve.json
Wazuh (HIDS) Setup

Install Wazuh agent:

curl -sO https://packages.wazuh.com/4.x/wazuh-install.sh
sudo bash wazuh-install.sh

Wazuh monitors:

authentication logs

system logs

process execution

file system changes

Alert output:

/var/ossec/logs/alerts/alerts.json
OpenCTI Setup

OpenCTI is deployed using Docker.

Clone repository:

git clone https://github.com/OpenCTI-Platform/opencti.git
cd opencti

Start OpenCTI services:

docker compose up -d

Import threat intelligence feeds:

MITRE ATT&CK

MISP feeds

Access OpenCTI GraphQL API:

http://localhost:8080/graphql

Example GraphQL query:

query {
  attackPatterns(search: "reverse shell") {
    edges {
      node {
        name
        description
        killChainPhases {
          kill_chain_name
          phase_name
        }
      }
    }
  }
}
Alert Classification Model

The classification module uses:

SecureBERT embeddings

Bidirectional LSTM for temporal modeling

Training Parameters
Parameter	Value
Learning Rate	3e-5
Batch Size	32
Epochs	10
Optimizer	AdamW
Running the Pipeline
Step 1 — Feature Extraction
python preprocessing/feature_extraction.py
Step 2 — Train Classification Model
python models/training_script.py
Step 3 — Threat Intelligence Enrichment
python opencti/graphql_queries.py
Step 4 — Kill Chain Inference
python evaluation/performance_metrics.py
Dataset

Due to security considerations, the complete dataset cannot be publicly released.

This repository provides a representative subset containing:

sample IDS alerts

extracted feature vectors

example CTI enrichment results
