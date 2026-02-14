# TANDAU - Quick Start Guide

## 🚀 Getting Started

### Step 1: Install Dependencies

Open a terminal in the project directory and run:

```bash
flutter pub get
```

This will install:
- google_fonts (for modern typography)
- shared_preferences (for saving favorites)
- intl (for internationalization)

### Step 2: Run the App

```bash
flutter run
```

Or in VS Code:
- Press `F5` to start debugging
- Or use the "Run and Debug" panel

### Step 3: Choose Your Device

If you have multiple devices/emulators:

```bash
flutter devices          # List available devices
flutter run -d <device>  # Run on specific device
```

## ✅ What to Test

1. **Home Screen**: Check branding and statistics display
2. **Filter Flow**: Go through city → major → budget selection
3. **University List**: Search and browse filtered results
4. **Details**: View university information in tabs
5. **Favorites**: Add/remove universities, check persistence

## 🐛 Troubleshooting

### "Flutter command not found"
- Make sure Flutter is installed and added to PATH
- Restart your terminal/VS Code

### "No devices found"
- Start an Android emulator or iOS simulator
- Or connect a physical device with USB debugging enabled

### Lint errors about missing packages
- Run `flutter pub get` first
- These errors will disappear after dependencies are installed

## 📱 Recommended Testing

- **Android**: Test on Android 8.0+ (API 26+)
- **iOS**: Test on iOS 12.0+
- **Screen sizes**: Test on different device sizes

## 🎯 Next Steps

After testing the MVP:
1. Gather user feedback
2. Plan AI agent integration
3. Connect to real university database
4. Add more features from the roadmap

---

**Need help?** Check the main README.md or walkthrough.md for detailed information.
