#!/bin/bash

# Build and launch Word Golf iOS in the simulator
# Usage: ./build-ios.sh [simulator-name]
# Default simulator: iPhone 16 Pro

set -e

SIMULATOR_NAME="${1:-iPhone 16 Pro}"
SCHEME="WordGolf-iOS"
BUNDLE_ID="com.palefire.WordGolf-iOS"

echo "Building Word Golf iOS..."

# Regenerate Xcode project if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "Regenerating Xcode project..."
    xcodegen generate
fi

# Get simulator ID
SIMULATOR_ID=$(xcrun simctl list devices available | grep "$SIMULATOR_NAME" | head -1 | grep -oE '[A-F0-9-]{36}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "Error: Could not find simulator '$SIMULATOR_NAME'"
    echo "Available simulators:"
    xcrun simctl list devices available | grep iPhone
    exit 1
fi

echo "Using simulator: $SIMULATOR_NAME ($SIMULATOR_ID)"

# Build the app
echo "Building $SCHEME..."
xcodebuild -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -configuration Debug \
    build 2>&1 | grep -E "(error:|warning:|BUILD|Compiling|Linking)" || true

# Check if build succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Find the built app (exclude Index.noindex which contains incomplete indexing artifacts)
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "WordGolf-iOS.app" -path "*/Debug-iphonesimulator/*" -not -path "*/Index.noindex/*" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app"
    exit 1
fi

echo "Built app: $APP_PATH"

# Boot simulator if needed
echo "Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true

# Open Simulator app
open -a Simulator

# Wait a moment for simulator to boot
sleep 2

# Install the app
echo "Installing app..."
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

# Launch the app
echo "Launching app..."
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

echo "Done! Word Golf iOS is running in $SIMULATOR_NAME"
