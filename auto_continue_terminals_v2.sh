#!/bin/bash
#
# auto_continue_terminals_v2.sh
# 
# Description:
#   Advanced version that supports path-based filtering and Claude detection
#   Can handle multiple configurations with different paths, times, and commands
#
# Usage:
#   ./auto_continue_terminals_v2.sh                    # Execute immediately to Claude terminals
#   ./auto_continue_terminals_v2.sh HH:MM              # Legacy: execute at time
#   ./auto_continue_terminals_v2.sh HH:MM "command"    # Legacy: execute with custom command
#   ./auto_continue_terminals_v2.sh "path:HH:MM:command" ["path2:HH:MM:command2" ...]  # Advanced mode
#
# Examples:
#   ./auto_continue_terminals_v2.sh "/Users/me/project:14:30:continue" 
#   ./auto_continue_terminals_v2.sh "/Users/me/work:15:00:analyze the code" "/Users/me/test:16:00:run tests"
#
# Version: 2.0.0
#

set -e
set -o pipefail

# Global variables
CAFFEINATE_PID=""
declare -a TASKS=()
LEGACY_MODE=false

# Cleanup function
cleanup() {
    echo -e "\n\nCleaning up..."
    if [ -n "$CAFFEINATE_PID" ] && kill -0 "$CAFFEINATE_PID" 2>/dev/null; then
        echo "Stopping caffeinate process (PID: $CAFFEINATE_PID)..."
        kill "$CAFFEINATE_PID" 2>/dev/null || true
    fi
    echo "Cleanup completed."
    exit
}

trap cleanup EXIT INT TERM HUP

