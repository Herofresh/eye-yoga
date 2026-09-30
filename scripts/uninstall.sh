#!/usr/bin/env bash
# Stops Eye Yoga and removes the app and LaunchAgent. Settings and XP stay in
# UserDefaults; remove them with: defaults delete at.herofresh.eyeyoga
set -euo pipefail

label=at.herofresh.eyeyoga
launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$label.plist"
rm -rf "$HOME/Applications/EyeYoga.app"
echo "Eye Yoga uninstalled."
