# Release-сборка для публикации на поддомене (корень сайта, не GitHub Pages).
Set-Location $PSScriptRoot\..

flutter pub get
flutter build web --release `
  --base-href / `
  --dart-define=USE_API=false `
  --no-web-resources-cdn

Copy-Item -Force build\web\index.html build\web\404.html
Write-Host "Сборка: build\web"
