# german_bharatham_admin

Run web locally with the HTML renderer (recommended when behind a firewall/proxy that blocks gstatic):

PowerShell:

    scripts\run_chrome_html.ps1

This sets the environment variable `FLUTTER_WEB_USE_SKIA=false` and starts `flutter run -d chrome` so CanvasKit won't be fetched from the gstatic CDN.

## Run on Android (always sets adb reverse)

If you run on a physical phone and your backend is on your PC at port `5000`, use:

PowerShell (from this folder):

    scripts\run_android.ps1 -DeviceId ZD2227D74V

Or let it auto-pick the first connected device:

    scripts\run_android.ps1

This script finds `adb.exe` even if it isn't on PATH, runs `adb reverse tcp:5000 tcp:5000`, then runs `flutter run`.

This app's default API base URL is the Render backend: `https://german-bharatham-backend.onrender.com`.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
