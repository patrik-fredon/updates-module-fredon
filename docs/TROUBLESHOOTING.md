# Troubleshooting Guide

## Updates Module Fredon - Problem Resolution

**Patrik Fredon - FredonBytes - Where code meets innovation**

This guide helps resolve common issues with the Updates Module Fredon.

## Common Issues

### 1. Module Not Appearing in Waybar

#### Symptoms

- Updates module doesn't show in Waybar
- Empty space where module should be
- Waybar shows error in logs

#### Solutions

**Check Waybar Configuration Syntax**

```bash
# Test Waybar configuration
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css --log-level debug

# Check for JSON syntax errors
python3 -m json.tool ~/.config/waybar/config.jsonc
```

**Verify Script Installation**

```bash
# Check if scripts exist
ls -la ~/.config/waybar/scripts/arch_updates*.py

# Check script permissions
chmod +x ~/.config/waybar/scripts/arch_updates*.py
```

**Restart Waybar**

```bash
# Kill and restart Waybar
killall waybar && waybar &

# Or reload configuration
pkill -SIGUSR2 waybar
```

### 2. Permission Denied Errors

#### Symptoms

- "Permission denied" when clicking module
- Scripts fail to execute
- Terminal shows permission errors

#### Solutions

**Fix Script Permissions**

```bash
chmod +x ~/.config/waybar/scripts/arch_updates*.py
chmod +x ~/.config/waybar/scripts/update_terminal.sh
```

**Check File Ownership**

```bash
# Ensure files are owned by user
chown -R $USER:$USER ~/.config/waybar/scripts/
```

**Verify Sudo Configuration**

```bash
# Test sudo access
sudo -v

# If sudo requires password every time, consider adding to sudoers
# (Advanced users only)
```

### 3. GUI Features Not Working

#### Symptoms

- Right-click doesn't show GUI menu
- "GUI not available" messages
- FreeSimpleGUI import errors

#### Solutions

**Install GUI Dependencies**

```bash
# Option 1: System-wide installation
pip install FreeSimpleGUI

# Option 2: User installation
pip install --user FreeSimpleGUI

# Option 3: Virtual environment
python -m venv ~/.local/share/waybar-gui
source ~/.local/share/waybar-gui/bin/activate
pip install FreeSimpleGUI
```

**Test GUI Availability**

```bash
# Check if GUI is working
python3 -c "import FreeSimpleGUI; print('GUI Available')"

# If import fails, check Python installation
python3 --version
which python3
```

**Alternative Solutions**

```bash
# Use terminal-only mode
~/.config/waybar/scripts/arch_updates_simple.py --update

# Check X11/Wayland compatibility
echo $XDG_SESSION_TYPE
```

### 4. Package Manager Issues

#### Symptoms

- "No updates found" when updates exist
- Package manager commands fail
- AUR helpers not working

#### Solutions

**Install Missing Package Managers**

```bash
# Install checkupdates
sudo pacman -S pacman-contrib

# Install yay
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Or use the setup script
~/.config/waybar/scripts/../scripts/package-manager-setup.sh
```

**Test Package Managers Manually**

```bash
# Test checkupdates
checkupdates

# Test yay
yay -Qum

# Test paru
paru -Qua
```

**Check Package Manager Configuration**

```bash
# Verify package manager priority in config
cat ~/.config/waybar/scripts/update_config.json | grep -A5 "package_managers"
```

### 5. Terminal Issues

#### Symptoms

- Terminal doesn't open on click
- Wrong terminal application opens
- Terminal shows garbled colors

#### Solutions

**Configure Terminal**

```bash
# Check which terminal is installed
which kitty alacritty wezterm foot

# Test terminal manually
kitty ~/.config/waybar/scripts/update_terminal.sh --interactive
```

**Fix Color Issues**

```bash
# Set environment variables
export TERM=xterm-256color
export COLORTERM=truecolor

# For kitty specifically
export KITTY_DISABLE_WAYLAND=1
```

**Update Terminal Configuration**
Edit `~/.config/waybar/scripts/update_config.json`:

```json
{
  "terminal_settings": {
    "default_terminal": "your-preferred-terminal",
    "terminal_args": ["--your", "--args", "-e"]
  }
}
```

### 6. Update Checking Problems

#### Symptoms

- Module always shows "0 updates"
- Module shows error state
- Updates not detected properly

#### Solutions

**Clear Cache**

```bash
# Remove cache file to force refresh
rm ~/.config/waybar/scripts/.update_cache.json

# Force immediate check
~/.config/waybar/scripts/arch_updates_simple.py --check
```

**Test Update Detection**

```bash
# Manual update check
checkupdates
yay -Qum

# Test script directly
python3 ~/.config/waybar/scripts/arch_updates_simple.py --check
```

**Check Network Connectivity**

```bash
# Test internet connection
ping -c 3 archlinux.org

# Update package databases
sudo pacman -Sy
```

### 7. JSON Output Issues

#### Symptoms

