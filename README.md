# IDS Alert Correlation and Threat Intelligence Enrichment Framework

A research framework for correlating IDS alerts and mapping them to **MITRE ATT&CK techniques** and **Cyber Kill Chain stages** using **multi-stage attack simulation** and **Cyber Threat Intelligence (CTI) enrichment via OpenCTI**.

This project focuses on **alert correlation and enrichment**, leveraging outputs from **Suricata (NIDS)** and **Wazuh (HIDS)** rather than replacing the IDS engines themselves.

---

## Overview

Modern Intrusion Detection Systems generate large volumes of alerts that are difficult to interpret in isolation. This project provides a framework that:

- Collects alerts from **network-based and host-based IDS**
- Normalizes heterogeneous alert logs
- Maps alerts to **MITRE ATT&CK techniques**
- Infers **Cyber Kill Chain stages**
- Enriches alerts using **OpenCTI threat intelligence**

The framework is validated through **controlled multi-stage attack simulations** conducted in a virtualized laboratory environment.

---


---

## Experimental Testbed

The evaluation environment consists of a controlled virtual lab setup.

| Component | Description |
|--------|--------|
| Attacker VM | Kali Linux |
| Target VM | Ubuntu Linux |
| NIDS | Suricata |
| HIDS | Wazuh |
| CTI Platform | OpenCTI |
| Virtualization | VirtualBox |

The attacker machine executes scripted attack scenarios targeting the victim host while IDS alerts are collected and processed.

---

## Attack Simulation

The framework uses **controlled attack scenarios** representing different intrusion stages.

Example stages simulated:

- Reconnaissance  
- Initial Access  
- Execution  
- Privilege Escalation  
- Lateral Movement  

Each stage generates IDS alerts which are then processed by the pipeline.

Example tools used in simulations:

- `nmap`
- `hydra`
- enumeration tools
- network scanning utilities

Only **representative examples** are provided in this repository.

---

## Limitations

This repository provides a **research prototype implementation** and example configurations.

The framework:

- Relies on the detection capabilities of underlying IDS systems
- Uses **representative simulated attacks**
- Provides **sample alert logs only**, not full experimental datasets

---

## Future Work

Possible extensions include:

- Advanced alert correlation techniques
- Graph-based attack chain reconstruction
- Integration with additional CTI platforms
- Machine learning models for alert classification

---

---

## License

This project is released under the MIT License.

