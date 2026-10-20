#!/usr/bin/env python3
"""Turn generated character sheets into evenly spaced Godot sprite sheets."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
CELL = (420, 280)
COLUMNS = 8


def find_boundaries(alpha: Image.Image, frame_count: int) -> list[int]:
    width, height = alpha.size
    pixels = alpha.load()
    density = [sum(pixels[x, y] > 8 for y in range(height)) for x in range(width)]
    boundaries = [0]
    nominal_cell = width / frame_count
    for index in range(1, frame_count):
        nominal = index * nominal_cell
        radius = int(nominal_cell * 0.28)
        low = max(boundaries[-1] + 2, int(nominal - radius))
        high = min(width - 2, int(nominal + radius))
        scores = {
            x: sum(density[max(0, x - 2) : min(width, x + 3)])
            for x in range(low, high + 1)
        }
        minimum = min(scores.values())
        candidates = [x for x, score in scores.items() if score == minimum]
        runs: list[list[int]] = []
        for x in candidates:
            if not runs or x != runs[-1][-1] + 1:
                runs.append([x])
            else:
                runs[-1].append(x)
        best = min(runs, key=lambda run: abs((run[0] + run[-1]) / 2 - nominal))
        boundaries.append((best[0] + best[-1]) // 2)
    boundaries.append(width)
    return boundaries


def normalize(frame: Image.Image, scale: float) -> Image.Image:
    alpha = frame.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if bounds is None:
        return Image.new("RGBA", CELL)
    frame = frame.crop(bounds)
    if scale != 1.0:
        frame = frame.resize(
            (round(frame.width * scale), round(frame.height * scale)),
            Image.Resampling.LANCZOS,
        )
    maximum_width, maximum_height = CELL[0] - 16, CELL[1] - 12
    fit = min(maximum_width / frame.width, maximum_height / frame.height, 1.0)
    if fit < 1.0:
        frame = frame.resize(
            (round(frame.width * fit), round(frame.height * fit)),
            Image.Resampling.LANCZOS,
        )
    canvas = Image.new("RGBA", CELL)
    x = (CELL[0] - frame.width) // 2
    y = CELL[1] - frame.height - 6
    canvas.alpha_composite(frame, (x, y))
    return canvas


def rebuild(path: Path, output: Path, rows: list[int], scale: float) -> None:
    source = Image.open(path).convert("RGBA")
    result = Image.new("RGBA", (CELL[0] * COLUMNS, CELL[1] * len(rows)))
    for row_index, frame_count in enumerate(rows):
        top = round(row_index * source.height / len(rows))
        bottom = round((row_index + 1) * source.height / len(rows))
        row = source.crop((0, top, source.width, bottom))
        boundaries = find_boundaries(row.getchannel("A"), frame_count)
        for frame_index in range(frame_count):
            frame = row.crop(
                (boundaries[frame_index], 0, boundaries[frame_index + 1], row.height)
            )
            result.alpha_composite(
                normalize(frame, scale), (frame_index * CELL[0], row_index * CELL[1])
            )
    result.save(output, optimize=True)


def main() -> None:
    rebuild(
        ASSETS / "cat_locomotion_source.png",
        ASSETS / "cat_locomotion.png",
        [8, 8, 8],
        1.0,
    )
    rebuild(
        ASSETS / "cat_activities_source.png",
        ASSETS / "cat_activities.png",
        [6, 8, 6, 8, 8, 5],
        1.5,
    )


if __name__ == "__main__":
    main()
