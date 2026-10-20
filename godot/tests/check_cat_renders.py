"""Check rendered poses for disconnected cats/tails and viewport-edge clipping.

Run after capture_cat.gd with a real rendering backend. Requires Pillow.
This inspects screenshots; it does not generate or edit game artwork.
"""

from collections import deque
from pathlib import Path

from PIL import Image


def components(mask: set[tuple[int, int]]) -> list[int]:
    sizes = []
    while mask:
        queue = deque([mask.pop()])
        size = 0
        while queue:
            x, y = queue.popleft()
            size += 1
            for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if point in mask:
                    mask.remove(point)
                    queue.append(point)
        sizes.append(size)
    return sorted(sizes, reverse=True)


def main() -> None:
    files = sorted(Path("/tmp").glob("cat-poses-[0-9][0-9].png"))
    files += sorted(Path("/tmp").glob("cat-transitions-[0-9][0-9].png"))
    assert len(files) == 48, "Capture all 24 poses and 24 transitions before running the render checks"
    failures = []
    for path in files:
        image = Image.open(path).convert("RGB")
        assert image.size == (1280, 1260)
        for index in range(18):
            left, top = index % 3 * 420, index // 3 * 210
            cell = image.crop((left, top, left + 420, top + 210))
            pixels = cell.load()
            mask = {
                (x, y)
                for y in range(210)
                for x in range(420)
                if not (x < 150 and y < 30)
                and max(pixels[x, y]) < 170
            }
            if any(x in (0, 419) or y in (0, 209) for x, y in mask):
                failures.append(f"{path.name}, pose {index}: clipped at cell edge")
            sizes = components(mask)
            if not sizes or sizes[0] < 500:
                failures.append(f"{path.name}, pose {index}: missing cat")
            elif len(sizes) > 1 and sizes[1] > sizes[0] * 0.04:
                failures.append(f"{path.name}, pose {index}: disconnected body part or duplicate cat ({sizes[:3]})")
    if failures:
        raise SystemExit("\n".join(failures))
    print("CAT VISUAL RESULT: 864 rendered poses and transitions have one connected cat and no clipped cell edges")


if __name__ == "__main__":
    main()
