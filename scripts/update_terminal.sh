#!/bin/bash

# Arch Linux Update Terminal Script
# Self-contained script with launcher and interactive modes

# Set environment variables for better terminal compatibility
export TERM=xterm-256color
export COLORTERM=truecolor
export KITTY_DISABLE_WAYLAND=1
export NO_COLOR=0
export FORCE_COLOR=1

# Color definitions (compatible with all terminals)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print with colors
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    clear
    print_colored "$CYAN" "============================================"
    print_colored "$CYAN" "        Arch Linux System Update"
    print_colored "$CYAN" "============================================"
    echo
}

# Function to check for updates
check_updates() {
    print_colored "$BLUE" "🔍 Checking for available updates..."
    
    # Check pacman updates
    if command -v checkupdates >/dev/null 2>&1; then
        PACMAN_UPDATES=$(checkupdates 2>/dev/null | wc -l)
    else
        PACMAN_UPDATES=0
    fi
    
    # Check AUR updates
    AUR_UPDATES=0
    if command -v yay >/dev/null 2>&1; then
        AUR_UPDATES=$(yay -Qum 2>/dev/null | wc -l)
    elif command -v paru >/dev/null 2>&1; then
        AUR_UPDATES=$(paru -Qua 2>/dev/null | wc -l)
    fi
    
    TOTAL_UPDATES=$((PACMAN_UPDATES + AUR_UPDATES))
    
    echo
    print_colored "$WHITE" "📊 Update Summary:"
    print_colored "$GREEN" "   Official packages: $PACMAN_UPDATES"
    print_colored "$YELLOW" "   AUR packages: $AUR_UPDATES"
    print_colored "$BOLD" "   Total updates: $TOTAL_UPDATES"
    echo
}

# Function to show menu
show_menu() {
    print_colored "$WHITE" "📋 Available Actions:"
    echo "   1) Update all packages (Pacman + AUR)"
    echo "   2) Update official packages only"
    echo "   3) Update AUR packages only"
    echo "   4) Clean package cache"
    echo "   5) Check system logs for errors"
    echo "   6) System maintenance"
    echo "   7) Show system information"
    echo "   8) Exit"
    echo
}

# Function to execute with progress
execute_with_progress() {
    local command="$1"
    local description="$2"
    
    print_colored "$BLUE" "🚀 $description"
    print_colored "$CYAN" "Command: $command"
    echo
    
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    echo
    
    eval "$command"
    local exit_code=$?
    
    echo
    if [ $exit_code -eq 0 ]; then
        print_colored "$GREEN" "✅ Operation completed successfully!"
    else
        print_colored "$RED" "❌ Operation failed with exit code: $exit_code"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function to detect and configure terminal
detect_terminal() {
    if command -v kitty >/dev/null 2>&1; then
        # Kitty with sRGB fix and color profile override
        TERMINAL="kitty"
        TERMINAL_ARGS="--config NONE -o background_opacity=0.9 -o term=xterm-256color -o allow_remote_control=no -o macos_colorspace=srgb"
    elif command -v alacritty >/dev/null 2>&1; then
        TERMINAL="alacritty"
        TERMINAL_ARGS=""
    elif command -v wezterm >/dev/null 2>&1; then
        TERMINAL="wezterm"
        TERMINAL_ARGS="start --"
    elif command -v foot >/dev/null 2>&1; then
        TERMINAL="foot"
        TERMINAL_ARGS=""
    elif command -v terminator >/dev/null 2>&1; then
        TERMINAL="terminator"
        TERMINAL_ARGS="-x"
    else
        # Fallback to xterm
        TERMINAL="xterm"
        TERMINAL_ARGS="-e"
    fi
}

# Interactive mode - runs the actual update menu
run_interactive_mode() {
    print_header
    check_updates
    
    if [ $TOTAL_UPDATES -eq 0 ]; then
        print_colored "$GREEN" "✅ Your system is already up to date!"
        echo
        print_colored "$CYAN" "You can still perform maintenance tasks below."
        echo
    fi
    
    while true; do
        show_menu
        
        read -p "Enter your choice (1-8): " choice
        echo
        
        case $choice in
            1)
                if command -v yay >/dev/null 2>&1; then
                    execute_with_progress "sudo pacman -Syu && yay -Syu" "Updating all packages"
                elif command -v paru >/dev/null 2>&1; then
                    execute_with_progress "sudo pacman -Syu && paru -Syu" "Updating all packages"
                else
                    execute_with_progress "sudo pacman -Syu" "Updating official packages only"
                fi
                ;;
            2)
                execute_with_progress "sudo pacman -Syu" "Updating official packages"
                ;;
            3)
                if command -v yay >/dev/null 2>&1; then
                    execute_with_progress "yay -Syu --aur" "Updating AUR packages"
                elif command -v paru >/dev/null 2>&1; then
                    execute_with_progress "paru -Syu --aur" "Updating AUR packages"
                else
                    print_colored "$RED" "❌ No AUR helper found (yay or paru required)"
                    read -p "Press Enter to continue..."
                fi
                ;;
            4)
                execute_with_progress "sudo pacman -Sc && sudo rm -rf /tmp/* && sudo journalctl --vacuum-time=7d" "Cleaning system cache"
                ;;
            5)
                print_colored "$BLUE" "🔍 Checking system logs for errors..."
                echo
                journalctl -p 3 -n 20 --no-pager
                echo
                read -p "Press Enter to continue..."
                ;;
            6)
                execute_with_progress "sudo fstrim -av && sudo sync" "Running system maintenance"
                ;;
            7)
                if command -v neofetch >/dev/null 2>&1; then
                    neofetch
                else
                    uname -a
                    lscpu | head -10
                    free -h
                    df -h
                fi
                echo
                read -p "Press Enter to continue..."
                ;;
            8)
                print_colored "$GREEN" "👋 Goodbye!"
                exit 0
                ;;
            *)
                print_colored "$RED" "❌ Invalid choice. Please try again."
                sleep 1
                ;;
        esac
        
        clear
        print_header
        check_updates
    done
}

# Launcher mode - detects terminal and launches interactive mode
run_launcher_mode() {
    detect_terminal
    
    # Get the absolute path to this script
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
    
    # Launch this script in interactive mode in the detected terminal
    $TERMINAL $TERMINAL_ARGS "$SCRIPT_PATH" --interactive
}

# Main execution logic
main() {
    # Parse command line arguments
    case "${1:-}" in
        --interactive)
            # Interactive mode - run the menu directly
            run_interactive_mode
            ;;
        *)
            # Launcher mode - detect terminal and launch interactive mode
            run_launcher_mode
            ;;
    esac
}

# If script is executed directly, run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi