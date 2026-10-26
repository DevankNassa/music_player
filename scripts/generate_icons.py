#!/usr/bin/env python3
"""Regenerates every platform's app icon from the 5a "disc + tag" mock
(claude.ai/design project Insta-Playlist Mocks): the Player's cropped record
on a terracotta ground, with a tag laid over it.

Needs rsvg-convert (librsvg) and ImageMagick's `magick`. Run from anywhere:

    python3 scripts/generate_icons.py
"""
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Organic tokens (lib/theme/organic.dart).
ACCENT = "#C67139"
ACCENT2_300 = "#CCDBB2"
ACCENT2_400 = "#AEBF92"
BG = "#F5EAD8"


def art() -> str:
    """Icon artwork in a 100x100 box, mirroring the mock's CSS geometry."""
    # Disc: 96% wide at (24%, 24%), so centred at 72 with r=48. The CSS
    # repeating-radial-gradient sizes to the farthest corner (48*sqrt2), and
    # alternates the two greens every 5% of that.
    cx = cy = 72
    r = 48
    band = 48 * 2**0.5 * 0.05
    rings = []
    k = int(r / band)
    while k >= 0:
        color = ACCENT2_300 if k % 2 == 0 else ACCENT2_400
        rings.append(f'<circle cx="{cx}" cy="{cy}" r="{min(band * (k + 1), r):.3f}" fill="{color}"/>')
        k -= 1
    # Tag: 44x20 pill at (14%, 24%), rotated -40deg about its centre, with a
    # punched dot 22% of its width, inset 6% of the icon from its left end.
    return (
        "".join(rings)
        + f'<circle cx="{cx}" cy="{cy}" r="10" fill="{BG}"/>'
        + '<g transform="rotate(-40 36 34)">'
        + f'<rect x="14" y="24" width="44" height="20" rx="10" fill="{BG}"/>'
        + f'<circle cx="24.84" cy="34" r="4.84" fill="{ACCENT}"/>'
        + "</g>"
    )


def svg(*, background: bool = True, pad: float = 0) -> str:
    """Full-bleed icon. `pad` widens the viewBox on every side (for Android's
    adaptive foreground, whose visible area is only the middle of the layer)."""
    lo, size = -pad, 100 + 2 * pad
    clip = f'<clipPath id="c"><rect x="{lo}" y="{lo}" width="{size}" height="{size}"/></clipPath>'
    bg = f'<rect x="{lo}" y="{lo}" width="{size}" height="{size}" fill="{ACCENT}"/>' if background else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{lo} {lo} {size} {size}">'
        f'<defs>{clip}</defs><g clip-path="url(#c)">{bg}{art()}</g></svg>'
    )


def render(svg_text: str, out: Path, px: int, *, opaque: bool = False) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".svg") as f:
        f.write(svg_text)
        f.flush()
        subprocess.run(["rsvg-convert", "-w", str(px), "-h", str(px), "-o", str(out), f.name], check=True)
    if opaque:
        # App Store rejects icons with an alpha channel.
        subprocess.run(["magick", str(out), "-background", ACCENT, "-alpha", "remove", "-alpha", "off", str(out)], check=True)


def main() -> None:
    full = svg()
    (ROOT / "assets/icon").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets/icon/app_icon.svg").write_text(full + "\n")

    # iOS: sizes come from the asset catalog itself.
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for image in json.loads((ios / "Contents.json").read_text())["images"]:
        if "filename" not in image:
            continue
        pt = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        render(full, ios / image["filename"], round(pt * scale), opaque=True)

    # macOS: same catalog format.
    mac = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for image in json.loads((mac / "Contents.json").read_text())["images"]:
        pt = int(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        render(full, mac / image["filename"], pt * scale)

    # Android: legacy square icon plus an adaptive icon. The adaptive layers
    # are 108dp with the middle 72dp visible, hence the 25-unit padding.
    res = ROOT / "android/app/src/main/res"
    for density, scale in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
        render(full, res / f"mipmap-{density}/ic_launcher.png", round(48 * scale))
        render(svg(background=False, pad=25), res / f"mipmap-{density}/ic_launcher_foreground.png", round(108 * scale))
    (res / "mipmap-anydpi-v26").mkdir(exist_ok=True)
    (res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    (res / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">{ACCENT}</color>\n'
        "</resources>\n"
    )

    # Web.
    web = ROOT / "web"
    render(full, web / "favicon.png", 32)
    for px in (192, 512):
        render(full, web / f"icons/Icon-{px}.png", px)
        # Maskable icons get cropped to a circle of 80% diameter; padding
        # 12.5 keeps the tag inside it.
        render(svg(pad=12.5), web / f"icons/Icon-maskable-{px}.png", px)

    # Windows.
    with tempfile.TemporaryDirectory() as tmp:
        pngs = []
        for px in (16, 24, 32, 48, 64, 128, 256):
            p = Path(tmp) / f"{px}.png"
            render(full, p, px)
            pngs.append(str(p))
        subprocess.run(["magick", *pngs, str(ROOT / "windows/runner/resources/app_icon.ico")], check=True)


if __name__ == "__main__":
    main()
