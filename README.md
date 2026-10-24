# YourPrinter Mobile

Cross-platform 3D printing telemetry, multi-camera streaming, and print management client for **YourPrinter** and **Bambu Lab** printers. Built with Flutter for high performance on Android and iOS.

---

## 🚀 Features

- **Fleet Dashboard**: Row-by-row live monitoring of all networked printers with synchronized 16:9 live camera feeds.
- **Swipe-to-Cycle Controls**: Horizontal swipe between printers on the Device screen with numerical counter (`1/2`, `2/2`) and interactive dot indicators.
- **Real-Time Telemetry**: Live nozzle & bed temperatures, layer progress, active file names, and print status updates via WebSocket with REST fallback.
- **Dual Camera Architecture**: Native WebRTC streaming via `go2rtc` with automatic fallback to high-framerate MJPEG snapshots.
- **Smart Error Handling**: Generic, user-friendly connection cards with an expandable technical details inspector (`RAW ERROR LOG`) and one-tap error copying.
- **Automated CI/CD Builds**: Continuous integration and release publishing directly on GitHub Actions.

---

## 📦 Automated GitHub Builds & APK Downloads

Every push to `master` automatically triggers GitHub Actions to test, build, and publish ready-to-install Android APKs:

1. **Direct Releases**:
   - Go to [**GitHub Releases**](https://github.com/christianborges121/YourPrinter-Mobile/releases).
   - Under the **Latest Build** (or tag release), download:
     - **`YourPrinter-Mobile-arm64-v8a-release.apk`** *(Recommended)*: Optimized for modern Android phones (Samsung Galaxy, Google Pixel, OnePlus) with faster startup and smaller file size.
     - **`YourPrinter-Mobile-universal-release.apk`**: Universal binary compatible with all Android devices (Android 5.0+ / API 21+).
2. **GitHub Actions Artifacts**:
   - You can also download APKs from any completed workflow run under the [**Actions Tab**](https://github.com/christianborges121/YourPrinter-Mobile/actions).

---

## 📲 Installation on Android

1. Download the `.apk` file directly on your phone or transfer it via ADB:
   ```bash
   adb install -r YourPrinter-Mobile-arm64-v8a-release.apk
   ```
2. If installing directly via your phone's browser/file manager, allow *"Install unknown apps"* when prompted.
3. Launch **YourPrinter Mobile** and enter your YourPrinter Server Base URL (e.g., `http://192.168.68.120:3080`).

---

## 🛠 Local Development

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```
