#!/bin/bash
#
# auto_continue_terminals.sh
# 
# Description:
#   This script sends commands to all open Terminal windows and tabs.
#   It can either execute immediately or wait until a specified time.
#   The script prevents system sleep while waiting using caffeinate.
#
# Usage:
#   ./auto_continue_terminals.sh                    # Execute immediately with 'continue'
#   ./auto_continue_terminals.sh HH:MM              # Execute at specified time with 'continue'
#   ./auto_continue_terminals.sh HH:MM "command"    # Execute at specified time with custom command
#
# Examples:
#   ./auto_continue_terminals.sh                    # Sends 'continue' to all terminals now
#   ./auto_continue_terminals.sh 14:30              # Waits until 2:30 PM then sends 'continue'
#   ./auto_continue_terminals.sh 06:01 "ultrathink continue"  # Sends custom command at 6:01 AM
#
# Requirements:
#   - macOS with Terminal app
#   - Terminal must have accessibility permissions
#     (System Preferences > Security & Privacy > Privacy > Accessibility)
#   - caffeinate command (included in macOS)
#
# Notes:
#   - Press Ctrl+C at any time to cancel execution
#   - The script will send the specified command + Enter to each tab in every Terminal window
#   - System sleep is prevented while the script is running
#   - Default command is 'continue' if not specified
#
# Author: Auto-generated script
# Version: 1.2.0
#

# Enable strict error handling
set -e
set -o pipefail

# Global variable for caffeinate PID
CAFFEINATE_PID=""

# Cleanup function
cleanup() {
    echo -e "\n\nCleaning up..."
    
    # Kill caffeinate process if it exists
    if [ -n "$CAFFEINATE_PID" ] && kill -0 "$CAFFEINATE_PID" 2>/dev/null; then
        echo "Stopping caffeinate process (PID: $CAFFEINATE_PID)..."
        kill "$CAFFEINATE_PID" 2>/dev/null || true
    fi
    
    echo "Cleanup completed."
    exit
}

# Setup trap for various signals
trap cleanup EXIT INT TERM HUP

# Handle Ctrl+C specifically
trap 'echo -e "\n\nCtrl+C detected. Exiting..."; cleanup' INT

# Default command
COMMAND_TEXT="continue"

