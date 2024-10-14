#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# This script is designed to install and configure powerful security tools and set up logging for evidence preservation.

# Variables
LOG_DIR="/Users/caseychambers/JobScrape/AuditLogs"
LOG_FILE="$LOG_DIR/security_audit.log"
REMOTE_LOG_SERVER="your.remote.log.server"  # Replace with your remote logging server
OSSEC_CONFIG="/opt/homebrew/etc/ossec/ossec.conf"
FAIL2BAN_CONFIG="/opt/homebrew/etc/fail2ban/jail.local"
PF_CONF="/etc/pf.conf"

# Function to log messages with color
log() {
    local COLOR_RESET="\033[0m"
    local COLOR_GREEN="\033[32m"
    local COLOR_RED="\033[31m"
    local COLOR_YELLOW="\033[33m"
    local MESSAGE_TYPE=$1
    local MESSAGE=$2
    case $MESSAGE_TYPE in
        INFO) echo -e "${COLOR_GREEN}INFO: ${MESSAGE}${COLOR_RESET}" | tee -a "$LOG_FILE" ;;
        ERROR) echo -e "${COLOR_RED}ERROR: ${MESSAGE}${COLOR_RESET}" | tee -a "$LOG_FILE" ;;
        WARN) echo -e "${COLOR_YELLOW}WARN: ${MESSAGE}${COLOR_RESET}" | tee -a "$LOG_FILE" ;;
    esac
}

# Create log directory
mkdir -p "$LOG_DIR" || { log "ERROR" "Permission denied: Unable to create log directory"; exit 1; }

# Function to handle errors
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Trap to handle cleanup on exit
trap 'log "INFO" "Cleaning up..."; exit' EXIT

# Function to install packages
install_package() {
    if ! command -v "$1" &> /dev/null; then
        log "INFO" "Installing $1..."
        if [ "$1" == "wireshark" ]; then
            brew install --cask wireshark || { log "ERROR" "Failed to install $1"; return; }
        elif [ "$1" == "ossec" ]; then
            log "ERROR" "OSSEC is not available via Homebrew. Please install it manually."
            return
        else
            brew install "$1" || { log "ERROR" "Failed to install $1"; return; }
        fi
    else
        log "INFO" "$1 is already installed."
    fi
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error_exit "This script is designed for macOS systems."
fi

# Install necessary packages (run without sudo)
install_package "wireshark"
install_package "suricata"
install_package "ossec"
install_package "fail2ban"
install_package "chkrootkit"
install_package "rkhunter"
install_package "logwatch"
install_package "rsync" # For offsite backups
install_package "shellcheck" # For linting
install_package "pv" # For progress indication
install_package "nmap" # For port scanning
install_package "tcpdump" # For packet capture
install_package "auditd" # For auditing
install_package "clamav" # For antivirus scanning
install_package "lynis" # For security auditing
install_package "snort" # For intrusion detection
install_package "tripwire" # For file integrity monitoring
install_package "aide" # For file integrity checking
install_package "openvas" # For vulnerability scanning
install_package "metasploit" # For penetration testing

# The following operations require sudo
sudo bash <<EOF

# Configure OSSEC
if [ -f "$OSSEC_CONFIG" ]; then
    log "INFO" "Configuring OSSEC..."
    sed -i 's|<localfile>|<localfile>\n<log_format>full</log_format>|' "$OSSEC_CONFIG" || error_exit "Failed to configure OSSEC"
fi

# Start OSSEC service
brew services start ossec || error_exit "Failed to start OSSEC service"

# Configure Fail2Ban
if [ -f "$FAIL2BAN_CONFIG" ]; then
    log "INFO" "Configuring Fail2Ban..."
    {
        echo "[sshd]"
        echo "enabled = true"
        echo "port    = ssh"
        echo "filter  = sshd"
        echo "logpath = /var/log/auth.log"
    } >> "$FAIL2BAN_CONFIG" || error_exit "Failed to configure Fail2Ban"
fi

# Start Fail2Ban service
brew services start fail2ban || error_exit "Failed to start Fail2Ban service"

# Check for rootkits
log "INFO" "Running chkrootkit..."
chkrootkit | tee -a "$LOG_FILE" || error_exit "chkrootkit failed"

log "INFO" "Running rkhunter..."
rkhunter --check --rwo | tee -a "$LOG_FILE" || error_exit "rkhunter failed"

# Run ClamAV scan
log "INFO" "Updating ClamAV database..."
freshclam || error_exit "Failed to update ClamAV database"

log "INFO" "Running ClamAV scan..."
clamscan -r / --exclude-dir="^/sys" --exclude-dir="^/proc" --exclude-dir="^/dev" --exclude-dir="^/run" | tee -a "$LOG_FILE" || error_exit "ClamAV scan failed"

# Run Lynis audit
log "INFO" "Running Lynis audit..."
lynis audit system | tee -a "$LOG_FILE" || error_exit "Lynis audit failed"

# Close unnecessary ports (example: closing port 80)
pfctl -f "$PF_CONF" || error_exit "Failed to load pf.conf"
pfctl -e || error_exit "Failed to enable pf"

# Add rules to block unwanted access
echo "block in on en0 proto tcp from any to any port 80" | tee -a "$PF_CONF" || error_exit "Failed to update pf.conf"

# Setup offsite logging
log "INFO" "Configuring offsite logging..."
rsync -avz "$LOG_DIR/" "$REMOTE_LOG_SERVER:$LOG_DIR/" || error_exit "Failed to configure offsite logging"

# Schedule a cron job for periodic logging
(crontab -l 2>/dev/null; echo "0 * * * * rsync -avz $LOG_DIR/ $REMOTE_LOG_SERVER:$LOG_DIR/") | crontab - || error_exit "Failed to schedule cron job"

# Port Scanning
log "INFO" "Running port scan..."
nmap -sS -T4 -A -v localhost | tee -a "$LOG_FILE" || error_exit "Port scan failed"

# Packet Capture
log "INFO" "Starting packet capture..."
tcpdump -i en0 -w "$LOG_DIR/packets.pcap" &

# Auditing
log "INFO" "Starting auditd service..."
auditctl -e 1 || error_exit "Failed to start auditd"

# Honeypot Setup (Example with Cowrie)
log "INFO" "Setting up honeypot..."
# Assuming Cowrie is installed and configured
systemctl start cowrie || error_exit "Failed to start honeypot"

EOF

# Log completion
log "INFO" "Security setup complete. Monitoring and logging are now active."

# Notify user to check logs
echo "Check your logs at $LOG_FILE for details."
