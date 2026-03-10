# IDS Experimental Testbed Setup

This document describes the experimental environment used to generate IDS alerts and evaluate the IDS alert correlation framework.

The setup consists of a controlled virtual laboratory where simulated attacks are launched against a victim host while IDS systems monitor the activity.

---

## Virtual Environment

The experiment is conducted using virtual machines.

| Component | Description |
|----------|-------------|
| Virtualization | VirtualBox |
| Attacker Machine | Kali Linux |
| Target Machine | Ubuntu Linux |

---

## Intrusion Detection Systems

Two IDS systems are used to capture security events.

### Network-based IDS (NIDS)

**Suricata**

Responsibilities:
- Monitor network traffic
- Detect malicious network behavior
- Generate network alerts

Example events detected:
- Port scanning
- SSH brute-force attempts
- Suspicious network connections

---

### Host-based IDS (HIDS)

**Wazuh**

Responsibilities:
- Monitor host-level activity
- Detect suspicious system events
- Log authentication and system anomalies

Example events detected:
- Login attempts
- File modifications
- System command execution

---

## Cyber Threat Intelligence Platform

The framework integrates with **OpenCTI** to enrich alerts with threat intelligence.

OpenCTI provides:

- Threat actor information
- MITRE ATT&CK techniques
- Indicators of compromise (IOC)
- Contextual threat intelligence

OpenCTI is deployed using **Docker containers**.

---

## Experimental Workflow

The experimental workflow follows these steps:

1. Simulated attacks are executed from the attacker machine
2. The victim machine receives the malicious activity
3. Suricata monitors network traffic and generates alerts
4. Wazuh monitors host events and generates alerts
5. Alerts are collected and processed by the framework
6. Alerts are mapped to MITRE ATT&CK techniques
7. Cyber Kill Chain stages are inferred
8. Alerts are enriched using OpenCTI intelligence

---

## Notes

This repository provides **configuration examples and sample alerts only**.

The full experimental datasets and infrastructure configurations are not included for security and privacy reasons.
