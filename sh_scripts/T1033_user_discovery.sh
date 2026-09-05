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


LOG_FILE="/tmp/T1033_user_discovery_$(date +'%Y%m%d_%H%M%S').log"

log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_action "Simulating T1033: User Discovery"

# Actual enumeration
log_action "Running: who"
who >> "$LOG_FILE"

log_action "Running: id"
id >> "$LOG_FILE"

log_action "Running: getent passwd"
getent passwd >> "$LOG_FILE"

log_action "T1033 simulation completed"