- Module shows raw JSON text
- Formatting problems in Waybar
- Tooltip not working

#### Solutions

**Verify JSON Output**

```bash
# Test JSON output format
~/.config/waybar/scripts/arch_updates_simple.py --check | python3 -m json.tool
```

**Check Waybar Module Configuration**
Ensure these settings in `config.jsonc`:

```jsonc
{
  "custom/updates": {
    "return-type": "json",
    "escape": true,
    "tooltip": true
  }
}
```

**Debug Output**

```bash
# Run script with debug info
python3 -c "
import sys
sys.path.append('/home/$USER/.config/waybar/scripts')
from arch_updates_simple import ArchUpdateChecker
checker = ArchUpdateChecker()
print(checker.get_waybar_output())
"
```

### 8. Performance Issues

#### Symptoms

- Waybar freezes when checking updates
- High CPU usage
- Slow response times

#### Solutions

**Adjust Check Interval**
Edit `update_config.json`:

```json
{
  "update_settings": {
    "check_interval": 1800
  }
}
```

**Monitor Resource Usage**

```bash
# Check script resource usage
top -p $(pgrep -f arch_updates)

# Monitor cache file size
ls -lh ~/.config/waybar/scripts/.update_cache.json
```

**Optimize Configuration**

```bash
# Use simple script only
# In waybar config, change exec to use arch_updates_simple.py
# Remove unnecessary package managers from config
```

## Advanced Troubleshooting

### Debug Mode

Enable detailed logging:

```bash
# Run with debug output
python3 ~/.config/waybar/scripts/arch_updates_simple.py --check 2>&1 | tee debug.log

# Check Waybar logs
journalctl --user -u waybar -f
```

### System Information Collection

Gather system info for support:

```bash
# Create debug info file
cat > debug_info.txt << EOF
System Information:
$(uname -a)

Python Version:
$(python3 --version)

Waybar Version:
$(waybar --version)

Package Managers:
$(which pacman checkupdates yay paru)

Script Permissions:
$(ls -la ~/.config/waybar/scripts/arch_updates*.py)

Config File:
$(cat ~/.config/waybar/scripts/update_config.json)

Recent Errors:
$(journalctl --user -u waybar --since "1 hour ago" | tail -20)
EOF
```

### Configuration Validation

Validate your configuration:

```bash
# Check JSON syntax
python3 -c "
import json
with open('/home/$USER/.config/waybar/scripts/update_config.json', 'r') as f:
    config = json.load(f)
    print('Configuration is valid')
    print(f'Check interval: {config[\"update_settings\"][\"check_interval\"]}')
    print(f'Package managers: {config[\"update_settings\"][\"package_managers\"]}')
"
```

### Network Diagnostics

Check network-related issues:

```bash
# Test package repository access
curl -I https://archlinux.org/

# Check mirror status
sudo pacman -Sy

# Test AUR access
curl -I https://aur.archlinux.org/
```

### Clean Reinstallation

If all else fails, perform a clean reinstall:

```bash
# Backup current configuration
cp ~/.config/waybar/scripts/update_config.json ~/update_config_backup.json

# Remove old files
rm ~/.config/waybar/scripts/arch_updates*.py
rm ~/.config/waybar/scripts/update_terminal.sh
rm ~/.config/waybar/scripts/.update_cache.json

# Reinstall from repository
cd updates-module-fredon
./install.sh

# Restore custom configuration
cp ~/update_config_backup.json ~/.config/waybar/scripts/update_config.json
```

## Error Codes and Messages

### Common Error Messages

| Error Message                     | Cause                        | Solution                        |
| --------------------------------- | ---------------------------- | ------------------------------- |
| "Permission denied"               | Script not executable        | `chmod +x script.py`            |
| "No module named 'FreeSimpleGUI'" | GUI dependency missing       | `pip install FreeSimpleGUI`     |
| "checkupdates: command not found" | pacman-contrib not installed | `sudo pacman -S pacman-contrib` |
| "Invalid JSON in config file"     | Syntax error in config       | Check JSON syntax               |
| "GUI not available"               | FreeSimpleGUI not installed  | Install GUI dependencies        |

### Exit Codes

- **0**: Success
- **1**: General error
- **2**: Configuration error
- **3**: Permission error
- **126**: Script not executable
- **127**: Command not found

## Getting Help

### Before Seeking Help

1. Check this troubleshooting guide
2. Verify system requirements
3. Test with minimal configuration
4. Collect debug information
5. Search existing issues on GitHub

### Support Channels

1. **GitHub Issues**: Report bugs and feature requests
2. **Documentation**: Review all documentation files
3. **Community Forums**: Arch Linux forums and Reddit

### Reporting Issues

When reporting issues, include:

1. System information (OS, desktop environment, Waybar version)
2. Complete error messages
3. Configuration files
4. Steps to reproduce
5. Debug output

---

**Et in tenebris codicem inveni lucem**
_"In the darkness, I found the light of code"_

---

© 2025 Fredon - FredonBytes
