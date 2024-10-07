#!/bin/bash

LOGFILE="wifi_test.log"

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" | tee -a "$LOGFILE"
}

error_handler() {
    log_message "Error: $1"
    echo "Error: $1"
    exit 1
}

cleanup() {
    log_message "Starting system cleanup..."
    
    ifconfig "$INTERFACE" down > /dev/null 2>&1 || log_message "Failed to bring down the interface $INTERFACE"
    iwconfig "$INTERFACE" mode managed > /dev/null 2>&1 || log_message "Failed to set $INTERFACE to managed mode"
    ifconfig "$INTERFACE" up > /dev/null 2>&1 || log_message "Failed to bring up the interface $INTERFACE"
    
    macchanger -p "$INTERFACE" > /dev/null 2>&1 || log_message "Failed to restore the MAC address on $INTERFACE"
    
    if ifconfig "$INTERFACE" | grep -q "UP"; then
        log_message "$INTERFACE is successfully up."
    else
        log_message "Error: Could not bring $INTERFACE up after recovery."
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
    log_message "Cleanup completed."
}

setup_interface() {
    log_message "Setting up $INTERFACE..."
    ifconfig "$INTERFACE" down || error_handler "Failed to bring down $INTERFACE"
    macchanger -r "$INTERFACE" || error_handler "Failed to change MAC address on $INTERFACE"
    iwconfig "$INTERFACE" mode monitor || error_handler "Failed to set $INTERFACE to monitor mode"
    ifconfig "$INTERFACE" up || error_handler "Failed to bring up $INTERFACE"
    log_message "$INTERFACE set to monitor mode."
}

select_interface() {
    echo "Select a wireless interface from the list:"
    ifconfig | grep -e ": " | sed -e 's/: .*//g' | sed -e 's/^/   /'
    echo -n "Enter the name of the wireless interface: "
    read -r INTERFACE
    if [[ -z "$INTERFACE" ]]; then
        error_handler "No interface selected."
    fi
    log_message "Interface selected: $INTERFACE"
}

menu_options() {
    echo "Choose an option:"
    echo "1. Use SSID file"
    echo "2. Generate random SSID"
    echo -n "> "
    read -r OPTION
    if [[ "$OPTION" != "1" && "$OPTION" != "2" ]]; then
        error_handler "Invalid option selected."
    fi
    log_message "Option selected: $OPTION"
}

run_attack() {
    local wordlist="$1"
    local ssid_count="$2"
    log_message "Launching attack with $ssid_count SSID(s) from $wordlist"
    setup_interface
    trap cleanup EXIT
    mdk3 "$INTERFACE" b -f "$wordlist" -a -s "$ssid_count" || error_handler "Failed to execute attack with mdk3."
    log_message "Attack completed."
}

generate_random_ssids() {
    local count="$1"
    log_message "Generating $count random SSID(s)..."
    > RANDOM_wordlist.txt
    for ((i = 1; i <= count; i++)); do
        echo "$(pwgen 14 1)" >> RANDOM_wordlist.txt
    done
    log_message "Random SSIDs generated and saved in RANDOM_wordlist.txt"
}

main() {
    echo "================================================="
    echo "   Wi-Fi SSID Attack Script be kewwL"
    echo "   Project Repository: https://github.com/cbFelix/wifispam"
    echo "================================================="
    log_message "Script started."
    select_interface
    menu_options

    case $OPTION in
        1)
            echo -n "Enter the path to the SSID file: "
            read -r wordlist
            if [[ ! -f "$wordlist" ]]; then
                error_handler "File $wordlist not found."
            fi
            ssid_count=$(wc -l < "$wordlist")
            log_message "$wordlist loaded with $ssid_count SSID(s)."
            run_attack "$wordlist" "$ssid_count"
            ;;
        2)
            echo -n "How many random SSID(s) to generate? "
            read -r ssid_count
            if ! [[ "$ssid_count" =~ ^[0-9]+$ ]]; then
                error_handler "Invalid number of SSIDs."
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
