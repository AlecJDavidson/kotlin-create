#!/bin/bash

# Ensure root privileges
if [ "$UID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Define installation directory and bin path
INSTALL_DIR="/usr/local/bin"

# Remove the kotlin-create binary
rm -f "$INSTALL_DIR/kotlin-create"
echo "Removed kotlin-create from $INSTALL_DIR."

# Check if the bin directory is empty after removal
if [ "$(ls -A "$INSTALL_DIR" | wc -l)" -eq 0 ]; then
    rm -r "$INSTALL_DIR"
    echo "Removed empty directory: $INSTALL_DIR"
else
    echo "Directory $INSTALL_DIR not removed as it contains other files."
fi

# Inform completion
echo ""
echo "Uninstallation of kotlin-create Complete!"
