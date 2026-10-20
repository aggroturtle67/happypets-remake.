"""Install pinned official Godot export templates without changing system files."""
from pathlib import Path
import argparse
import hashlib
import os
import subprocess
import tempfile
import zipfile

VERSION = "4.6.3"
SHA512 = "da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68"
URL = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"
TARGET = Path(os.environ["XDG_DATA_HOME"]) / "godot/export_templates" / f"{VERSION}.stable"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--web", action="store_true", help="Install the single-threaded web release template instead of desktop templates")
args = parser.parse_args()
FILES = ["web_nothreads_release.zip", "version.txt"] if args.web else ["windows_release_x86_64.exe", "linux_release.x86_64", "version.txt"]
MARKER = TARGET / ".official-archive-sha512"

if MARKER.is_file() and MARKER.read_text().strip() == SHA512 and all((TARGET / name).is_file() for name in FILES):
    print("Reusing verified Godot 4.6.3 export templates.")
else:
    archive = Path(tempfile.gettempdir()) / f"Godot_v{VERSION}-stable_export_templates.tpz"
    if not archive.is_file():
        subprocess.run(["curl", "--fail", "--location", "--silent", "--show-error", "--retry", "2", "--max-time", "300", URL, "-o", str(archive)], check=True)
    with archive.open("rb") as stream:
        actual = hashlib.file_digest(stream, "sha512").hexdigest()
    if actual != SHA512:
        raise SystemExit("Godot template SHA-512 verification failed. Do not use this archive. Remove the corrupt cached download and retry from the official release.")
    TARGET.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as zipped:
        for name in FILES:
            (TARGET / name).write_bytes(zipped.read("templates/" + name))
    MARKER.write_text(SHA512 + "\n")
    print("Installed Godot 4.6.3 templates after official SHA-512 verification.")
