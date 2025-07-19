#!/bin/bash

echo "Testing Claude detection..."

# Check Terminal app name
if pgrep -x "Terminal" > /dev/null; then
    TERMINAL_APP="Terminal"
elif pgrep -x "終端機" > /dev/null; then
    TERMINAL_APP="終端機"
else
    echo "Terminal not running"
    exit 1
fi

osascript -e "
tell application \"$TERMINAL_APP\"
    set windowCount to count of windows
    set output to \"Windows found: \" & windowCount & \"\n\"
    
    repeat with i from 1 to windowCount
        set tabCount to count of tabs of window i
        set output to output & \"Window \" & i & \" has \" & tabCount & \" tabs:\n\"
        
        repeat with j from 1 to tabCount
            -- Get tty
            set ttyDevice to tty of tab j of window i
            
            -- Get custom title if available
            set tabTitle to \"\"
            try
                set tabTitle to custom title of tab j of window i
            end try
            
            -- Get session ID
            set sessionID to text -4 thru -1 of ttyDevice
            
            set output to output & \"  Tab \" & j & \": tty=\" & ttyDevice & \", sessionID=\" & sessionID & \", title='\" & tabTitle & \"'\n\"
            
            -- Check for Claude process
            set shellCommand to \"ps aux | grep \" & quoted form of sessionID & \" | grep -i claude | grep -v grep\"
            try
                set claudeProcesses to do shell script shellCommand
                set output to output & \"    Claude found: \" & claudeProcesses & \"\n\"
            on error
                set output to output & \"    No Claude process found\n\"
            end try
        end repeat
    end repeat
    
    return output
end tell
"
