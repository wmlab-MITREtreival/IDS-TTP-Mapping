
# ---------------------------------------------
# Attack Phase 3: Delivery - Simulate Malicious Payload Download
# ---------------------------------------------
# Components:
# - Ubuntu VM = Target
# - Kali VM = Attacker
# Requirements:
#   • Apache2 must be running on Ubuntu
#   • payload.sh must exist in /var/www/html/
#   • Suricata must be running and have relevant rules
# ---------------------------------------------

TARGET_IP=""      # Target Ubuntu IP
TARGET_USER=""              # Username on Ubuntu
PAYLOAD_CONTENT='echo malicious activity'  # Fake payload

echo "[+] Phase 3: Starting delivery simulation..."

# Step 1: Remotely create the payload on the target and serve via Apache
echo "[+] Creating and serving malicious payload on target..."

ssh ${TARGET_USER}@${TARGET_IP} << EOF
  echo '[*] Connected to target.'
  echo '[*] Creating payload file...'
  echo "$PAYLOAD_CONTENT" | sudo tee /var/www/html/payload.sh > /dev/null
  sudo chmod 755 /var/www/html/payload.sh
  echo '[*] Ensuring Apache2 is running...'
  sudo systemctl restart apache2
  echo '[*] Payload ready at http://${TARGET_IP}/payload.sh'
EOF

# Wait briefly
sleep 3

# Step 2: Simulate attacker downloading the malicious payload
echo "[+] Downloading payload from target (simulating delivery)..."
curl http://${TARGET_IP}/payload.sh -o /dev/null --connect-timeout 5

# Step 3: Completion notice
echo "[+] Attack Phase 3 complete. Check Suricata alerts on target."

