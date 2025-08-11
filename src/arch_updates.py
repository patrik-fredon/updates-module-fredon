#!/usr/bin/env python3
"""
Arch Linux Update Manager for Waybar
A comprehensive update checker and system maintenance tool for Hyprland/Waybar
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
"""

import json
import subprocess
import sys
import os
import time
import threading
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import argparse

try:
    import FreeSimpleGUI as sg

    GUI_AVAILABLE = True
except ImportError:
    GUI_AVAILABLE = False

    # Create a minimal sg-like interface for non-GUI operations
    class sg:
        @staticmethod
        def popup(*args, **kwargs):
            print(" ".join(str(arg) for arg in args))
            return True

        @staticmethod
        def popup_scrolled(*args, **kwargs):
            print(" ".join(str(arg) for arg in args))
            return True


class ArchUpdateManager:
    def __init__(self, config_path: str = None):
        self.script_dir = Path(__file__).parent
        self.config_path = config_path or self.script_dir / "update_config.json"
        self.cache_file = self.script_dir / ".update_cache.json"
        self.config = self.load_config()
        self.last_check = 0
        self.update_count = {"pacman": 0, "yay": 0, "paru": 0, "total": 0}
        self.current_status = "checking"

    def load_config(self) -> Dict:
        """Load configuration from JSON file"""
        try:
            with open(self.config_path, "r") as f:
                return json.load(f)
        except FileNotFoundError:
            # Return default config if file not found
            return {
                "update_settings": {
                    "check_interval": 600,
                    "package_managers": ["pacman", "yay", "paru"],
                    "icons": {
                        "no_updates": "✅",
                        "updates_available": "📦",
                        "updating": "🔄",
                        "error": "⚠️",
                    },
                    "colors": {
                        "no_updates": "#588157",
                        "updates_available": "#f9c74f",
                        "updating": "#277da1",
                        "error": "#e63946",
                    },
                },
                "gui_settings": {
                    "transparency": 0.9,
                    "popup_width": 350,
                    "popup_height": 400,
                    "button_padding": 10,
                },
                "terminal_settings": {
                    "default_terminal": "kitty",
                    "terminal_args": ["-e"],
                    "color_scheme": {
                        "info": "\\033[36m",
                        "success": "\\033[32m",
                        "error": "\\033[31m",
                        "bold": "\\033[1m",
                        "reset": "\\033[0m",
                    },
                },
                "menu_buttons": [
                    {
                        "key": "full_update",
                        "name": "System Update",
                        "icon": "🔄",
                        "description": "Update all packages (pacman + AUR)",
                        "command": "sudo pacman -Syu && yay -Syu",
                        "requires_confirmation": True,
                        "terminal": True,
                    },
                    {
                        "key": "cache_clean",
                        "name": "Clean Cache",
                        "icon": "🧹",
                        "description": "Clean package cache",
                        "command": "sudo pacman -Scc && yay -Scc",
                        "requires_confirmation": True,
                        "terminal": True,
                    },
                ],
            }
        except json.JSONDecodeError as e:
            print(f"Invalid JSON in config file: {e}", file=sys.stderr)
            sys.exit(1)

    def get_package_manager_priority(self) -> str:
        """Determine which package manager to use based on availability"""
        managers = self.config["update_settings"]["package_managers"]
        for manager in managers:
            if subprocess.run(["which", manager], capture_output=True).returncode == 0:
                return manager
        return "pacman"  # fallback

    def check_pacman_updates(self) -> Tuple[int, List[str]]:
        """Check for pacman updates"""
        try:
            result = subprocess.run(
                ["checkupdates"], capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                updates = result.stdout.strip().split("\n")
                return len([u for u in updates if u.strip()]), updates
            return 0, []
        except (
            subprocess.TimeoutExpired,
            subprocess.SubprocessError,
            FileNotFoundError,
        ):
            return 0, []

    def check_aur_updates(self, manager: str = "yay") -> Tuple[int, List[str]]:
        """Check for AUR updates using yay or paru"""
        if manager not in ["yay", "paru"]:
            return 0, []

        try:
            cmd = [manager, "-Qum"] if manager == "yay" else [manager, "-Qua"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0:
                updates = result.stdout.strip().split("\n")
                return len([u for u in updates if u.strip()]), updates
            return 0, []
        except (
            subprocess.TimeoutExpired,
            subprocess.SubprocessError,
            FileNotFoundError,
        ):
            return 0, []

    def check_all_updates(self) -> Dict[str, int]:
        """Check updates from all package managers"""
        current_time = time.time()

        # Use cache if within interval
        if (
            current_time - self.last_check
            < self.config["update_settings"]["check_interval"]
        ):
            return self.load_cached_updates()

        print("Checking for updates...", file=sys.stderr)

        # Check pacman updates
        pacman_count, pacman_list = self.check_pacman_updates()

        # Check AUR updates
        yay_count, yay_list = self.check_aur_updates("yay")
        paru_count, paru_list = self.check_aur_updates("paru")

        # Update counts
        self.update_count = {
            "pacman": pacman_count,
            "yay": yay_count,
            "paru": paru_count,
            "total": pacman_count
            + max(yay_count, paru_count),  # Avoid double counting AUR
        }

        # Cache results
        self.cache_updates()
        self.last_check = current_time

        return self.update_count

    def load_cached_updates(self) -> Dict[str, int]:
        """Load cached update counts"""
        try:
            if self.cache_file.exists():
                with open(self.cache_file, "r") as f:
                    cached = json.load(f)
                    self.update_count = cached.get("counts", self.update_count)
                    self.last_check = cached.get("timestamp", 0)
        except (json.JSONDecodeError, FileNotFoundError):
            pass
        return self.update_count

    def cache_updates(self):
        """Cache update counts with timestamp"""
        cache_data = {"counts": self.update_count, "timestamp": time.time()}
        try:
            with open(self.cache_file, "w") as f:
                json.dump(cache_data, f)
        except IOError:
            pass

    def get_waybar_output(self) -> str:
        """Generate JSON output for Waybar"""
        counts = self.check_all_updates()
        total = counts["total"]
        icons = self.config["update_settings"]["icons"]
        colors = self.config["update_settings"]["colors"]

        if total == 0:
            icon = icons["no_updates"]
            css_class = "no-updates"
            color = colors["no_updates"]
            tooltip = "System is up to date"
        else:
            icon = icons["updates_available"]
            css_class = "updates-available"
            color = colors["updates_available"]
            tooltip = f"Updates available:\nPacman: {counts['pacman']}\nAUR: {max(counts['yay'], counts['paru'])}\nTotal: {total}"

        output = {
            "text": f"{icon} {total}" if total > 0 else icon,
            "tooltip": tooltip,
            "class": css_class,
            "percentage": min(100, total * 10) if total > 0 else 0,
        }

        return json.dumps(output)

    def check_journal_errors(self) -> List[str]:
        """Check journalctl for errors"""
        try:
            result = subprocess.run(
                ["journalctl", "-p", "3", "-n", "20", "--no-pager"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip().split("\n")
            return []
        except (subprocess.TimeoutExpired, subprocess.SubprocessError):
            return []

    def execute_command(
        self, command: str, terminal: bool = True, requires_confirmation: bool = False
    ) -> bool:
        """Execute a system command"""
        colors = self.config["terminal_settings"]["color_scheme"]

        if requires_confirmation:
            if GUI_AVAILABLE:
                layout = [
                    [sg.Text(f"Execute command:", font=("Arial", 12, "bold"))],
                    [sg.Text(command, font=("Courier", 10), text_color="yellow")],
                    [sg.Text("Are you sure you want to continue?")],
                    [
                        sg.Button("Yes", button_color=("white", "green")),
                        sg.Button("No", button_color=("white", "red")),
                    ],
                ]

                window = sg.Window(
                    "Confirm Command",
                    layout,
                    modal=True,
                    alpha_channel=0.9,
                    no_titlebar=False,
                    finalize=True,
                )

                event, values = window.read()
                window.close()

                if event != "Yes":
                    return False
            else:
                # Fallback to terminal confirmation
                print(f"\nExecute command: {command}")
                response = input("Are you sure you want to continue? (y/N): ")
                if response.lower() not in ["y", "yes"]:
                    return False

        if terminal:
            terminal_cmd = self.config["terminal_settings"]["default_terminal"]
            terminal_args = self.config["terminal_settings"]["terminal_args"]

            # Create a script to run the command with colored output
            script_content = f"""#!/bin/bash
echo -e "{colors['bold']}{colors['info']}Executing: {command}{colors['reset']}"
echo -e "{colors['info']}Press Enter to continue...{colors['reset']}"
read
echo -e "{colors['bold']}Starting command execution...{colors['reset']}"
{command}
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo -e "{colors['success']}{colors['bold']}Command completed successfully!{colors['reset']}"
else
    echo -e "{colors['error']}{colors['bold']}Command failed with exit code: $exit_code{colors['reset']}"
fi
echo -e "{colors['info']}Press Enter to close...{colors['reset']}"
read
"""

            # Write temporary script
            temp_script = self.script_dir / ".temp_command.sh"
            with open(temp_script, "w") as f:
                f.write(script_content)
            os.chmod(temp_script, 0o755)

            try:
                # Execute in terminal
                full_cmd = [terminal_cmd] + terminal_args + [str(temp_script)]
                subprocess.run(full_cmd, check=False)
                return True
            finally:
                # Clean up
                if temp_script.exists():
                    temp_script.unlink()
        else:
            # Execute directly
            try:
                result = subprocess.run(command, shell=True, check=True)
                return result.returncode == 0
            except subprocess.CalledProcessError:
                return False

    def show_popup_menu(self):
        """Show the translucent popup menu with system maintenance options"""
        if not GUI_AVAILABLE:
            print("GUI not available. Use --update for terminal interface.")
            return

        sg.theme("DarkGrey9")

        gui_settings = self.config["gui_settings"]
        buttons = self.config["menu_buttons"]

        # Create layout with buttons
        layout = []
        layout.append(
            [
                sg.Text(
                    "System Maintenance",
                    font=("Arial", 14, "bold"),
                    justification="center",
                    expand_x=True,
                )
            ]
        )
        layout.append([sg.HSeparator()])

        # Add update info
        counts = self.check_all_updates()
        total = counts["total"]
        if total > 0:
            update_text = f"📦 {total} updates available"
            layout.append(
                [
                    sg.Text(
                        update_text,
                        font=("Arial", 12),
                        text_color="orange",
                        justification="center",
                    )
                ]
            )
        else:
            layout.append(
                [
                    sg.Text(
                        "✅ System up to date",
                        font=("Arial", 12),
                        text_color="green",
                        justification="center",
                    )
                ]
            )

        layout.append([sg.HSeparator()])

        # Add menu buttons
        for button in buttons:
            button_layout = [
                sg.Button(
                    f"{button['icon']} {button['name']}",
                    key=button["key"],
                    size=(25, 1),
                    font=("Arial", 10),
                    tooltip=button["description"],
                    button_color=("white", "#2d2d3a"),
                    border_width=1,
                )
            ]
            layout.append(button_layout)

        layout.append([sg.HSeparator()])
        layout.append([sg.Button("Close", key="close", button_color=("white", "red"))])

        # Create window with transparency and no title bar for blur effect
        window = sg.Window(
            "System Updates",
            layout,
            no_titlebar=True,
            alpha_channel=gui_settings["transparency"],
            grab_anywhere=True,
            keep_on_top=True,
            size=(gui_settings["popup_width"], gui_settings["popup_height"]),
            element_padding=(gui_settings["button_padding"], 5),
            finalize=True,
        )

        # Event loop
        while True:
            event, values = window.read()

            if event in (sg.WINDOW_CLOSED, "close"):
                break

            # Find the button configuration
            button_config = None
            for button in buttons:
                if button["key"] == event:
                    button_config = button
                    break

            if button_config:
                window.hide()  # Hide menu during execution
                success = self.execute_command(
                    button_config["command"],
                    button_config["terminal"],
                    button_config["requires_confirmation"],
                )

                # Special handling for reboot
                if button_config["key"] == "reboot" and success:
                    break

                window.un_hide()  # Show menu again

        window.close()

    def run_interactive_update(self):
        """Run interactive system update process"""
        journal_errors = self.check_journal_errors()

        if journal_errors:
            sg.popup_scrolled(
                "System errors detected in journal:\n\n"
                + "\n".join(journal_errors[-10:]),
                title="Journal Errors",
                size=(80, 20),
            )

        # Show interactive update menu
        self.show_popup_menu()


def main():
    parser = argparse.ArgumentParser(description="Arch Linux Update Manager for Waybar")
    parser.add_argument("--config", help="Path to config file")
    parser.add_argument(
        "--check", action="store_true", help="Check for updates and output JSON"
    )
    parser.add_argument("--menu", action="store_true", help="Show interactive menu")
    parser.add_argument("--update", action="store_true", help="Run interactive update")

    args = parser.parse_args()

    manager = ArchUpdateManager(args.config)

    if args.check:
        print(manager.get_waybar_output())
    elif args.menu:
        manager.show_popup_menu()
    elif args.update:
        manager.run_interactive_update()
    else:
        # Default: output for Waybar
        print(manager.get_waybar_output())


if __name__ == "__main__":
    main()
