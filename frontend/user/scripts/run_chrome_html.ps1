# Run Flutter on Chrome using the HTML renderer (disables CanvasKit fetch)
$env:FLUTTER_WEB_USE_SKIA = 'false'
flutter run -d chrome
