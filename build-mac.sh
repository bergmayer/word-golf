#!/bin/bash

# Build and launch Word Golf Mac app
# Usage: ./build-mac.sh

set -e

SCHEME="WordGolf"

echo "Building Word Golf Mac..."

# Regenerate Xcode project if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "Regenerating Xcode project..."
    xcodegen generate
fi

# Build the app
echo "Building $SCHEME..."
xcodebuild -scheme "$SCHEME" -configuration Debug build 2>&1 | grep -E "(error:|warning:|BUILD|Compiling|Linking)" || true

# Check if build succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Find the built app (exclude Index.noindex which contains incomplete indexing artifacts)
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "WordGolf.app" -path "*/Debug/*" -not -path "*-iphonesimulator*" -not -path "*/Index.noindex/*" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app"
    exit 1
fi

echo "Built app: $APP_PATH"

# Launch the app
echo "Launching Word Golf..."
open "$APP_PATH"

echo "Done! Word Golf Mac is running."
