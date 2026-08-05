#!/bin/bash
# install_android-deps.sh: Install all dependencies for Android build on Linux

set -e

# Prevent running the whole script with sudo/root.
# We still use sudo for apt installs below, but the SDK should be under the user home, not /root.
if [ "$(id -u)" -eq 0 ]; then
  if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    echo "This script should not be run with sudo. Re-running as $SUDO_USER..."
    exec sudo -u "$SUDO_USER" -H bash "$0" "$@"
  else
    echo "Please run this script without sudo (it will use sudo only where needed)." >&2
    exit 1
  fi
fi

sudo apt update
sudo apt install -y cmake libx11-dev libxfixes-dev libegl-dev libgbm-dev libfontconfig-dev unzip curl zip ninja-build openjdk-8-jdk adb google-android-cmdline-tools-13.0-installer

export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.2.9519653"
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"


sdkmanager --sdk_root=$ANDROID_HOME \
  "platform-tools" \
  "platforms;android-32" \
  "build-tools;32.0.0" \
  "ndk;25.2.9519653"


echo
read -p "Add Android environment variables to your ~/.bashrc for future sessions? If not, you will need to set them manually. [y/N] " add_envs
if [[ "$add_envs" =~ ^[Yy]$ ]]; then
  {
    echo ''
    echo '# Android SDK/NDK environment variables (added by install_android_deps.sh)'
    echo 'export ANDROID_HOME="$HOME/Android/Sdk"'
    echo 'export ANDROID_SDK_ROOT="$ANDROID_HOME"'
    echo 'export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.2.9519653"'
    echo 'export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"'
    echo 'export PATH="$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"'
  } >> "$HOME/.bashrc"
  echo "Variables added to ~/.bashrc. Please restart your terminal or run: source ~/.bashrc"
else
  echo "Skipped adding environment variables to ~/.bashrc."
fi

