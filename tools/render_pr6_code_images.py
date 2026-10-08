# -*- coding: utf-8 -*-
from __future__ import annotations

from pathlib import Path

from render_code_images import render_file

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr6" / "code"
OUT.mkdir(parents=True, exist_ok=True)

SNIPPETS: dict[str, tuple[str, int, int]] = {
    "layout_breakpoints.dart.png": ("lib/core/layout_breakpoints.dart", 1, 16),
    "build_production.ps1.png": ("scripts/build_production.ps1", 1, 14),
    "index_html_meta.png": ("web/index.html", 17, 35),
    "nginx_motoprocat.png": ("deploy/nginx-motoprocatflutter.conf", 1, 28),
}


def main() -> None:
    for key, (path, start, end) in SNIPPETS.items():
        out = render_file(key.replace(".png", ""), path, start, end)
        target = OUT / key
        if out != target:
            out.replace(target)
        print(target)


if __name__ == "__main__":
    main()
