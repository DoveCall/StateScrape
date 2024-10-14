LOG_DIR="/var/log/security_audit"
REMOTE_LOG_SERVER="your.remote.log.server"
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
    local COLOR_RED="\033[31m"
    case $MESSAGE_TYPE in
        INFO) echo -e "${COLOR_GREEN}INFO: ${MESSAGE}${COLOR_RESET}" | tee -a $LOG_FILE ;;
        ERROR) echo -e "${COLOR_RED}ERROR: ${MESSAGE}${COLOR_RESET}" | tee -a $LOG_FILE ;;
        WARN) echo -e "${COLOR_YELLOW}WARN: ${MESSAGE}${COLOR_RESET}" | tee -a $LOG_FILE ;;
    esac
}

