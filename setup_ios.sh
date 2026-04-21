#!/bin/bash

# 🎓 TANDAU iOS Setup Script
# This script prepares the Flutter project for iOS build on a Mac.

echo "🚀 Starting TANDAU iOS Setup..."

# 1. Check for Flutter
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter not found. Please install Flutter first: https://docs.flutter.dev/get-started/install/macos"
    exit
fi

# 2. Get dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# 3. Handle CocoaPods
cd ios
if ! command -v pod &> /dev/null
then
    echo "⚠️ CocoaPods not found. Attempting to install..."
    sudo gem install cocoapods
fi

echo "📦 Installing Pods (this may take a while on older Macs)..."
# Using --repo-update to ensure we have the latest specs
pod install --repo-update

cd ..

# 4. Generate App Icons (if launcher_icons is configured)
echo "🎨 Generating App Icons..."
flutter pub run flutter_launcher_icons:main

echo ""
echo "✅ Setup Complete!"
echo "--------------------------------------------------"
echo "🍎 Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select your development Team in 'Signing & Capabilities'"
echo "3. Press Cmd + R to run on your device/simulator"
echo "--------------------------------------------------"
