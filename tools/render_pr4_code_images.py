# -*- coding: utf-8 -*-
"""Фрагменты кода для отчёта ПР4."""
from __future__ import annotations

from pathlib import Path

from render_code_images import render_file

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr4" / "code"
OUT.mkdir(parents=True, exist_ok=True)

SNIPPETS: dict[str, tuple[str, int, int]] = {
    "config.dart": ("lib/core/config.dart", 1, 12),
    "api_client.dart": ("lib/core/api_client.dart", 1, 62),
    "api_exceptions.dart": ("lib/core/api_exceptions.dart", 28, 92),
    "main_api_wiring.dart": ("lib/main.dart", 42, 86),
    "api_equipment_find.dart": ("lib/repositories/api/api_equipment_repository.dart", 1, 80),
}


def main() -> None:
    for key, (path, start, end) in SNIPPETS.items():
        out = render_file(key, path, start, end)
        target = OUT / out.name
        if out != target:
            out.replace(target)
        print(target)


if __name__ == "__main__":
    main()
