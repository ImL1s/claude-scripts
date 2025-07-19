#!/bin/bash

echo "Testing history-based detection..."

# Check Terminal app name
if pgrep -x "Terminal" > /dev/null; then
    TERMINAL_APP="Terminal"
elif pgrep -x "終端機" > /dev/null; then
    TERMINAL_APP="終端機"
else
    echo "Terminal not running"
    exit 1
fi

# Create a temporary file to store tty devices
TTY_FILE=$(mktemp)

# First, get all TTY devices
osascript -e "
tell application \"$TERMINAL_APP\"
    set ttyList to \"\"
    repeat with w from 1 to count of windows
        repeat with t from 1 to count of tabs of window w
            set ttyDevice to tty of tab t of window w
            set ttyList to ttyList & ttyDevice & \"\n\"
        end repeat
    end repeat
    return ttyList
end tell
" > "$TTY_FILE"

echo "Checking each terminal's history..."

# For each TTY, check its history
while IFS= read -r tty; do
    if [ -n "$tty" ]; then
        echo "Checking $tty:"
        
        # Extract the pts number from tty (e.g., /dev/ttys010 -> 10)
        pts_num=$(echo "$tty" | sed 's/.*ttys//')
        
        # Try to find the shell process for this tty
        shell_pid=$(ps -t "$tty" -o pid,comm | grep -E "zsh|bash" | awk '{print $1}' | head -1)
        
        if [ -n "$shell_pid" ]; then
            echo "  Shell PID: $shell_pid"
            
            # Check if we can access the history file
            # For zsh, history is usually in ~/.zsh_history
            # For bash, it's ~/.bash_history
            
            # Try to get the last few commands from history
            # This is a bit tricky because we need to identify which history belongs to which terminal
        else
            echo "  No shell process found"
        fi
        
        # Alternative: Check if any claude-related process is associated with this tty
        claude_check=$(ps -t "$tty" | grep -i claude | grep -v grep)
        if [ -n "$claude_check" ]; then
            echo "  Claude process found: $claude_check"
        fi
        
        echo ""
    fi
done < "$TTY_FILE"

# Clean up
rm -f "$TTY_FILE"

echo "Alternative approach: Check for marker files..."
echo "We could have each Claude session create a marker file with its TTY"
