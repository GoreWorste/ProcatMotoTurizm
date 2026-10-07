Set-Location $PSScriptRoot\..
$env:PR4_WEB_BASE = "http://localhost:5555"
python tools\capture_pr4_screenshots.py
python tools\render_pr4_code_images.py
python tools\generate_pr4_report.py
