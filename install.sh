#!/bin/bash

# Updates Module Fredon - Installation Script
# Patrik Fredon - FredonBytes - Where code meets innovation

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
    echo
    print_colored "$CYAN" "╔════════════════════════════════════════════════════════════╗"
    print_colored "$CYAN" "║                 Updates Module Fredon                      ║"
    print_colored "$CYAN" "║              Installation Script v1.0                     ║"
    print_colored "$CYAN" "║                                                            ║"
    print_colored "$CYAN" "║        Fredon - FredonBytes - Where code meets innovation ║"
    print_colored "$CYAN" "╚════════════════════════════════════════════════════════════╝"
    echo
    print_colored "$WHITE" "Et in tenebris codicem inveni lucem"
    print_colored "$WHITE" "\"In the darkness, I found the light of code\""
    echo
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_colored "$BLUE" "📁 Created directory: $dir"
    fi
}

# Function to backup existing files
backup_existing() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_colored "$YELLOW" "💾 Backed up existing file: $file -> $backup"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_colored "$BLUE" "🔧 Installing dependencies..."

    # Check for required system packages
    local packages_needed=()

    if ! command_exists python3; then
        packages_needed+=("python")
    fi

    if ! command_exists checkupdates; then
        packages_needed+=("pacman-contrib")
    fi

    if [ ${#packages_needed[@]} -gt 0 ]; then
        print_colored "$YELLOW" "📦 Installing system packages: ${packages_needed[*]}"
        sudo pacman -S --needed "${packages_needed[@]}" || {
            print_colored "$RED" "❌ Failed to install system packages"
            return 1
        }
    fi

    # Install Python dependencies
    if command_exists pip; then
        print_colored "$YELLOW" "🐍 Installing FreeSimpleGUI (optional)..."
        pip install --user FreeSimpleGUI || print_colored "$YELLOW" "⚠️ FreeSimpleGUI installation failed (GUI features will be disabled)"
    fi

    print_colored "$GREEN" "✅ Dependencies installation completed"
}

# Function to install AUR helper
install_aur_helper() {
    if command_exists yay || command_exists paru; then
        print_colored "$GREEN" "✅ AUR helper already installed"
        return 0
    fi

    print_colored "$BLUE" "🏗️ Installing yay AUR helper..."

    # Install dependencies for building
    sudo pacman -S --needed git base-devel || {
        print_colored "$RED" "❌ Failed to install build dependencies"
        return 1
    }

    # Clone and build yay
    cd /tmp
    git clone https://aur.archlinux.org/yay.git || {
        print_colored "$RED" "❌ Failed to clone yay repository"
        return 1
    }

    cd yay
    makepkg -si --noconfirm || {
        print_colored "$RED" "❌ Failed to build yay"
        cd /
        rm -rf /tmp/yay
        return 1
    }

    # Clean up
    cd /
    rm -rf /tmp/yay

    if command_exists yay; then
        print_colored "$GREEN" "✅ yay installed successfully"
        return 0
    else
        print_colored "$RED" "❌ yay installation failed"
        return 1
    fi
}

# Function to copy files
install_files() {
    print_colored "$BLUE" "📋 Installing module files..."

    local waybar_dir="$HOME/.config/waybar"
    local scripts_dir="$waybar_dir/scripts"

    # Create directories
    ensure_directory "$waybar_dir"
    ensure_directory "$scripts_dir"

    # Copy core scripts
    print_colored "$YELLOW" "📄 Installing core scripts..."
    cp src/arch_updates.py "$scripts_dir/" || return 1
    cp src/arch_updates_simple.py "$scripts_dir/" || return 1
    cp scripts/update_terminal.sh "$scripts_dir/" || return 1

    # Copy configuration
    if [ ! -f "$scripts_dir/update_config.json" ]; then
        cp scripts/update_config.json "$scripts_dir/" || return 1
        print_colored "$GREEN" "📄 Installed configuration file"
    else
        print_colored "$YELLOW" "⚠️ Configuration file exists, skipping (use --force to overwrite)"
    fi

    # Make scripts executable
    chmod +x "$scripts_dir/arch_updates.py"
    chmod +x "$scripts_dir/arch_updates_simple.py"
    chmod +x "$scripts_dir/update_terminal.sh"

    print_colored "$GREEN" "✅ Core files installed successfully"
}

