# Заливка build/web на VPS (нужен OpenSSH: scp/ssh).
# Пример: .\scripts\deploy_to_vps.ps1 -User deploy -Host 213.171.28.69

param(
    [string]$User = "root",
    [string]$Host = "213.171.28.69",
    [string]$RemotePath = "/var/www/motoprocatflutter"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path "build\web\index.html")) {
    & "$PSScriptRoot\build_production.ps1"
}

Write-Host "Копирование на ${User}@${Host}:${RemotePath} ..."
ssh "${User}@${Host}" "mkdir -p $RemotePath"
scp -r build\web\* "${User}@${Host}:${RemotePath}/"
Write-Host "Готово. Проверьте: http://motoprocatflutter.romanovivv.ru/"
