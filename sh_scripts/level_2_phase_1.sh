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


# ----------------------------
# Level 2 - Phase 1: Recon & Discovery Simulation
# ----------------------------

TARGET_IP="<TARGET_IP>"  # <-- Replace if different

echo "[+] Starting Level 2 - Phase 1: Reconnaissance & Discovery"

# 1. DNS Recon via dig
echo "[+] Performing DNS reconnaissance with dig..."
dig @${TARGET_IP} google.com

# 2. ICMP Ping (host discovery)
echo "[+] Pinging target for host discovery..."
ping -c 4 ${TARGET_IP}

# 3. Netcat port probe
echo "[+] Probing SMB-related ports with Netcat..."
nc -zv ${TARGET_IP} 139
nc -zv ${TARGET_IP} 445

# 4. Enum4linux enumeration
echo "[+] Running enum4linux enumeration..."
enum4linux -a ${TARGET_IP}

echo "[+] Level 2 - Phase 1 complete. Check Suricata alerts on target machine."

