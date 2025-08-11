# Updates Module Fredon

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║           ███████╗██████╗ ███████╗██████╗  ██████╗ ███╗   ██╗         ║
║           ██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗████╗  ██║         ║
║           █████╗  ██████╔╝█████╗  ██║  ██║██║   ██║██╔██╗ ██║         ║
║           ██╔══╝  ██╔══██╗██╔══╝  ██║  ██║██║   ██║██║╚██╗██║         ║
║           ██║     ██║  ██║███████╗██████╔╝╚██████╔╝██║ ╚████║         ║
║           ╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═══╝         ║
║                                                                       ║
║                    D O T F I L E S   M A N A G E R                    ║
║                 “Et in tenebris codicem inveni lucem.”                ║
╚═══════════════════════════════════════════════════════════════════════╝
```

**Patrik Fredon - FredonBytes - Where code meets innovation**

A system update manager and maintenance tool designed for Waybar on Hyprland/Arch Linux systems.

## Features

- 🔄 **Real-time Update Monitoring**: Automatically checks for system and AUR updates
- 🎨 **Beautiful Waybar Integration**: Seamless integration with animated visual states
- 🖱️ **Interactive Interface**: Left-click for terminal updates, right-click for GUI menu
- 📦 **Multi Package Manager Support**: Works with pacman, yay, and paru
- ⚡ **Performance Optimized**: Smart caching system to minimize resource usage
- 🎯 **Customizable**: Fully configurable icons, colors, and update intervals
- 🛠️ **Easy Installation**: One-command setup with automated configuration

## Visual States

- 🟢 **Green**: System up to date
- 🟡 **Yellow**: Updates available (animated pulse)
- 🔵 **Blue**: Currently updating (rotating animation)
- 🔴 **Red**: Error occurred (shake animation)

## Quick Installation

```bash
git clone https://github.com/patrik-fredon/updates-module-fredon.git
cd updates-module-fredon
chmod +x install.sh
./install.sh
```

## Prerequisites

- **Arch Linux** with Waybar and Hyprland
- **Python 3.8+**
- **Package Managers**: At least `pacman`, optionally `yay` and/or `paru`
- **Terminal**: Default configured (kitty recommended)

## Manual Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/patrik-fredon/updates-module-fredon.git
   cd updates-module-fredon
   ```

2. **Copy files to Waybar config directory**:

   ```bash
   cp -r src/* ~/.config/waybar/scripts/
   cp -r config/waybar/* ~/.config/waybar/
   cp scripts/update_config.json ~/.config/waybar/scripts/
   ```

3. **Make scripts executable**:

   ```bash
   chmod +x ~/.config/waybar/scripts/arch_updates*.py
   ```

4. **Restart Waybar**:
   ```bash
   killall waybar && waybar &
   ```

## Configuration

### Update Settings

Configuration is stored in `~/.config/waybar/scripts/update_config.json`:

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
      "no_updates": "#4CAF50",
      "updates_available": "#FF9800",
      "updating": "#2196F3",
      "error": "#F44336"
    }
  }
}
```

### Waybar Integration

The module integrates with Waybar through:

- [`config.jsonc`](config/waybar/config.jsonc): Main Waybar configuration
- [`modules.json`](config/waybar/modules.json): Module definitions with click handlers
- [`style.css`](config/waybar/style.css): Visual styling with animations

## Usage

### Basic Commands

```bash
# Check for updates (JSON output for Waybar)
~/.config/waybar/scripts/arch_updates_simple.py --check

# Run interactive update
~/.config/waybar/scripts/arch_updates_simple.py --update

# Show GUI menu (requires GUI dependencies)
~/.config/waybar/scripts/arch_updates.py --menu
```

### Waybar Integration

Once configured, the module appears in Waybar with:

- **Icon**: Shows current update status
- **Counter**: Number of available updates
- **Left Click**: Opens interactive terminal update
- **Right Click**: Opens popup menu (with GUI installed)
- **Tooltip**: Detailed breakdown of update counts

## Troubleshooting

For common issues and solutions, see our [Troubleshooting Guide](docs/TROUBLESHOOTING.md).

### Quick Fixes

1. **Permission Denied**: Ensure scripts are executable

   ```bash
   chmod +x ~/.config/waybar/scripts/arch_updates*.py
   ```

2. **Module Not Appearing**: Check Waybar config syntax

   ```bash
   waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css --log-level debug
   ```

3. **Force Update Check**: Send signal to Waybar
   ```bash
   pkill -SIGRTMIN+8 waybar
   ```

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- [Implementation Guide](docs/IMPLEMENTATION.md) - Configuration and customization
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## File Structure

```
updates-module-fredon/
├── src/                         # Core functionality
│   ├── arch_updates.py          # Full-featured script with GUI
│   └── arch_updates_simple.py   # Core functionality, no dependencies
├── config/waybar/               # Waybar integration
│   ├── config.jsonc            # Main configuration
│   ├── modules.json            # Module definitions
│   └── style.css               # Styling with animations
├── scripts/                     # Supporting scripts
│   ├── update_config.json      # Module configuration
│   └── package-manager-setup.sh # Package manager installation
├── docs/                        # Documentation
└── install.sh                  # Installation script
```

## Contributing

Contributions are welcome! Feel free to submit improvements, especially for:

- Additional package manager support
- Enhanced visual effects
- Performance optimizations
- Error handling improvements

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes in each version.

---

**Et in tenebris codicem inveni lucem**
_"In the darkness, I found the light of code"_

---

© 2025 Fredon - FredonBytes
