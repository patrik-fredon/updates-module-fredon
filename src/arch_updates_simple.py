#!/usr/bin/env python3
"""
Simplified Arch Linux Update Checker for Waybar
Core functionality without GUI dependencies
"""

import json
import subprocess
import sys
import os
import time
from pathlib import Path
from typing import Dict, List, Tuple
import argparse


class ArchUpdateChecker:
    def __init__(self, config_path: str = None):
        self.script_dir = Path(__file__).parent.resolve()
        self.config_path = self._determine_config_path(config_path)
        self.cache_file = self.script_dir / ".update_cache.json"
        self.config = self.load_config()
        self.last_check = 0
        self.update_count = {"pacman": 0, "yay": 0, "paru": 0, "total": 0}

    def _determine_config_path(self, config_path: str = None) -> Path:
        """Determine config file path with fallback options"""
        if config_path:
            return Path(config_path).resolve()
        
        # Check environment variable first
        env_config = os.getenv('WAYBAR_UPDATE_CONFIG')
        if env_config:
            env_path = Path(env_config).resolve()
            if env_path.exists():
                return env_path
        
        # Default to script directory
        return self.script_dir / "update_config.json"

    def load_config(self) -> Dict:
        """Load configuration from JSON file with fallback to defaults"""
        try:
            if self.config_path.exists():
                with open(self.config_path, "r") as f:
                    return json.load(f)
            else:
                print(f"Config file not found at {self.config_path}, using defaults", file=sys.stderr)
                return self._get_default_config()
        except json.JSONDecodeError as e:
            print(f"Invalid JSON in config file {self.config_path}: {e}", file=sys.stderr)
            print("Using default configuration", file=sys.stderr)
            return self._get_default_config()
        except (OSError, IOError) as e:
            print(f"Error reading config file {self.config_path}: {e}", file=sys.stderr)
            print("Using default configuration", file=sys.stderr)
            return self._get_default_config()

    def _get_default_config(self) -> Dict:
        """Return default configuration"""
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
            }
        }

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
        except (json.JSONDecodeError, FileNotFoundError, OSError, IOError) as e:
            print(f"Warning: Could not load cache file {self.cache_file}: {e}", file=sys.stderr)
        return self.update_count

    def cache_updates(self):
        """Cache update counts with timestamp"""
        cache_data = {"counts": self.update_count, "timestamp": time.time()}
        try:
            # Ensure parent directory exists
            self.cache_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.cache_file, "w") as f:
                json.dump(cache_data, f)
        except (OSError, IOError) as e:
            print(f"Warning: Could not write cache file {self.cache_file}: {e}", file=sys.stderr)

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

    def execute_terminal_update(self):
        """Execute interactive terminal update"""
        # Use the improved terminal script
        terminal_script = self.script_dir / "update_terminal.sh"

        if not terminal_script.exists():
            print(f"Terminal update script not found at {terminal_script}", file=sys.stderr)
            print("Please ensure update_terminal.sh exists in the script directory", file=sys.stderr)
            return

        if not os.access(terminal_script, os.X_OK):
            print(f"Terminal update script is not executable: {terminal_script}", file=sys.stderr)
            print(f"Run: chmod +x {terminal_script}", file=sys.stderr)
            return

        try:
            subprocess.run([str(terminal_script)], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Terminal update script failed with exit code {e.returncode}", file=sys.stderr)
        except subprocess.SubprocessError as e:
            print(f"Failed to launch terminal update: {e}", file=sys.stderr)
        except FileNotFoundError:
            print(f"Terminal update script not found or not executable: {terminal_script}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Arch Linux Update Checker for Waybar")
    parser.add_argument("--config", help="Path to config file (overrides environment variable and defaults)")
    parser.add_argument(
        "--check", action="store_true", help="Check for updates and output JSON"
    )
    parser.add_argument("--update", action="store_true", help="Run interactive update")

    args = parser.parse_args()

    try:
        checker = ArchUpdateChecker(config_path=args.config)

        if args.update:
            checker.execute_terminal_update()
        else:
            # Default: output for Waybar
            print(checker.get_waybar_output())
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
