#!/bin/bash

echo "Testing terminal properties..."

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
            -- Get various properties
            set ttyDevice to tty of tab j of window i
            
            -- Get custom title
            set tabTitle to \"\"
            try
                set tabTitle to custom title of tab j of window i
            end try
            
            -- Get current settings (contents is not directly accessible)
            set isBusy to busy of tab j of window i
            set isSelected to selected of tab j of window i
            
            -- Get processes of the tab
            set processesInfo to \"\"
            try
                set processesInfo to processes of tab j of window i
            end try
            
            set output to output & \"  Tab \" & j & \":\n\"
            set output to output & \"    TTY: \" & ttyDevice & \"\n\"
            set output to output & \"    Title: '\" & tabTitle & \"'\n\"
            set output to output & \"    Busy: \" & isBusy & \"\n\"
            set output to output & \"    Selected: \" & isSelected & \"\n\"
            set output to output & \"    Processes: \" & processesInfo & \"\n\"
            
            -- Try to get history or current command (this might not work)
            try
                set historyInfo to history of tab j of window i
                set output to output & \"    History available: yes\n\"
            on error
                set output to output & \"    History available: no\n\"
            end try
            
        end repeat
    end repeat
    
    return output
end tell
"
