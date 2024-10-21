# Wi-Fi SSID Attack Script

A bash script for executing Wi-Fi SSID attacks with options to use custom SSID lists or generate random SSIDs, featuring automated interface setup and cleanup.

## Features
- Automates Wi-Fi SSID attacks using MDK3
- Supports custom SSID lists or random SSID generation
- Handles interface setup (monitor mode) and teardown (managed mode)
- Automatic error logging and system cleanup after execution

# Changelogs
## v1.1.0 - 09.10.2024

- Dependency Checks: Added validation for required tools (mdk3, macchanger, etc.).
- Interface Validation: Ensures selected interface is wireless and active.
- Error Handling: Improved error messages for easier troubleshooting.
- MAC Change Verification: Added check to confirm successful MAC address change.
- Cleanup: Enhanced post-attack cleanup to restore original settings.


# Disclaimer

This project is intended for educational and research purposes only. The use of this script for any illegal activities, including unauthorized access to wireless networks, is strictly prohibited. It is your responsibility to ensure that you have permission to test or attack any network you are targeting.

**Note:** In many countries, performing Wi-Fi attacks without explicit permission is illegal and can result in severe penalties, including fines and imprisonment. By using this script, you acknowledge that you understand the laws in your country regarding network security and will not use this script for any unlawful purposes.

The authors of this project will not be held responsible for any misuse or damage caused by this script. Use it at your own risk.

## Installation

1. Clone this repository:
    ```bash
    git clone https://github.com/cbFelix/wifispam.git
    cd wifispam
    ```

2. Install the required dependencies:
    ```bash
    sudo apt update
    sudo apt install -y mdk3 macchanger pwgen
    ```

## Usage

1. Navigate to the project directory:
    ```bash
    cd wifispam
    ```

2. Make the script executable:
    ```bash
    chmod +x wifispam.sh
    ```

3. Run the script:
    ```bash
    sudo ./wifispam.sh
    ```

4. Follow the on-screen prompts to either:
    - Use a predefined SSID list, or
    - Generate random SSIDs for the attack.

## Dependencies

The script relies on the following utilities:
- **MDK3**: Used for conducting the SSID attacks.
  - Repository: [https://github.com/wi-fi-analyzer/mdk3-master](https://github.com/wi-fi-analyzer/mdk3-master)
- **MacChanger**: For changing and restoring MAC addresses.
  - Repository: [https://github.com/alobbs/macchanger](https://github.com/alobbs/macchanger)
- **Pwgen**: Used for generating random SSIDs.
  - Repository: [https://github.com/tytso/pwgen](https://github.com/tytso/pwgen)

## Project Structure

```bash
wifispam.sh  # Main script
wifi_test.log        # Log file generated during script execution
RANDOM_wordlist.txt  # Temporary file storing generated SSIDs (if applicable)
