# Короткий TTL access-токена (60 с) для демонстрации refresh по 401.
Set-Location $PSScriptRoot\..
node api\mock-server.js --port 8080 --origin http://localhost:5555 --ttl 60
