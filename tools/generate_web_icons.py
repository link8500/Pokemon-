"""Render the app's existing vector Pokéball mark as browser/PWA PNG icons.

Run with Python and Pillow. Runtime/build dependencies of Flutter are unchanged.
"""

from pathlib import Path

from PIL import Image, ImageDraw


WEB = Path(__file__).resolve().parents[1] / "web"
ICONS = WEB / "icons"
RED = "#ed4b4e"


def pokeball(size: int, maskable: bool = False) -> Image.Image:
    # Supersampling keeps the small browser-tab icon crisp.
    canvas_size = size * 4
    image = Image.new("RGBA", (canvas_size, canvas_size), "#f7f8fa" if maskable else (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    inset = canvas_size * 0.12 if maskable else 0
    diameter = canvas_size - inset * 2
    center = canvas_size / 2
    draw.ellipse((inset, inset, canvas_size - inset - 1, canvas_size - inset - 1), fill=RED)
    draw.line((inset, center, canvas_size - inset, center), fill="white", width=round(diameter * 0.10))
    outer = diameter * 0.172
    inner = diameter * 0.094
    draw.ellipse((center - outer, center - outer, center + outer, center + outer), fill="white")
    draw.ellipse((center - inner, center - inner, center + inner, center + inner), fill=RED)
    return image.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    ICONS.mkdir(parents=True, exist_ok=True)
    for size in (32, 180, 192, 512):
        pokeball(size).save(ICONS / f"pokedex-{size}-v2.png", optimize=True)
    for size in (192, 512):
        pokeball(size, maskable=True).save(ICONS / f"pokedex-maskable-{size}-v2.png", optimize=True)
        # Update legacy filenames too, for clients still using an old manifest.
        pokeball(size).save(ICONS / f"Icon-{size}.png", optimize=True)
        pokeball(size, maskable=True).save(ICONS / f"Icon-maskable-{size}.png", optimize=True)
    pokeball(64).save(WEB / "favicon.png", optimize=True)
    pokeball(64).save(WEB / "favicon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])


if __name__ == "__main__":
    main()
