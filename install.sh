#!/bin/bash

# Ensure root privileges
if [ "$UID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Define variables (change as needed)
SOURCE_URL="https://raw.githubusercontent.com/AlecJDavidson/kotlin-create/refs/heads/main/kotlin-create.sh"
INSTALL_DIR="/usr/local/bin"
BIN_NAME="kotlin-create"

# Fetch the main script from a URL or local path
if [ -z "$SOURCE_URL" ]; then
    # Use local copy if no URL provided
    SCRIPT_PATH="$(dirname $0)/kotlin-create"
else
    # Download using curl (or wget if preferred)
    wget "$SOURCE_URL" -O "/tmp/kotlin-create" ||
    curl -Ls "$SOURCE_URL" -o "/tmp/kotlin-create"
fi

# Check if the script exists
if [ ! -f "/tmp/kotlin-create" ]; then
    echo "Failed to download or locate kotlin-create. Please check your SOURCE_URL."
    exit 1
fi

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Move the script to the bin directory
cp "/tmp/kotlin-create" "$INSTALL_DIR/$BIN_NAME"
rm -f "/tmp/kotlin-create" # Clean up temp file

# Make the script executable
chmod +x "$INSTALL_DIR/$BIN_NAME"

# Change ownership to current user
chown $(whoami):$(whoami) "$INSTALL_DIR/$BIN_NAME"

# Add to PATH if not already present
if echo $PATH | grep -q "$INSTALL_DIR"; then
    echo "kotlin-create is now installed and available in your \$PATH."
else
    echo "Adding $INSTALL_DIR to your \$PATH. Please run the following command:"
    echo "export PATH=\$PATH:\$INSTALL_DIR"
fi

# Print usage instructions
echo ""
echo "Installation Complete!"
echo ""
echo "To use kotlin-create.sh, simply run it in any directory."
echo "Example Usage:"
echo "kotlin-create -n my_project"
echo ""
