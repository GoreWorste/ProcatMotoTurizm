# Flutter Web без CDN Google (нужно, если gstatic.com/fonts.gstatic.com недоступны).
Set-Location $PSScriptRoot\..
flutter run -d chrome --web-port=5555 --no-web-resources-cdn `
  --dart-define=USE_API=true `
  --dart-define=API_BASE_URL=http://localhost:8080/api `
  @args
