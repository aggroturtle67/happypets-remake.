"""Build a directly playable Windows archive and a clean Godot source archive."""
from pathlib import Path
import hashlib
import struct
import zipfile

ROOT = Path(__file__).resolve().parent.parent
EXE = ROOT / "godot/builds/windows/Pfotenstube.exe"
OUT = ROOT / "exports"
OUT.mkdir(exist_ok=True)

with EXE.open("rb") as stream:
    if stream.read(2) != b"MZ":
        raise SystemExit("Windows export is missing its PE header.")
    stream.seek(0x3C)
    offset = struct.unpack("<I", stream.read(4))[0]
    stream.seek(offset)
    if stream.read(6) != b"PE\x00\x00\x64\x86":
        raise SystemExit("The export is not a Windows x64 executable.")
    stream.seek(-4, 2)
    if stream.read() != b"GDPC":
        raise SystemExit("The executable does not contain its embedded Godot game pack.")

readme = """PFOTENSTUBE - WINDOWS-TESTVERSION

1. Dieses ZIP-Paket mit 'Alle extrahieren' vollstaendig entpacken.
2. Im entpackten Ordner 'Pfotenstube.exe' per Doppelklick starten.

Kein Godot-Editor, kein Node.js, kein Konto und kein Internet erforderlich.
Voraussetzung: Windows 10/11, 64 Bit, Grafiktreiber mit OpenGL 3.3.

SPIELEN
- Waehle Momo oder Milo aus und fuettere, bespiele oder pflege dein Tier.
- Momo laeuft durch das Zimmer und reagiert mit Rennen, Springen,
  Sitzen, Putzen, Schlafen, Fressen, Trinken und Katzenklo-Animationen.
- Zum Fressen und Trinken laeuft sie an die aufgestellten Naepfe.
  Ein Katzenklo fuer vorhandene Spielstaende gibt es unter Einrichtung.
- Ein Klick auf das Tier im Zimmer streichelt es.
- Im Laden kannst du Tiere adoptieren und Moebel kaufen.
- Unter 'Einrichten' Moebel ziehen oder per Pfeiltasten bewegen.
- R: drehen, Entf: einlagern. Im Moebellager wieder aufstellen.
- F11 schaltet Vollbild um. Unter Hilfe kannst du Spielstaende sichern.

Dein Fortschritt wird automatisch unter %APPDATA%\\Pfotenstube gespeichert.
Die alte Browser-Version hat einen getrennten Spielstand.

Dies ist ein erster spielbarer Godot-Prototyp. Noch ohne Zucht,
Freundesbesuche, Mehrspieler und Online-Konten.
Spielregeln, echte Godot-Oberflaeche und ein Linux-Export wurden in der
Cloud geprueft. Diese Windows-EXE wurde hier nicht unter Windows ausgefuehrt.
Die Testversion ist nicht digital signiert.

Die Engine-Lizenzen liegen im Unterordner 'Lizenzen'.
"""

windows = OUT / "Pfotenstube-Windows-x64.zip"
with zipfile.ZipFile(windows, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    archive.write(EXE, "Pfotenstube/Pfotenstube.exe")
    archive.writestr("Pfotenstube/LIESMICH.txt", readme.replace("\n", "\r\n"))
    for license_file in sorted((ROOT / "godot/licenses").glob("*.txt")):
        archive.write(license_file, "Pfotenstube/Lizenzen/" + license_file.name)
with zipfile.ZipFile(windows) as archive:
    if archive.testzip() is not None:
        raise SystemExit("Windows archive integrity check failed.")

source = OUT / "Pfotenstube-Godot-Projekt.zip"
with zipfile.ZipFile(source, "w", zipfile.ZIP_DEFLATED) as archive:
    for file in sorted((ROOT / "godot").rglob("*")):
        relative = file.relative_to(ROOT / "godot")
        if not file.is_file() or any(part in (".godot", "builds") for part in relative.parts):
            continue
        archive.write(file, Path("Pfotenstube-Godot") / relative)

for artifact in [windows, source]:
    with artifact.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    artifact.with_suffix(artifact.suffix + ".sha256").write_text(digest + "  " + artifact.name + "\n")
    print(f"Created {artifact.name}: {artifact.stat().st_size:,} bytes; SHA-256 {digest}")
