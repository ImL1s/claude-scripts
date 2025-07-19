#!/bin/bash
#
# claude_marker.sh - Mark/unmark terminals running Claude
#
# Usage:
#   claude_marker.sh mark    # Mark current terminal as running Claude
#   claude_marker.sh unmark  # Unmark current terminal
#   claude_marker.sh list    # List all terminals marked as running Claude
#   claude_marker.sh clean   # Clean up stale markers

MARKER_DIR="$HOME/.claude_markers"

# Create marker directory if it doesn't exist
mkdir -p "$MARKER_DIR"

# Get current TTY
CURRENT_TTY=$(tty)
TTY_ID=$(echo "$CURRENT_TTY" | sed 's/\/dev\///')

case "$1" in
    mark)
        # Create a marker file for this terminal
        echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$MARKER_DIR/$TTY_ID"
        echo "Marked $CURRENT_TTY as running Claude"
        ;;
        
    unmark)
        # Remove the marker file
        rm -f "$MARKER_DIR/$TTY_ID"
        echo "Unmarked $CURRENT_TTY"
        ;;
        
    list)
        echo "Terminals marked as running Claude:"
        for marker in "$MARKER_DIR"/*; do
            if [ -f "$marker" ]; then
                tty_id=$(basename "$marker")
                tty_device="/dev/$tty_id"
                
                # Check if the TTY is still active
                if ps -t "$tty_device" > /dev/null 2>&1; then
                    marked_time=$(cat "$marker")
                    echo "  $tty_device (marked at $marked_time)"
                else
                    echo "  $tty_device (stale - TTY no longer active)"
                fi
            fi
        done
        ;;
        
    clean)
        echo "Cleaning up stale markers..."
        cleaned=0
        for marker in "$MARKER_DIR"/*; do
            if [ -f "$marker" ]; then
                tty_id=$(basename "$marker")
                tty_device="/dev/$tty_id"
                
                # Remove marker if TTY is no longer active
                if ! ps -t "$tty_device" > /dev/null 2>&1; then
                    rm -f "$marker"
                    echo "  Removed stale marker for $tty_device"
                    ((cleaned++))
                fi
            fi
        done
        echo "Cleaned up $cleaned stale markers"
        ;;
        
    *)
        echo "Usage: $0 {mark|unmark|list|clean}"
        echo ""
        echo "Mark/unmark terminals as running Claude for auto_continue_terminals.sh"
        echo ""
        echo "Commands:"
        echo "  mark    - Mark current terminal as running Claude"
        echo "  unmark  - Unmark current terminal"
        echo "  list    - List all terminals marked as running Claude"
        echo "  clean   - Clean up stale markers"
        exit 1
        ;;
esac
