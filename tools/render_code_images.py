"""Render Dart source snippets as PNG for the PR3 report."""
from __future__ import annotations

import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "screenshots_report" / "pr3" / "code"
OUT.mkdir(parents=True, exist_ok=True)

SNIPPETS: dict[str, tuple[str, int, int]] = {
    "validators.dart": ("lib/core/validators.dart", 1, 95),
    "app_data_store.dart": ("lib/repositories/app_data_store.dart", 1, 120),
    "equipment_form_relations.dart": ("lib/screens/equipment_form_screen.dart", 130, 320),
    "client_form_card.dart": ("lib/screens/client_form_screen.dart", 130, 250),
    "form_scaffold_popscope.dart": ("lib/widgets/form_scaffold.dart", 1, 75),
    "multi_id_chips.dart": ("lib/widgets/multi_id_chips_field.dart", 1, 80),
    "brand_delete_guard.dart": ("lib/repositories/persistent_brand_repository.dart", 55, 95),
    "main_persistence.dart": ("lib/main.dart", 31, 95),
    "equipment_toJson.dart": ("lib/models/equipment.dart", 60, 95),
}


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for name in ("CascadiaMono.ttf", "Consolas.ttf", "cour.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def render_file(name: str, rel_path: str, start: int, end: int) -> Path:
    src = ROOT / rel_path
    lines = src.read_text(encoding="utf-8").splitlines()
    chunk = lines[start - 1 : end]
    numbered = [f"{i + start:4}  {line}" for i, line in enumerate(chunk)]
    text = "\n".join(numbered)

    font = _font(14)
    padding = 16
    max_width = 1100
    wrapped_lines: list[str] = []
    for line in text.split("\n"):
        if len(line) <= 120:
            wrapped_lines.append(line)
        else:
            wrapped_lines.extend(textwrap.wrap(line, width=120))

    line_h = 20
    img_h = padding * 2 + line_h * len(wrapped_lines) + 28
    img = Image.new("RGB", (max_width, img_h), (30, 30, 30))
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, max_width, 26), fill=(45, 45, 48))
    draw.text((padding, 5), f"{rel_path} ({start}:{end})", fill=(200, 200, 200), font=_font(12))
    y = padding + 20
    for line in wrapped_lines:
        draw.text((padding, y), line, fill=(220, 220, 220), font=font)
        y += line_h

    out = OUT / f"{name}.png"
    img.save(out)
    return out


def main() -> None:
    for key, (path, start, end) in SNIPPETS.items():
        out = render_file(key, path, start, end)
        print(out)


if __name__ == "__main__":
    main()
