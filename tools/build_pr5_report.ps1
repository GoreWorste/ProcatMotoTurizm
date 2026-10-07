Set-Location $PSScriptRoot\..
$env:PR5_WEB_BASE = "http://localhost:5555"
python tools\capture_pr5_screenshots.py
python tools\render_pr5_code_images.py
python tools\generate_pr5_report.py
