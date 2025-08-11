# Installation Guide

## Updates Module Fredon - Installation Instructions

**Patrik Fredon - FredonBytes - Where code meets innovation**

This guide will walk you through the complete installation process for the Updates Module Fredon.

## Prerequisites

Before installing, ensure your system meets these requirements:

### System Requirements

- **Operating System**: Arch Linux
- **Desktop Environment**: Hyprland
- **Status Bar**: Waybar
- **Python**: Version 3.8 or higher
- **Terminal**: kitty (recommended), alacritty, or any modern terminal

### Package Managers

At minimum, you need:

- `pacman` (pre-installed on Arch Linux)
- `checkupdates` (from pacman-contrib)

Optional but recommended:

- `yay` (AUR helper)
- `paru` (alternative AUR helper)

## Quick Installation (Recommended)

### Method 1: Automated Installation

```bash
# Clone the repository
git clone https://github.com/patrik-fredon/updates-module-fredon.git
cd updates-module-fredon

# Run the installation script
chmod +x install.sh
./install.sh
```

### Method 2: One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/patrik-fredon/updates-module-fredon/main/install.sh | bash
```

## Manual Installation

If you prefer to install manually or want to understand each step:

### Step 1: Download and Extract

```bash
# Download the latest release
wget https://github.com/patrik-fredon/updates-module-fredon/archive/main.zip
unzip main.zip
cd updates-module-fredon-main
```

### Step 2: Install Package Manager Dependencies

```bash
# Install required packages
sudo pacman -S pacman-contrib python python-pip

# Install AUR helper (choose one)
# Option A: Install yay
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Option B: Use the provided setup script
chmod +x scripts/package-manager-setup.sh
./scripts/package-manager-setup.sh
```

### Step 3: Copy Files to Waybar Directory

```bash
# Create directories if they don't exist
mkdir -p ~/.config/waybar/scripts

# Copy core scripts
cp src/arch_updates.py ~/.config/waybar/scripts/
cp src/arch_updates_simple.py ~/.config/waybar/scripts/
cp scripts/update_config.json ~/.config/waybar/scripts/
cp scripts/update_terminal.sh ~/.config/waybar/scripts/

# Make scripts executable
chmod +x ~/.config/waybar/scripts/arch_updates*.py
chmod +x ~/.config/waybar/scripts/update_terminal.sh
```

### Step 4: Configure Waybar

#### Option A: Backup and Replace Configuration

```bash
# Backup existing configuration
cp ~/.config/waybar/config.jsonc ~/.config/waybar/config.jsonc.backup
cp ~/.config/waybar/style.css ~/.config/waybar/style.css.backup

# Copy new configuration
cp config/waybar/config.jsonc ~/.config/waybar/
cp config/waybar/modules.json ~/.config/waybar/
cp config/waybar/style.css ~/.config/waybar/
```

#### Option B: Manual Integration

Add this to your existing `~/.config/waybar/config.jsonc`:

```jsonc
{
  "modules-right": [
    // ... your existing modules
    "custom/updates"
  ],

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
}
```

### Step 5: Install Optional GUI Dependencies

For the full GUI experience:

```bash
# Install FreeSimpleGUI
pip install --user FreeSimpleGUI

# Or use a virtual environment
python -m venv ~/.local/share/waybar-updates-env
source ~/.local/share/waybar-updates-env/bin/activate
pip install FreeSimpleGUI
```

### Step 6: Test Installation

```bash
# Test the simple script
~/.config/waybar/scripts/arch_updates_simple.py --check

# Test the full script
~/.config/waybar/scripts/arch_updates.py --check

# Test terminal integration
~/.config/waybar/scripts/arch_updates_simple.py --update
```

### Step 7: Restart Waybar

```bash
# Restart Waybar to load the new module
killall waybar && waybar &

# Or reload Waybar configuration
pkill -SIGUSR2 waybar
```

## Post-Installation Setup

### Configure Update Intervals

Edit `~/.config/waybar/scripts/update_config.json` to customize:

```json
{
  "update_settings": {
    "check_interval": 600,
    "package_managers": ["pacman", "yay", "paru"],
    "icons": {
      "no_updates": "✅",
      "updates_available": "📦",
      "updating": "🔄",
      "error": "⚠️"
    }
  }
}
```

### Set Up Automatic Updates (Optional)

Create a pacman hook to refresh the module after package operations:

```bash
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
```

## Verification

After installation, verify everything works:

1. **Check Waybar Module**: The updates module should appear in your Waybar
2. **Test Left Click**: Should open terminal update interface
3. **Test Right Click**: Should open GUI menu (if GUI dependencies installed)
4. **Check Tooltip**: Should show update information on hover

## Troubleshooting Installation

### Common Issues

1. **Module Not Appearing**

   ```bash
   # Check Waybar config syntax
   waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css --log-level debug
   ```

2. **Permission Denied**

   ```bash
   chmod +x ~/.config/waybar/scripts/arch_updates*.py
   ```

3. **Python Import Errors**

   ```bash
   # Check Python installation
   python3 --version
   python3 -c "import json; print('JSON OK')"
   ```

4. **GUI Not Working**
   ```bash
   # Test GUI availability
   python3 -c "import FreeSimpleGUI; print('GUI Available')"
   ```

## Uninstallation

To remove the module:

```bash
# Remove scripts
rm ~/.config/waybar/scripts/arch_updates*.py
rm ~/.config/waybar/scripts/update_config.json
rm ~/.config/waybar/scripts/update_terminal.sh

# Remove from Waybar config (manual edit required)
# Remove the custom/updates section from config.jsonc

# Remove pacman hook
sudo rm /etc/pacman.d/hooks/waybar-update.hook

# Restart Waybar
killall waybar && waybar &
```

## Support

If you encounter issues during installation:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review the [Implementation Guide](IMPLEMENTATION.md)
3. Open an issue on GitHub with your system information and error logs

---

**Et in tenebris codicem inveni lucem**
_"In the darkness, I found the light of code"_

---

© 2025 Fredon - FredonBytes
