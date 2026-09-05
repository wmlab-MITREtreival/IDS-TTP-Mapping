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

# Function to log actions with timestamp
log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Simulate adding a new user
log_action "Simulating user addition: adding hacker123"
sudo useradd hacker123
log_action "User hacker123 added."

# Wait for 2 seconds
sleep 2

# Simulate deleting the user
log_action "Simulating user deletion: deleting hacker123"
sudo userdel hacker123
log_action "User hacker123 deleted."

# Wait for 2 seconds
sleep 2

# Simulate modifying the /etc/passwd file (example hack)
log_action "Simulating modification of /etc/passwd: adding hacked entry"
echo "hacked" | sudo tee -a /etc/passwd > /dev/null
log_action "Modified /etc/passwd with 'hacked' entry."

# Wait for 2 seconds
sleep 2

# Simulate restoring /etc/passwd by removing the last entry
log_action "Simulating restore of /etc/passwd: removing hacked entry"
sudo sed -i '$ d' /etc/passwd
log_action "Restored /etc/passwd by removing last entry."

# Wait for 2 seconds
sleep 2

# Simulate dropping the EICAR malware test file
log_action "Simulating dropping of EICAR malware test file"
sudo bash -c "echo 'X5O!P%@AP[4\\PZX54(P^)7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!\$H+H*' > /tmp/eicar.com"
log_action "EICAR malware test file created at /tmp/eicar.com."

# Wait for 2 seconds
sleep 2

# Change permissions for the malware file (optional)
log_action "Changing permissions of /tmp/eicar.com to 755"
sudo chmod 755 /tmp/eicar.com
log_action "Permissions of /tmp/eicar.com set to 755."

# Simulate a fake attack (you can extend this with more techniques)
log_action "Simulating fake attack."
# (Example for fake attack simulation, customize with more techniques)
sudo touch /tmp/fake_attack_file

log_action "Fake attack file created at /tmp/fake_attack_file."

# Print final message
log_action "HIDS attack simulation completed. Logs saved to $LOG_FILE."

# End of script
echo "Attack simulation completed. Check the log file: $LOG_FILE"