# Function to configure Waybar
configure_waybar() {
    print_colored "$BLUE" "⚙️ Configuring Waybar..."

    local waybar_dir="$HOME/.config/waybar"
    local config_file="$waybar_dir/config.jsonc"
    local modules_file="$waybar_dir/modules.json"
    local style_file="$waybar_dir/style.css"

    # Ask user about Waybar configuration
    echo
    print_colored "$YELLOW" "Waybar Configuration Options:"
    echo "1) Backup and replace existing configuration (recommended for new setups)"
    echo "2) Merge with existing configuration (manual integration required)"
    echo "3) Skip Waybar configuration (manual setup required)"
    echo

    read -p "Choose option (1-3): " waybar_choice

    case $waybar_choice in
        1)
            # Backup existing files
            backup_existing "$config_file"
            backup_existing "$modules_file"
            backup_existing "$style_file"

            # Copy new configuration
            cp config/waybar/config.jsonc "$waybar_dir/"
            cp config/waybar/modules.json "$waybar_dir/"
            cp config/waybar/style.css "$waybar_dir/"

            print_colored "$GREEN" "✅ Waybar configuration replaced"
            ;;
        2)
            print_colored "$YELLOW" "📋 Manual integration required:"
            print_colored "$WHITE" "Add this to your config.jsonc modules-right array:"
            echo '    "custom/updates"'
            echo
            print_colored "$WHITE" "Add this to your config.jsonc:"
            cat << 'EOF'
  "custom/updates": {
    "format": "{}",
    "interval": 600,
    "exec": "~/.config/waybar/scripts/arch_updates_simple.py --check",
    "exec-if": "test -f ~/.config/waybar/scripts/arch_updates_simple.py",
    "on-click": "~/.config/waybar/scripts/arch_updates_simple.py --update",
    "on-click-right": "~/.config/waybar/scripts/arch_updates.py --menu",
    "return-type": "json",
    "signal": 8,
    "tooltip": true,
    "escape": true
  }
EOF
            ;;
        3)
            print_colored "$YELLOW" "⚠️ Waybar configuration skipped"
            print_colored "$WHITE" "See docs/INSTALLATION.md for manual setup instructions"
            ;;
        *)
            print_colored "$RED" "❌ Invalid choice, skipping Waybar configuration"
            ;;
    esac
}

# Function to set up system hooks
setup_hooks() {
    print_colored "$BLUE" "🔗 Setting up system hooks..."

    echo
    read -p "Install pacman hook for automatic updates? (y/N): " install_hook

    if [[ $install_hook =~ ^[Yy]$ ]]; then
        sudo mkdir -p /etc/pacman.d/hooks
        sudo tee /etc/pacman.d/hooks/waybar-update.hook > /dev/null << 'EOF'
[Trigger]
Operation = Install
Operation = Remove
Operation = Upgrade
Type = Package
Target = *

[Action]
When = PostTransaction
Exec = /usr/bin/pkill -SIGRTMIN+8 waybar
EOF
        print_colored "$GREEN" "✅ Pacman hook installed"
    else
        print_colored "$YELLOW" "⚠️ Pacman hook skipped"
    fi
}

