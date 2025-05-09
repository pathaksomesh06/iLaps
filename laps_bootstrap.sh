#!/bin/bash

set -e
set -x

# Variables (replace with your actual URLs and filenames)
CERT_URL="https://irlintunediagnosticsa.blob.core.windows.net/ilaps/laps_app_cert.pem?sp=r&st=2025-05-08T12:21:17Z&se=2026-05-08T20:21:17Z&spr=https&sv=2024-11-04&sr=b&sig=itXjfGfPfNje2ukSjHhMxy%2FIfOBe4Lh5Wyc%2FD7kG7NU%3D"
KEY_URL="https://irlintunediagnosticsa.blob.core.windows.net/ilaps/laps_app_key.pem?sp=r&st=2025-05-08T12:21:59Z&se=2026-05-08T20:21:59Z&spr=https&sv=2024-11-04&sr=b&sig=cxw6zbLWFFipn3ks8aCa3KbavpOlJmL1uW%2B4CP03MSw%3D"
SCRIPT_URL="https://irlintunediagnosticsa.blob.core.windows.net/ilaps/laps_rotate.sh?sp=r&st=2025-05-08T12:22:30Z&se=2026-05-08T20:22:30Z&spr=https&sv=2024-11-04&sr=b&sig=417j6qCICrc44U18cZR4TOlXL29fu8fSZkBGwoaW%2BEk%3D"
PLIST_URL="https://irlintunediagnosticsa.blob.core.windows.net/ilaps/com.maverick.laps.plist?sp=r&st=2025-05-08T12:23:24Z&se=2026-05-08T20:23:24Z&spr=https&sv=2024-11-04&sr=b&sig=EU36F6MaOEjlz09dgIFSB5%2Fv6oIwAwwOAtP7xnAWxBA%3D"

LAPS_DIR="/usr/local/laps"
PLIST_PATH="/Library/LaunchDaemons/com.maverick.laps.plist"

# Create directory
sudo mkdir -p "$LAPS_DIR"
sudo chown root:wheel "$LAPS_DIR"
sudo chmod 700 "$LAPS_DIR"

# Download cert and key
curl -fsSL "$CERT_URL" -o "$LAPS_DIR/laps_app_cert.pem"
curl -fsSL "$KEY_URL" -o "$LAPS_DIR/laps_app_key.pem"
sudo chown root:wheel "$LAPS_DIR/laps_app_cert.pem" "$LAPS_DIR/laps_app_key.pem"
sudo chmod 600 "$LAPS_DIR/laps_app_cert.pem" "$LAPS_DIR/laps_app_key.pem"

# Download LAPS script
curl -fsSL "$SCRIPT_URL" -o "$LAPS_DIR/laps_rotate.sh"
sudo chown root:wheel "$LAPS_DIR/laps_rotate.sh"
sudo chmod 700 "$LAPS_DIR/laps_rotate.sh"

# Download and install LaunchDaemon plist
curl -fsSL "$PLIST_URL" -o "$PLIST_PATH"
sudo chown root:wheel "$PLIST_PATH"
sudo chmod 644 "$PLIST_PATH"

# Load the LaunchDaemon (idempotent)
if sudo launchctl list | grep -q maverick; then
    sudo launchctl unload "$PLIST_PATH"
fi
sudo launchctl load "$PLIST_PATH"

echo "LAPS deployment complete."