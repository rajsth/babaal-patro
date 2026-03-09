---
description: Build release APK and install it on a connected Android device
---

# Build & Deploy to Device

// turbo-all

## Steps

1. Check that a device is connected via USB:
```bash
adb devices
```
If no device is listed, ensure USB Debugging is enabled on the phone and it's connected via USB.

2. Build the release APK:
```bash
flutter build apk --release
```

3. Install the APK on the connected device (replaces existing install):
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

4. Launch the app on the device:
```bash
adb shell am start -n com.babaal.patro/.MainActivity
```
