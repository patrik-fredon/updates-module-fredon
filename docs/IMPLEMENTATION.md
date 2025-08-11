# Implementation Guide

## Updates Module Fredon - Configuration and Customization

**Patrik Fredon - FredonBytes - Where code meets innovation**

This guide covers advanced configuration, customization, and implementation details for the Updates Module Fredon.

## Module Architecture

### Core Components

1. **arch_updates_simple.py**: Lightweight core functionality

   - No GUI dependencies
   - JSON output for Waybar
   - Basic update checking
   - Terminal integration

2. **arch_updates.py**: Full-featured version

   - GUI menu support (FreeSimpleGUI)
   - Advanced error handling
   - System maintenance tools
   - Interactive popup menus

3. **update_config.json**: Configuration file

   - Update intervals and settings
   - Icon and color customization
   - Menu button definitions
   - Terminal and GUI settings

4. **update_terminal.sh**: Terminal interface
   - Interactive update menu
   - Colored output
   - Progress tracking
   - System maintenance options

## Configuration

### Basic Configuration

The main configuration file is `~/.config/waybar/scripts/update_config.json`:

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
    },
    "colors": {
      "no_updates": "#588157",
      "updates_available": "#f9c74f",
      "updating": "#277da1",
      "error": "#e63946"
    }
  }
}
```

### Waybar Integration

#### Module Definition

Add to your `~/.config/waybar/config.jsonc`:

```jsonc
{
  "modules-right": ["custom/updates"],

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

#### Signal-Based Updates

Force immediate refresh:

```bash
pkill -SIGRTMIN+8 waybar
```

### Styling and Theming

#### CSS Classes

The module uses these CSS classes in `~/.config/waybar/style.css`:

```css
#custom-updates.no-updates {
  color: #588157;
  background: rgba(88, 129, 87, 0.1);
  border: 1px solid rgba(88, 129, 87, 0.3);
}

#custom-updates.updates-available {
  color: #f9c74f;
  background: rgba(249, 199, 79, 0.1);
  border: 1px solid rgba(249, 199, 79, 0.3);
  animation: pulse 2s infinite;
}

#custom-updates.updating {
  color: #277da1;
  background: rgba(39, 125, 161, 0.1);
  border: 1px solid rgba(39, 125, 161, 0.3);
  animation: rotate 1s linear infinite;
}

#custom-updates.error {
  color: #e63946;
  background: rgba(230, 57, 70, 0.1);
  border: 1px solid rgba(230, 57, 70, 0.3);
  animation: shake 0.5s ease-in-out infinite alternate;
}
```

#### Animations

- **Pulse**: Updates available
- **Rotate**: Currently updating
- **Shake**: Error state
- **Glow**: Subtle highlight effect

## Advanced Configuration

### Package Manager Priority

Configure which package managers to use and their priority:

```json
{
  "update_settings": {
    "package_managers": ["pacman", "yay", "paru"]
  }
}
```

The module will use the first available manager in the list.

### Custom Icons and Colors

Customize the appearance:

```json
{
  "update_settings": {
    "icons": {
      "no_updates": "🟢",
      "updates_available": "🟡",
      "updating": "🔵",
      "error": "🔴"
    },
    "colors": {
      "no_updates": "#00ff00",
      "updates_available": "#ffff00",
      "updating": "#0000ff",
      "error": "#ff0000"
    }
  }
}
```

### Menu Customization

Add custom menu buttons:

```json
{
  "menu_buttons": [
    {
      "key": "custom_command",
      "name": "Custom Task",
      "description": "Run custom maintenance task",
      "command": "your-custom-command",
      "icon": "⚙️",
      "requires_confirmation": true,
      "terminal": true
    }
  ]
}
```

### Terminal Configuration

Configure terminal behavior:

```json
{
  "terminal_settings": {
    "default_terminal": "kitty",
    "terminal_args": ["--config", "NONE", "-o", "background_opacity=0.9", "-e"],
    "color_scheme": {
      "success": "\\033[92m",
      "warning": "\\033[93m",
      "error": "\\033[91m",
      "info": "\\033[94m",
      "reset": "\\033[0m",
      "bold": "\\033[1m"
    }
  }
}
```

### GUI Settings

Configure popup menu appearance:

```json
{
  "gui_settings": {
    "popup_width": 350,
    "popup_height": 400,
    "transparency": 0.9,
    "blur_background": true,
    "button_padding": 10,
    "font_size": 12,
    "theme": "dark"
  }
}
```

## Integration Patterns

### System Hooks

Auto-refresh after package operations:

```bash
# /etc/pacman.d/hooks/waybar-update.hook
[Trigger]
Operation = Install
Operation = Remove
Operation = Upgrade
Type = Package
Target = *

[Action]
When = PostTransaction
Exec = /usr/bin/pkill -SIGRTMIN+8 waybar
```

### Systemd Timer (Optional)

Create periodic update checks:

```ini
# ~/.config/systemd/user/waybar-updates.service
[Unit]
Description=Waybar Updates Check

[Service]
Type=oneshot
ExecStart=/home/%i/.config/waybar/scripts/arch_updates_simple.py --check
```

```ini
# ~/.config/systemd/user/waybar-updates.timer
[Unit]
Description=Run Waybar Updates Check

[Timer]
OnCalendar=*:0/10
Persistent=true

[Install]
WantedBy=timers.target
```

Enable the timer:

```bash
systemctl --user enable --now waybar-updates.timer
```

### Script Integration

#### Command Line Usage

```bash
# Check for updates
arch_updates_simple.py --check

# Interactive update
arch_updates_simple.py --update

# Show GUI menu
arch_updates.py --menu

# Use custom config
arch_updates.py --config /path/to/config.json
```

#### JSON Output Format

The module outputs JSON for Waybar:

```json
{
  "text": "📦 5",
  "tooltip": "Updates available:\nPacman: 3\nAUR: 2\nTotal: 5",
  "class": "updates-available",
  "percentage": 50
}
```

## Customization Examples

### Minimal Configuration

For a lightweight setup:

```json
{
  "update_settings": {
    "check_interval": 1800,
    "package_managers": ["pacman"],
    "icons": {
      "no_updates": "",
      "updates_available": "",
      "updating": "",
      "error": ""
    }
  }
}
```

### Gaming-Focused Setup

Disable automatic updates during gaming:

```json
{
  "update_settings": {
    "check_interval": 3600,
    "gaming_mode": true,
    "gaming_processes": ["steam", "lutris", "wine"]
  }
}
```

### Enterprise Configuration

For managed environments:

```json
{
  "update_settings": {
    "check_interval": 300,
    "package_managers": ["pacman"],
    "disable_aur": true,
    "logging": {
      "enabled": true,
      "level": "info",
      "file": "/var/log/waybar-updates.log"
    }
  }
}
```

## Performance Optimization

### Cache Management

The module uses intelligent caching:

- Cache file: `~/.config/waybar/scripts/.update_cache.json`
- Respects `check_interval` setting
- Automatic cache invalidation
- Manual cache clear: `rm ~/.config/waybar/scripts/.update_cache.json`

### Resource Usage

- **Memory**: ~10-15MB during execution
- **CPU**: Minimal impact with proper caching
- **Network**: Only during package manager queries
- **Disk**: <1MB for cache and logs

## Development and Extension

### Creating Custom Scripts

Extend functionality by creating custom update scripts:

```python
#!/usr/bin/env python3
from pathlib import Path
import sys
sys.path.insert(0, str(Path.home() / '.config/waybar/scripts'))
from arch_updates_simple import ArchUpdateChecker

# Custom implementation
checker = ArchUpdateChecker()
# Your code here
```

### API Integration

The module can be extended to work with other package managers or notification systems.

## Best Practices

1. **Regular Backups**: Backup your configuration before changes
2. **Testing**: Test changes in a development environment
3. **Monitoring**: Monitor system resources and performance
4. **Security**: Keep scripts updated and review custom commands
5. **Documentation**: Document any custom modifications

## Migration from Other Tools

### From Manual Scripts

Replace manual update checking scripts with the module's standardized approach.

### From Other Waybar Modules

The module is designed to be compatible with most Waybar setups and can replace similar update checking modules.

---

**Et in tenebris codicem inveni lucem**
_"In the darkness, I found the light of code"_

---

© 2025 Fredon - FredonBytes
