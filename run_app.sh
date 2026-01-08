#!/bin/bash

# Meddeck App Runner
# This script automatically runs the meddeck app

cd /Users/mmesomaaliozor/meddeck

echo "🚀 Starting meddeck app..."

# Check for iOS simulators
IOS_DEVICES=$(flutter devices | grep -i "iphone\|ipad\|ios simulator")

if [ ! -z "$IOS_DEVICES" ]; then
    echo "📱 iOS Simulator detected, launching on iOS..."
    flutter run -d ios
else
    echo "💻 No iOS Simulator found, launching on macOS..."
    echo "To install iOS simulators, open Xcode > Settings > Platforms > iOS"
    flutter run -d macos
fi
