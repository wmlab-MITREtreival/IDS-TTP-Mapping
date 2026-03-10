
#!/bin/bash

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

# Print final message
log_action "HIDS attack simulation completed. Logs saved to $LOG_FILE."

# End of script
echo "Attack simulation completed. Check the log file: $LOG_FILE"