# Function to validate time format
validate_time() {
    local time=$1
    if ! [[ "$time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        return 1
    fi
    local hour=$(echo "$time" | cut -d: -f1)
    local minute=$(echo "$time" | cut -d: -f2)
    if [ "$hour" -gt 23 ] || [ "$minute" -gt 59 ]; then
        return 1
    fi
    return 0
}

# Function to parse task configuration
parse_task() {
    local config=$1
    local path time cmd
    
    # Split by first two colons to handle commands with colons
    path=$(echo "$config" | cut -d: -f1)
    time=$(echo "$config" | cut -d: -f2)
    cmd=$(echo "$config" | cut -d: -f3-)
    
    if [ -z "$path" ] || [ -z "$time" ] || [ -z "$cmd" ]; then
        echo "Error: Invalid task format: $config"
        echo "Expected format: path:HH:MM:command"
        return 1
    fi
    
    if ! validate_time "$time"; then
        echo "Error: Invalid time format in task: $config"
        return 1
    fi
    
    # Add to tasks array
    TASKS+=("$config")
    return 0
}

# Parse arguments
if [ $# -eq 0 ]; then
    # No arguments - execute immediately to all Claude terminals
    echo "Executing immediately with 'continue' to all Claude terminals..."
    TASKS+=("*:$(date +"%H:%M"):continue")
elif [ $# -eq 1 ]; then
    if [[ "$1" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        # Legacy mode - time only
        LEGACY_MODE=true
        TASKS+=("*:$1:continue")
        echo "Legacy mode: Will execute 'continue' at $1"
    elif [[ "$1" =~ .*:.*:.* ]]; then
        # Advanced mode - single task
        if ! parse_task "$1"; then
            exit 1
        fi
    else
        echo "Error: Invalid argument format"
        exit 1
    fi
elif [ $# -eq 2 ] && [[ "$1" =~ ^[0-9]{2}:[0-9]{2}$ ]] && ! [[ "$2" =~ .*:.*:.* ]]; then
    # Legacy mode - time and command
    LEGACY_MODE=true
    TASKS+=("*:$1:$2")
    echo "Legacy mode: Will execute '$2' at $1"
else
    # Advanced mode - multiple tasks
    for task in "$@"; do
        if ! parse_task "$task"; then
            exit 1
        fi
    done
fi

echo "Preventing system sleep..."
caffeinate -d -i -s &
CAFFEINATE_PID=$!

# Function to check if current time matches any task
check_tasks() {
    local current_time=$1
    local matched_tasks=()
    
    for task in "${TASKS[@]}"; do
        local task_time=$(echo "$task" | cut -d: -f2)
        if [ "$current_time" = "$task_time" ]; then
            matched_tasks+=("$task")
        fi
    done
    
    printf '%s\n' "${matched_tasks[@]}"
}

# Function to execute tasks
execute_tasks() {
    local tasks=("$@")
    
    for task in "${tasks[@]}"; do
        local path=$(echo "$task" | cut -d: -f1)
        local cmd=$(echo "$task" | cut -d: -f3-)
        
        echo "Executing task: path=$path, command=$cmd"
        
        # Check Terminal app
        local TERMINAL_APP=""
        if pgrep -x "Terminal" > /dev/null; then
            TERMINAL_APP="Terminal"
        elif pgrep -x "終端機" > /dev/null; then
            TERMINAL_APP="終端機"
        else
            echo "Error: Terminal not running"
            continue
        fi
        
        # Execute AppleScript
        osascript <<EOF
tell application "$TERMINAL_APP"
    set windowCount to count of windows
    
    if windowCount > 0 then
        repeat with i from 1 to windowCount
            set tabCount to count of tabs of window i
            
            repeat with j from 1 to tabCount
                set selected of tab j of window i to true
                delay 0.3
                
                -- Check if we should process this tab
                set shouldProcess to false
                
                if "$path" = "*" and $LEGACY_MODE then
                    -- Legacy mode: process all tabs
                    set shouldProcess to true
                else
                    -- Get current directory
                    tell window i
                        set tabContents to contents of tab j
                        -- Check if Claude is running (look for Claude in processes)
                        if tabContents contains "claude" or tabContents contains "Claude" then
                            if "$path" = "*" then
                                -- Process all Claude terminals
                                set shouldProcess to true
                            else
                                -- Check if path matches
                                do script "pwd" in tab j
                                delay 0.5
                                set currentPath to (do script "echo \\\$PWD" in tab j)
                                if currentPath starts with "$path" then
                                    set shouldProcess to true
                                end if
                            end if
                        end if
                    end tell
                end if
                
                if shouldProcess then
                    set frontmost of window i to true
                    activate
                    delay 0.3
                    
                    tell application "System Events"
                        tell process "$TERMINAL_APP"
                            keystroke "$cmd"
                            delay 0.2
                            key code 36
                        end tell
                    end tell
                    
                    delay 0.5
                end if
            end repeat
        end repeat
    end if
end tell
EOF
    done
}

# Main execution loop
echo "Starting task scheduler..."
echo "Tasks:"
for task in "${TASKS[@]}"; do
    echo "  - $task"
done

# Track executed tasks to avoid duplicates
declare -A executed_tasks

while true; do
    current_time=$(date +"%H:%M")
    
    # Check for tasks to execute
    mapfile -t tasks_to_run < <(check_tasks "$current_time")
    
    if [ ${#tasks_to_run[@]} -gt 0 ]; then
        for task in "${tasks_to_run[@]}"; do
            task_key="${current_time}_${task}"
            if [ -z "${executed_tasks[$task_key]}" ]; then
                echo "Executing task at $current_time"
                execute_tasks "$task"
                executed_tasks[$task_key]=1
            fi
        done
    fi
    
    # Check if all tasks are done
    all_done=true
    for task in "${TASKS[@]}"; do
        task_time=$(echo "$task" | cut -d: -f2)
        task_key="${task_time}_${task}"
        if [ -z "${executed_tasks[$task_key]}" ]; then
            all_done=false
            break
        fi
    done
    
    if $all_done; then
        echo "All tasks completed!"
        break
    fi
    
    # Sleep for a short interval
    sleep 30
done

echo "Script completed successfully!"
