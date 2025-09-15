#!/bin/bash

set -e

# Detect distro
detect_pkg_manager() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian) echo "apt-get" ;;
            fedora|rhel|centos) echo "dnf" ;;
            arch|manjaro|endeavouros) echo "pacman" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)

# Variables
SOURCE_URL="https://raw.githubusercontent.com/AlecJDavidson/kotlin-create/refs/heads/main/kotlin-create.sh"
INSTALL_DIR="/usr/local/bin"
BIN_NAME="kotlin-create"

SDK_DIR="$HOME/.sdk"
GRADLE_VERSION="8.5"
ANDROID_PLATFORM="platforms;android-34"
JAVA_VERSION="17"

# Helpers
add_to_path() {
    local dir="$1"
    local profile_file="$SDK_DIR/env.sh"
    mkdir -p "$(dirname "$profile_file")"
    if ! grep -q "$dir" <<< "$PATH"; then
        echo "export PATH=\$PATH:$dir" >> "$profile_file"
    fi
}

install_pkg() {
    local pkgs=("$@")
    case "$PKG_MANAGER" in
        apt-get)
            sudo apt-get update
            sudo apt-get install -y "${pkgs[@]}"
            ;;
        dnf)
            sudo dnf install -y "${pkgs[@]}"
            ;;
        pacman)
            sudo pacman -Sy --noconfirm "${pkgs[@]}"
            ;;
        *)
            echo "Unsupported package manager. Please install manually: ${pkgs[*]}"
            exit 1
            ;;
    esac
}

install_kotlin_create() {
    echo "Installing kotlin-create..."
    if [ -z "$SOURCE_URL" ]; then
        SCRIPT_PATH="$(dirname $0)/kotlin-create"
    else
        wget -q "$SOURCE_URL" -O "/tmp/kotlin-create" ||
        curl -Ls "$SOURCE_URL" -o "/tmp/kotlin-create"
    fi

    if [ ! -f "/tmp/kotlin-create" ]; then
        echo "Failed to download kotlin-create."
        exit 1
    fi

    sudo mkdir -p "$INSTALL_DIR"
    sudo cp "/tmp/kotlin-create" "$INSTALL_DIR/$BIN_NAME"
    rm -f "/tmp/kotlin-create"
    sudo chmod +x "$INSTALL_DIR/$BIN_NAME"
    sudo chown $(whoami):$(whoami) "$INSTALL_DIR/$BIN_NAME"
    echo "kotlin-create installed at $INSTALL_DIR/$BIN_NAME"
}

install_gradle() {
    echo "Installing Gradle $GRADLE_VERSION..."
    mkdir -p "$SDK_DIR"
    wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -O /tmp/gradle.zip
    unzip -q /tmp/gradle.zip -d "$SDK_DIR"
    ln -sfn "$SDK_DIR/gradle-${GRADLE_VERSION}" "$SDK_DIR/gradle"
    add_to_path "$SDK_DIR/gradle/bin"
    echo "Gradle $GRADLE_VERSION installed in $SDK_DIR/gradle"
}

install_android_sdk() {
    echo "Installing Android SDK (platform $ANDROID_PLATFORM)..."
    install_pkg unzip wget curl

    mkdir -p "$SDK_DIR/android-sdk/cmdline-tools"
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip
    unzip -q /tmp/cmdline-tools.zip -d "$SDK_DIR/android-sdk/cmdline-tools"
    mv "$SDK_DIR/android-sdk/cmdline-tools/cmdline-tools" "$SDK_DIR/android-sdk/cmdline-tools/latest"

    export ANDROID_HOME="$SDK_DIR/android-sdk"
    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

    yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
    sdkmanager --sdk_root=$ANDROID_HOME "$ANDROID_PLATFORM"

    add_to_path "$ANDROID_HOME/cmdline-tools/latest/bin"
    add_to_path "$ANDROID_HOME/platform-tools"

    echo "Android SDK installed at $ANDROID_HOME"
}

install_java() {
    echo "Installing OpenJDK $JAVA_VERSION..."
    case "$PKG_MANAGER" in
        apt-get) install_pkg openjdk-${JAVA_VERSION}-jdk ;;
        dnf) install_pkg java-${JAVA_VERSION}-openjdk-devel ;;
        pacman) install_pkg jdk${JAVA_VERSION}-openjdk ;;
    esac
    echo "OpenJDK $JAVA_VERSION installed."
}

# Parse args
DO_GRADLE=false
DO_ANDROID=false
DO_JAVA=false
DO_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --gradle) DO_GRADLE=true ;;
        --android-sdk) DO_ANDROID=true ;;
        --java) DO_JAVA=true ;;
        --all) DO_ALL=true ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Run installs
install_kotlin_create

if $DO_ALL; then
    install_gradle
    install_android_sdk
    install_java
else
    $DO_GRADLE && install_gradle
    $DO_ANDROID && install_android_sdk
    $DO_JAVA && install_java
fi

# Automatic shell setup
ENV_FILE="$SDK_DIR/env.sh"
SHELL_RC=""

if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "$ENV_FILE" "$SHELL_RC"; then
        echo "source $ENV_FILE" >> "$SHELL_RC"
        echo "Added source $ENV_FILE to $SHELL_RC"
    fi
fi

echo ""
echo "Installation Complete!"
echo "Example: kotlin-create -n my_project"
echo "Please restart your shell or run 'source $ENV_FILE' to update PATH."
echo ""
