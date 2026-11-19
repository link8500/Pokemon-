"""Build compact, offline-friendly data from the official PokéAPI dataset.

Only run to refresh the bundled snapshot. Visitors never download CSV sources
or all the pictures: the browser loads visible sprites on demand.
"""

import argparse
import concurrent.futures
import csv
import io
import json
import time
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/"
SPRITES = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/"
CACHE = ROOT / "tools/.data-cache"
PICTURES = ROOT / "web/lite/sprites"


def download(url):
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "Pokedex-static-assets/1.0"})
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.read()
        except (OSError, urllib.error.URLError):
            if attempt == 2:
                raise
            time.sleep(attempt + 1)


def table(name):
    CACHE.mkdir(parents=True, exist_ok=True)
    target = CACHE / name
    if not target.exists():
        target.write_bytes(download(SOURCE + name))
    return list(csv.DictReader(io.StringIO(target.read_text(encoding="utf-8-sig"))))


def sprite(pokemon_id):
    target = PICTURES / f"{pokemon_id}.png"
    if target.exists():
        return
    data = download(SPRITES + f"{pokemon_id}.png")
    with Image.open(io.BytesIO(data)) as image:
        if image.width > 128 or image.height > 128:
            raise ValueError(f"Unexpected sprite size: {pokemon_id}")
        image.save(target, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--refresh', action='store_true', help='Download current CSV data instead of reusing the source cache')
    options = parser.parse_args()
    if options.refresh:
        for name in ['types.csv', 'abilities.csv', 'pokemon_types.csv', 'pokemon_stats.csv', 'pokemon_abilities.csv', 'pokemon.csv']:
            (CACHE / name).unlink(missing_ok=True)
    PICTURES.mkdir(parents=True, exist_ok=True)
    types = {row["id"]: row["identifier"] for row in table("types.csv")}
    abilities = {row["id"]: row["identifier"] for row in table("abilities.csv")}
    pokemon_types = {}
    for row in sorted(table("pokemon_types.csv"), key=lambda value: int(value["slot"])):
        pokemon_types.setdefault(row["pokemon_id"], []).append(types[row["type_id"]])
    pokemon_stats = {}
    for row in table("pokemon_stats.csv"):
        pokemon_stats.setdefault(row["pokemon_id"], {})[int(row["stat_id"])] = int(row["base_stat"])
    pokemon_abilities = {}
    for row in sorted(table("pokemon_abilities.csv"), key=lambda value: int(value["slot"])):
        pokemon_abilities.setdefault(row["pokemon_id"], []).append(abilities[row["ability_id"]])
    rows = []
    for row in table("pokemon.csv"):
        pokemon_id = int(row["id"])
        if not 1 <= pokemon_id <= 1025:
            continue
        rows.append([
            pokemon_id, row["identifier"], pokemon_types[row["id"]],
            int(row["height"]), int(row["weight"]),
            [pokemon_stats[row["id"]][stat] for stat in range(1, 7)],
            pokemon_abilities[row["id"]], int(row["species_id"]),
        ])
    rows.sort(key=lambda row: row[0])
    assert [row[0] for row in rows] == list(range(1, 1026)), "Incomplete national Pokédex"
    snapshot = {"version": 1, "source": SOURCE, "updated": date.today().isoformat(), "rows": rows}
    output = ROOT / "assets/data/catalog.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(snapshot, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Compact catalogue: {len(rows)} Pokémon, {output.stat().st_size:,} bytes", flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
        for count, _ in enumerate(executor.map(sprite, range(1, 1026)), start=1):
            if count % 100 == 0:
                print(f"Small sprites ready: {count}/1025", flush=True)
    hero = ROOT / "web/lite/pikachu.webp"
    if not hero.exists():
        data = download(SPRITES + "other/official-artwork/25.png")
        with Image.open(io.BytesIO(data)) as image:
            image.thumbnail((192, 192))
            image.save(hero, "WEBP", quality=65, method=6)
    print("Offline catalogue and all small sprites ready.", flush=True)


if __name__ == "__main__":
    main()