# Function to test installation
test_installation() {
    print_colored "$BLUE" "🧪 Testing installation..."

    local scripts_dir="$HOME/.config/waybar/scripts"

    # Test script execution
    if "$scripts_dir/arch_updates_simple.py" --check >/dev/null 2>&1; then
        print_colored "$GREEN" "✅ Simple script test passed"
    else
        print_colored "$RED" "❌ Simple script test failed"
        return 1
    fi

    # Test configuration loading
    if python3 -c "import json; json.load(open('$scripts_dir/update_config.json'))" 2>/dev/null; then
        print_colored "$GREEN" "✅ Configuration file test passed"
    else
        print_colored "$RED" "❌ Configuration file test failed"
        return 1
    fi

    print_colored "$GREEN" "✅ Installation tests completed successfully"
}

# Function to restart Waybar
restart_waybar() {
    print_colored "$BLUE" "🔄 Restarting Waybar..."

    echo
    read -p "Restart Waybar now? (y/N): " restart_choice

    if [[ $restart_choice =~ ^[Yy]$ ]]; then
        killall waybar 2>/dev/null
        sleep 1
        waybar &
        print_colored "$GREEN" "✅ Waybar restarted"
    else
        print_colored "$YELLOW" "⚠️ Please restart Waybar manually: killall waybar && waybar &"
    fi
}

# Function to show completion message
show_completion() {
    echo
    print_colored "$GREEN" "🎉 Installation completed successfully!"
    echo
    print_colored "$CYAN" "Quick Start:"
    print_colored "$WHITE" "• Left click the module to open terminal update interface"
    print_colored "$WHITE" "• Right click the module to open GUI menu (if GUI installed)"
    print_colored "$WHITE" "• Module will automatically check for updates every 10 minutes"
    echo
    print_colored "$CYAN" "Documentation:"
    print_colored "$WHITE" "• Installation Guide: docs/INSTALLATION.md"
    print_colored "$WHITE" "• Implementation Guide: docs/IMPLEMENTATION.md"
    print_colored "$WHITE" "• Troubleshooting Guide: docs/TROUBLESHOOTING.md"
    echo
    print_colored "$CYAN" "Configuration:"
    print_colored "$WHITE" "• Edit ~/.config/waybar/scripts/update_config.json to customize"
    print_colored "$WHITE" "• Modify ~/.config/waybar/style.css for visual customization"
    echo
    print_colored "$GREEN" "Thank you for using Updates Module Fredon!"
    print_colored "$WHITE" "Et in tenebris codicem inveni lucem"
    echo
}

# Main installation function
main() {
    # Check if running on Arch Linux
    if [ ! -f /etc/arch-release ]; then
        print_colored "$RED" "❌ This module is designed for Arch Linux"
        exit 1
    fi

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_colored "$RED" "❌ Do not run this script as root"
        exit 1
    fi

    # Parse command line arguments
    local force_install=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_install=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--force] [--help]"
                echo "  --force  Overwrite existing configuration files"
                echo "  --help   Show this help message"
                exit 0
                ;;
            *)
                print_colored "$RED" "❌ Unknown option: $1"
                exit 1
                ;;
        esac
    done

    print_header

    # Installation steps
    echo
    print_colored "$CYAN" "Starting installation process..."
    echo

    # Step 1: Install dependencies
    install_dependencies || {
        print_colored "$RED" "❌ Failed to install dependencies"
        exit 1
    }

    # Step 2: Install AUR helper (optional)
    echo
    read -p "Install yay AUR helper? (recommended) (y/N): " install_yay
    if [[ $install_yay =~ ^[Yy]$ ]]; then
        install_aur_helper
    fi

    # Step 3: Install files
    echo
    install_files || {
        print_colored "$RED" "❌ Failed to install files"
        exit 1
    }

    # Step 4: Configure Waybar
    echo
    configure_waybar

    # Step 5: Set up hooks
    echo
    setup_hooks

    # Step 6: Test installation
    echo
    test_installation || {
        print_colored "$RED" "❌ Installation tests failed"
        exit 1
    }

    # Step 7: Restart Waybar
    echo
    restart_waybar

    # Step 8: Show completion message
    show_completion
}

# Run main function with all arguments
main "$@"
