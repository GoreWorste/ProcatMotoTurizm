# -*- coding: utf-8 -*-
"""Фрагменты кода для отчёта ПР5."""
from __future__ import annotations

from pathlib import Path

from render_code_images import render_file

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr5" / "code"
OUT.mkdir(parents=True, exist_ok=True)

SNIPPETS: dict[str, tuple[str, int, int]] = {
    "auth_notifier.dart": ("lib/state/auth_notifier.dart", 1, 95),
    "app_router_redirect.dart": ("lib/routing/app_router.dart", 24, 55),
    "api_client_refresh.dart": ("lib/core/api_client.dart", 64, 110),
    "inactivity_watcher.dart": ("lib/widgets/inactivity_watcher.dart", 1, 55),
    "mock_server_auth.js": ("api/mock-server.js", 70, 165),
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
