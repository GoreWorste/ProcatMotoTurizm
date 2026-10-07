# Сборка для GitHub Pages (репозиторий GoreWorste/ProcatMotoTurizm).
Set-Location $PSScriptRoot\..

flutter pub get
flutter build web --release `
  --base-href /ProcatMotoTurizm/ `
  --dart-define=USE_API=false `
  --no-web-resources-cdn

Copy-Item -Force build\web\index.html build\web\404.html
Write-Host "Готово: build\web (загрузите через Actions или ветку gh-pages)"
