#!/usr/bin/env bash
# Installs to ~/Applications and starts Eye Yoga at every login via a LaunchAgent.
set -euo pipefail

cd "$(dirname "$0")/.."
label=at.herofresh.eyeyoga
agent="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"

scripts/build-app.sh

mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
launchctl bootout "$domain/$label" 2>/dev/null || true
# bootout returns before the job is gone; bootstrapping too early fails with error 5.
for _ in {1..50}; do
    launchctl print "$domain/$label" >/dev/null 2>&1 || break
    sleep 0.1
done
rm -rf "$HOME/Applications/EyeYoga.app"
cp -R build/EyeYoga.app "$HOME/Applications/"

# launchd does not expand ~ or $HOME inside plists.
sed "s|__HOME__|$HOME|g" launchd/$label.plist > "$agent"
launchctl bootstrap "$domain" "$agent"

echo "Eye Yoga installed and running. Look for the eye in your menu bar."
