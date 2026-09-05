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
ATTACKER_IP="<ATTACKER_IP>"

echo "[+] Starting Level 3 - Phase 1: Advanced Reconnaissance & Exfiltration"

# 1. DNS NS and MX Record Lookup (T1590.002)
echo "[+] Performing DNS reconnaissance (NS & MX)..."
dig @$TARGET_IP google.com NS
dig @$TARGET_IP google.com MX

# 2. FTP & Telnet Application Layer Scans (T1595.003)
echo "[+] Probing FTP and Telnet services..."
nc -zv $TARGET_IP 21
nc -zv $TARGET_IP 23

# 3. Whois / API lookup simulation (T1596)
echo "[+] Simulating WHOIS technical database query..."
curl -s http://api.hackertarget.com/whois/?q=example.com > /dev/null

# 4. Access hidden web admin endpoints (T1592.004)
echo "[+] Accessing suspicious admin HTTP path..."
curl http://$TARGET_IP/admin

# 5. DNS TXT Record Exfiltration Simulation (T1041)
echo "[+] Simulating DNS TXT exfiltration..."
dig TXT sensitive.exfil.domain @$TARGET_IP

# 6. Simulate downloading a sniffing tool (T1040)
echo "[+] Simulating download of a packet capture tool..."
curl http://$TARGET_IP/downloads/tshark.deb -o /dev/null

echo "[+] Level 3 - Phase 1 simulation complete. Check Suricata alerts on Ubuntu."

