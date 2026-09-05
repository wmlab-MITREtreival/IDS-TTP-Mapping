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


# Create a timestamped log file
LOG_FILE="/tmp/attack_simulation_$(date +'%Y%m%d_%H%M%S').log"

log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_action "Starting HIDS simulation for T1003.008 - Credential Dumping"

# Simulate unauthorized access to /etc/shadow
log_action "Attempting to read /etc/shadow file"
sudo cat /etc/shadow > /dev/null 2>&1

log_action "Read attempt to /etc/shadow completed."

log_action "HIDS simulation completed for T1003.008 - Logs saved to $LOG_FILE"
echo "Attack simulation completed. Check the log file: $LOG_FILE"
