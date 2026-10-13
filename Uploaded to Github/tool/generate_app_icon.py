#!/usr/bin/env python3
"""Create the File Manager icon master and Android density launcher images."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "App Code" / "android" / "app" / "src" / "main" / "res"
MASTER = ROOT / "App Code" / "assets" / "app_icon.png"
BACKGROUND = (33, 198, 120, 255)
WHITE = (255, 255, 255, 255)
NAVY = (20, 35, 61, 255)
MINT = (40, 198, 164, 255)
SCALE = 4
ARTWORK_SCALE = 0.92


def point(value: int) -> int:
    return round((256 + (value - 256) * ARTWORK_SCALE) * SCALE)


def create_master() -> Image.Image:
    canvas = Image.new("RGBA", (512 * SCALE, 512 * SCALE), BACKGROUND)
    draw = ImageDraw.Draw(canvas)

    # Keep the foreground within Android's central adaptive-icon safe zone.
    draw.polygon(
        [
            (point(103), point(222)),
            (point(103), point(180)),
            (point(147), point(136)),
            (point(215), point(136)),
            (point(242), point(160)),
            (point(394), point(160)),
            (point(412), point(178)),
            (point(412), point(360)),
            (point(386), point(386)),
            (point(129), point(386)),
            (point(103), point(360)),
        ],
        fill=WHITE,
    )
    draw.ellipse(
        (point(297), point(287), point(391), point(381)),
        fill=NAVY,
    )
    draw.polygon(
        [
            (point(307), point(331)),
            (point(319), point(319)),
            (point(334), point(334)),
            (point(358), point(307)),
            (point(373), point(320)),
            (point(334), point(361)),
        ],
        fill=MINT,
    )
    return canvas.resize((512, 512), Image.Resampling.LANCZOS)


def main() -> None:
    icon = create_master()
    MASTER.parent.mkdir(parents=True, exist_ok=True)
    icon.save(MASTER, "PNG", optimize=True)
    for density, size in {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }.items():
        folder = RES / density
        folder.mkdir(parents=True, exist_ok=True)
        icon.resize((size, size), Image.Resampling.LANCZOS).save(
            folder / "ic_launcher.png", "PNG", optimize=True
        )
    print(f"Created 512 px master and Android launcher densities in {RES}")


if __name__ == "__main__":
    main()
