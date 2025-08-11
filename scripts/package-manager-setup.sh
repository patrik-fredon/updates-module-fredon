#!/bin/bash

# Package Manager Setup Script for Updates Module Fredon
# Installs and configures required package managers for Arch Linux

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    print_colored "$CYAN" "    Package Manager Setup - Fredon"
    print_colored "$CYAN" "============================================"
    echo
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install yay AUR helper
install_yay() {
    print_colored "$BLUE" "🔧 Installing yay AUR helper..."
    
    if command_exists yay; then
        print_colored "$GREEN" "✅ yay is already installed"
        return 0
    fi
    
    # Check if git is installed
    if ! command_exists git; then
        print_colored "$YELLOW" "📦 Installing git..."
        sudo pacman -S --needed git
    fi
    
    # Check if base-devel is installed
    print_colored "$YELLOW" "📦 Installing base-devel..."
    sudo pacman -S --needed base-devel
    
    # Clone and build yay
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    
    # Clean up
    cd /
    rm -rf /tmp/yay
    
    if command_exists yay; then
        print_colored "$GREEN" "✅ yay installed successfully"
        return 0
    else
        print_colored "$RED" "❌ Failed to install yay"
        return 1
    fi
}

# Function to install paru AUR helper
install_paru() {
    print_colored "$BLUE" "🔧 Installing paru AUR helper..."
    
    if command_exists paru; then
        print_colored "$GREEN" "✅ paru is already installed"
        return 0
    fi
    
    # Check if git and rust are installed
    if ! command_exists git; then
        print_colored "$YELLOW" "📦 Installing git..."
        sudo pacman -S --needed git
    fi
    
    if ! command_exists cargo; then
        print_colored "$YELLOW" "📦 Installing rust..."
        sudo pacman -S --needed rust
    fi
    
    # Check if base-devel is installed
    print_colored "$YELLOW" "📦 Installing base-devel..."
    sudo pacman -S --needed base-devel
    
    # Clone and build paru
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    
    # Clean up
    cd /
    rm -rf /tmp/paru
    
    if command_exists paru; then
        print_colored "$GREEN" "✅ paru installed successfully"
        return 0
    else
        print_colored "$RED" "❌ Failed to install paru"
        return 1
    fi
}

# Function to install checkupdates
install_checkupdates() {
    print_colored "$BLUE" "🔧 Installing pacman-contrib (checkupdates)..."
    
    if command_exists checkupdates; then
        print_colored "$GREEN" "✅ checkupdates is already installed"
        return 0
    fi
    
    sudo pacman -S --needed pacman-contrib
    
    if command_exists checkupdates; then
        print_colored "$GREEN" "✅ checkupdates installed successfully"
        return 0
    else
        print_colored "$RED" "❌ Failed to install checkupdates"
        return 1
    fi
}

# Function to install Python dependencies
install_python_deps() {
    print_colored "$BLUE" "🔧 Installing Python dependencies..."
    
    # Check if python3 is installed
    if ! command_exists python3; then
        print_colored "$YELLOW" "📦 Installing Python..."
        sudo pacman -S --needed python
    fi
    
    # Check if pip is installed
    if ! command_exists pip; then
        print_colored "$YELLOW" "📦 Installing pip..."
        sudo pacman -S --needed python-pip
    fi
    
    # Install FreeSimpleGUI (optional for GUI features)
    print_colored "$YELLOW" "📦 Installing FreeSimpleGUI (optional)..."
    pip install --user FreeSimpleGUI || print_colored "$YELLOW" "⚠️ FreeSimpleGUI installation failed (GUI features will be disabled)"
    
    print_colored "$GREEN" "✅ Python dependencies check completed"
}

# Function to show menu
show_menu() {
    print_colored "$WHITE" "📋 Package Manager Installation Options:"
    echo "   1) Install yay (recommended)"
    echo "   2) Install paru (alternative to yay)"
    echo "   3) Install both yay and paru"
    echo "   4) Install checkupdates only"
    echo "   5) Install Python dependencies"
    echo "   6) Install everything (recommended for new systems)"
    echo "   7) Check current installation status"
    echo "   8) Exit"
    echo
}

# Function to check installation status
check_status() {
    print_colored "$WHITE" "📊 Current Installation Status:"
    echo
    
    # Check pacman
    if command_exists pacman; then
        print_colored "$GREEN" "✅ pacman: Installed"
    else
        print_colored "$RED" "❌ pacman: Not found (this shouldn't happen on Arch)"
    fi
    
    # Check checkupdates
    if command_exists checkupdates; then
        print_colored "$GREEN" "✅ checkupdates: Installed"
    else
        print_colored "$YELLOW" "⚠️ checkupdates: Not installed (install pacman-contrib)"
    fi
    
    # Check yay
    if command_exists yay; then
        print_colored "$GREEN" "✅ yay: Installed"
    else
        print_colored "$YELLOW" "⚠️ yay: Not installed"
    fi
    
    # Check paru
    if command_exists paru; then
        print_colored "$GREEN" "✅ paru: Installed"
    else
        print_colored "$YELLOW" "⚠️ paru: Not installed"
    fi
    
    # Check Python
    if command_exists python3; then
        print_colored "$GREEN" "✅ Python 3: Installed"
    else
        print_colored "$YELLOW" "⚠️ Python 3: Not installed"
    fi
    
    # Check FreeSimpleGUI
    if python3 -c "import FreeSimpleGUI" 2>/dev/null; then
        print_colored "$GREEN" "✅ FreeSimpleGUI: Installed (GUI features available)"
    else
        print_colored "$YELLOW" "⚠️ FreeSimpleGUI: Not installed (GUI features disabled)"
    fi
    
    echo
}

# Main execution
main() {
    print_header
    
    print_colored "$CYAN" "This script will help you install the required package managers"
    print_colored "$CYAN" "for the Updates Module Fredon to work properly."
    echo
    
    while true; do
        show_menu
        
        read -p "Enter your choice (1-8): " choice
        echo
        
        case $choice in
            1)
                install_checkupdates
                install_yay
                echo
                read -p "Press Enter to continue..."
                ;;
            2)
                install_checkupdates
                install_paru
                echo
                read -p "Press Enter to continue..."
                ;;
            3)
                install_checkupdates
                install_yay
                install_paru
                echo
                read -p "Press Enter to continue..."
                ;;
            4)
                install_checkupdates
                echo
                read -p "Press Enter to continue..."
                ;;
            5)
                install_python_deps
                echo
                read -p "Press Enter to continue..."
                ;;
            6)
                install_checkupdates
                install_python_deps
                install_yay
                print_colored "$GREEN" "🎉 Full installation completed!"
                echo
                read -p "Press Enter to continue..."
                ;;
            7)
                check_status
                read -p "Press Enter to continue..."
                ;;
            8)
                print_colored "$GREEN" "👋 Setup complete! The Updates Module should now work properly."
                exit 0
                ;;
            *)
                print_colored "$RED" "❌ Invalid choice. Please try again."
                sleep 1
                ;;
        esac
        
        clear
        print_header
    done
}

# Run main function
main "$@"