# Parse arguments
if [ $# -eq 0 ]; then
    echo "No time provided. Executing immediately with default command: '$COMMAND_TEXT'"
    TARGET_TIME=$(date +"%H:%M")
elif [ $# -eq 1 ]; then
    # Only time provided
    TARGET_TIME=$1
    echo "Using default command: '$COMMAND_TEXT'"
elif [ $# -eq 2 ]; then
    # Time and custom command provided
    TARGET_TIME=$1
    COMMAND_TEXT=$2
    echo "Using custom command: '$COMMAND_TEXT'"
else
    echo "Error: Too many arguments"
    echo "Usage: $0 [HH:MM] [\"custom command\"]"
    echo "Examples:"
    echo "  $0                           # Execute immediately with 'continue'"
    echo "  $0 14:30                     # Execute at 14:30 with 'continue'"
    echo "  $0 14:30 \"ultrathink continue\" # Execute at 14:30 with custom command"
    exit 1
fi

# Validate time format if time was provided
if [ $# -ge 1 ]; then
    if ! [[ "$TARGET_TIME" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        echo "Error: Time must be in HH:MM format"
        exit 1
    fi

    # Validate time values
    HOUR=$(echo "$TARGET_TIME" | cut -d: -f1)
    MINUTE=$(echo "$TARGET_TIME" | cut -d: -f2)

    if [ "$HOUR" -gt 23 ] || [ "$MINUTE" -gt 59 ]; then
        echo "Error: Invalid time. Hour must be 00-23, minute must be 00-59"
        exit 1
    fi
    
    echo "Script will execute at $TARGET_TIME"
    echo "Press Ctrl+C at any time to cancel"
fi

echo "Preventing system sleep..."

# Start caffeinate to prevent system sleep
caffeinate -d -i -s &
CAFFEINATE_PID=$!

# Check if caffeinate started successfully
if ! kill -0 "$CAFFEINATE_PID" 2>/dev/null; then
    echo "Error: Failed to start caffeinate process"
    exit 1
fi

echo "Caffeinate started with PID: $CAFFEINATE_PID"

# Only wait if a specific time was provided and it's different from current time
if [ $# -ge 1 ] && [ "$(date +"%H:%M")" != "$TARGET_TIME" ]; then
    # Function to get current time in HH:MM format
    get_current_time() {
        date +"%H:%M"
    }

    # Wait until target time
    while true; do
        CURRENT_TIME=$(get_current_time)
        if [ "$CURRENT_TIME" = "$TARGET_TIME" ]; then
            echo "Target time reached: $TARGET_TIME"
            break
        fi
        echo "Current time: $CURRENT_TIME - Waiting for $TARGET_TIME..."
        
        # Use a loop with shorter sleep intervals for better interrupt handling
        for i in {1..30}; do
            sleep 1
            # This allows the script to check for interrupts more frequently
        done
    done
fi

echo "Finding all Terminal windows and sending '$COMMAND_TEXT' command..."

# Check if Terminal app is running (支援中文和英文版 macOS)
if ! pgrep -x "Terminal" > /dev/null && ! pgrep -x "終端機" > /dev/null; then
    echo "Error: Terminal/終端機 application is not running"
    echo "請開啟終端機後再試一次 / Please open Terminal and try again"
    exit 1
fi

# Determine which Terminal app name to use
if pgrep -x "Terminal" > /dev/null; then
    TERMINAL_APP="Terminal"
elif pgrep -x "終端機" > /dev/null; then
    TERMINAL_APP="終端機"
fi

# Check if we have permission to control Terminal
if ! osascript -e 'tell application "System Events" to return' &> /dev/null; then
    echo "Error: Unable to access System Events"
    echo "Please grant Terminal permission in System Preferences > Security & Privacy > Privacy > Accessibility"
    exit 1
fi

# AppleScript to find all Terminal windows and type 'continue' + Enter
# Disable strict mode temporarily for osascript as it may return non-zero on warnings
set +e
osascript <<EOF
tell application "$TERMINAL_APP"
    -- Get count of windows
    set windowCount to count of windows
    
    if windowCount > 0 then
        -- Loop through all windows
        repeat with i from 1 to windowCount
            -- First, activate the window to bring it to front
            set frontmost of window i to true
            activate
            
            -- Small delay to ensure window is fully activated
            delay 0.5
            
            -- Loop through all tabs in the window
            set tabCount to count of tabs of window i
            repeat with j from 1 to tabCount
                -- Select the tab
                set selected of tab j of window i to true
                
                -- Small delay to ensure the tab is active
                delay 0.3
                
                -- Type the command and press Enter
                tell application "System Events"
                    tell process "$TERMINAL_APP"
                        -- Type the command text
                        keystroke "$COMMAND_TEXT"
                        delay 0.2
                        
                        -- Use key code 36 for Enter key
                        key code 36
                    end tell
                end tell
                
                -- Small delay between tabs
                delay 0.3
            end repeat
        end repeat
        
        display notification "Sent '$COMMAND_TEXT' to all terminal windows" with title "Auto Continue Script"
    else
        display notification "No Terminal windows found" with title "Auto Continue Script"
    end if
end tell
EOF

# Capture osascript exit code
OSASCRIPT_EXIT_CODE=$?

# Re-enable strict mode
set -e

# Check if osascript executed successfully
if [ $OSASCRIPT_EXIT_CODE -ne 0 ]; then
    echo "Error: Failed to execute AppleScript (exit code: $OSASCRIPT_EXIT_CODE)"
    echo "This may be due to:"
    echo "  - Terminal not having Accessibility permissions"
    echo "  - Terminal windows being minimized or hidden"
    echo "  - System security restrictions"
    exit 1
fi

echo "Script completed successfully!"
