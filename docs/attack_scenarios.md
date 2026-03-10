# Attack Simulation Scenarios

This document describes the simulated attack scenarios used to generate IDS alerts for the framework evaluation.

The experiments simulate **multi-stage intrusion activities** in a controlled laboratory environment. Each stage represents a common phase in real-world cyber attacks.

The generated IDS alerts are later processed and mapped to **MITRE ATT&CK techniques** and **Cyber Kill Chain stages**.

---

# Attack Stages

The following attack stages are simulated.

| Stage | Description |
|------|-------------|
| Reconnaissance | Information gathering about the target system |
| Initial Access | Attempting to gain entry into the system |
| Execution | Running malicious commands on the target |
| Privilege Escalation | Attempting to obtain higher privileges |
| Lateral Movement | Accessing additional systems in the network |

---

# Stage 1 — Reconnaissance

In this stage, the attacker collects information about the target system.

Example activities include:

- Network scanning
- Port discovery
- Service enumeration

Example tools used:
nmap
ping
network scanning utilities

Example IDS alerts generated:

- Port scan detection
- Suspicious network probing

Example MITRE ATT&CK mapping:
T1046 – Network Service Discovery


Kill Chain Stage:


Reconnaissance


---

# Stage 2 — Initial Access

In this stage, the attacker attempts to gain access to the target system.

Example activities include:

- SSH brute-force attempts
- Credential guessing

Example tools used:
hydra
ssh login attempts


Example IDS alerts generated:

- SSH authentication failures
- Brute-force detection alerts

Example MITRE ATT&CK mapping:


T1110 – Brute Force


Kill Chain Stage:


Credential Access / Initial Access


---

# Stage 3 — Execution

Once access is obtained, the attacker attempts to execute commands on the target system.

Example activities include:

- Remote command execution
- Shell access

Example IDS alerts generated:

- Suspicious command execution
- Unusual system activity

Example MITRE ATT&CK mapping:


T1059 – Command and Scripting Interpreter


Kill Chain Stage:


Execution


---

# Stage 4 — Privilege Escalation

The attacker attempts to gain elevated privileges.

Example activities include:

- Running privileged commands
- Attempting sudo access

Example IDS alerts generated:

- Unauthorized privilege attempts
- Suspicious system command usage

Example MITRE ATT&CK mapping:


T1068 – Exploitation for Privilege Escalation


Kill Chain Stage:


Privilege Escalation


---

# Stage 5 — Lateral Movement

In this stage, the attacker attempts to move to other systems.

Example activities include:

- Remote login attempts
- Accessing additional machines

Example IDS alerts generated:

- Remote login attempts
- Network connection anomalies

Example MITRE ATT&CK mapping:


T1021 – Remote Services


Kill Chain Stage:


Lateral Movement


---

# Notes

The commands shown in this document are **representative examples**.  


