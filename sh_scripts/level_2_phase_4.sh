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


TARGET_IP="<TARGET_IP>"

echo "[+] Starting Level 2 - Phase 4: DNS and FTP-based Activity"

# 1. Simulate DNS tunneling using dig with a suspicious domain
echo "[+] Simulating DNS tunneling query..."
dig +short tunnel123.example.xyz @${TARGET_IP}

# 2. Simulate HTTP exfiltration on port 8443
echo "[+] Simulating HTTP request to uncommon port 8443..."
curl -v http://${TARGET_IP}:8443/secret-data --connect-timeout 5 || echo "Curl attempt finished."

# 3. Simulate FTP connection attempt
echo "[+] Simulating FTP connection to target..."
(echo USER testuser; echo PASS testpass; echo QUIT) | nc ${TARGET_IP} 21 || echo "FTP connection simulated."

echo "[+] Level 2 - Phase 4 simulation complete."
