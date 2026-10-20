# Pfotenstube – Godot-Projekt

Ein eigenständiges 2D-Haustierspiel in **Godot 4.6.3**, mit GDScript und dem Compatibility-Renderer. Zum Spielen wird kein Browser-Framework benötigt.

## Sofort auf Windows spielen

1. `Pfotenstube-Windows-x64.zip` herunterladen.
2. Rechtsklick auf das ZIP → **Alle extrahieren**.
3. Im entpackten Ordner **Pfotenstube.exe** doppelklicken.

Die EXE enthält alle Spielressourcen. Godot-Editor, Node.js, Konto und Internet sind nicht erforderlich. Ziel: Windows 10/11 auf x64, mit einem Grafiktreiber für OpenGL 3.3. Dies ist ein unsignierter Prototyp. Der Windows-Export wird in der Linux-Cloud erstellt und strukturell geprüft; ein Test auf einem echten Windows-PC steht noch aus.

## Im Godot-Editor weiterentwickeln

Godot 4.6.3 Standard installieren; die .NET-Ausgabe ist nicht erforderlich. Im Projektmanager **Importieren** wählen, `project.godot` in diesem Ordner öffnen und mit **F5** starten. `Pfotenstube-Godot-Projekt.zip` enthält diesen Ordner ohne generierte Caches und ausführbare Builds.

## Spielen und Fortschritt

Zwei Tiere begrüßen dich: Momo und Milo. Füttern kostet 8 Münzen, Spielen bringt 12 und Pflegen 10 Münzen. Tagesziele und das einmal tägliche Geschenk bringen zusätzliche Münzen. Je 100 Erfahrungspunkte steigt dein Level. Ab Level 2 können Kaninchen einziehen; bis zu sechs Tiere wohnen in einer Stube.

Ein Klick auf ein Tier im Zimmer streichelt es. Ein Klick auf seine Karte wählt es aus. Über **Name** kannst du es umbenennen. Möbel werden im Einrichtungsmodus mit der Maus gezogen oder mit den Pfeiltasten verschoben. **R** dreht, **Entf** lagert ein. Über **Möbellager** kannst du sie kostenlos wieder aufstellen. **F11** schaltet Vollbild um. **Esc** schließt ein geöffnetes Fenster oder beendet den Einrichtungsmodus.

Die graue Katze bewegt sich mit einem zusammenhängenden 2D-Rig aus sechs freigestellten Körperteilen. Beim Füttern läuft sie zum vorhandenen Futternapf und senkt dort den Kopf; beim Trinken nutzt sie dessen Wasserseite. Verschieben, Spiegeln und Einlagern eines Napfes werden berücksichtigt. Ohne aufgestellten freien Napf werden keine Futterkosten abgezogen. Das Katzenklo ist ein eigenes Möbelstück im Einrichtungsladen; neue Spielstände enthalten bereits eines. Vorhandene Spielstände bleiben kompatibel.

Spielstände werden automatisch auf diesem PC gespeichert, unter Windows in `%APPDATA%\Pfotenstube\spielstand.json`. Der vorherige Stand bleibt als `.backup` erhalten. Beschädigte Daten werden vor der Wiederherstellung als `.damaged` gesichert. Unter **Hilfe** kannst du einen Spielstand exportieren, importieren und den Speicherordner öffnen. Ein Import fragt vor dem Ersetzen nach und sichert den aktuellen Stand als `spielstand.vor_import.json`.

Die Browser-Version benutzt ein anderes Format; ihr Fortschritt wird nicht automatisch übernommen. Bedürfnisse sinken langsam mit der Zeit, wobei Pausen auf höchstens acht Stunden begrenzt werden. Tiere können nicht sterben. Zucht, Freunde, Online-Konten und Mehrspielerfunktionen sind noch nicht enthalten.

## Cloud-Entwicklung und Prüfungen

Im vorhandenen Checkout arbeiten; die Cloud-Aufgabe ist bereits isoliert. Ohne ausdrücklichen Wunsch keinen weiteren Git-Worktree erstellen.

```bash
cd /workspace/happypets-remake.
bash tools/setup-godot.sh
```

Das Skript nutzt den vorinstallierten Godot-Editor 4.6.3, importiert Ressourcen, prüft Spielregeln und Szeneninteraktionen, baut Windows und Linux und startet den Linux-Export zur Kontrolle. Die offiziellen Exportvorlagen werden gegen die fest hinterlegte SHA-512-Prüfsumme der Godot-Veröffentlichung geprüft und anschließend wiederverwendet. Der erste Download umfasst etwa 1,26 GB.

Godot-Daten und Caches liegen in `/workspace/.pfotenstube-runtime/`. Tests bekommen ein separates temporäres Datenverzeichnis und verändern keine Spielerstände. `tools/package_windows.py` erzeugt die beiden ZIP-Pakete unter `exports/` und prüft die Windows-x64-EXE, das eingebettete Ressourcenpaket und die Archivintegrität. SHA-256-Dateien liegen neben den ZIPs.

Grafische Prüfung mit einem verfügbaren X11-Display:

```bash
DISPLAY=:87 LIBGL_ALWAYS_SOFTWARE=1 \
XDG_DATA_HOME=/tmp/pfotenstube-godot-capture \
XDG_CONFIG_HOME=/workspace/.pfotenstube-runtime/config \
XDG_CACHE_HOME=/workspace/.pfotenstube-runtime/cache \
godot --path godot --rendering-method gl_compatibility \
  --audio-driver Dummy --disable-vsync --script tests/capture.gd
```

Sie prüft die tatsächliche Darstellung und einen Maus-Klick auf **Füttern** und erzeugt Screenshots von Zimmer und Shop unter `/tmp/`. In einer normalen Desktop-Umgebung startet `godot --path godot --editor` den Editor. In einer Cloud ohne sichtbare Desktop-Sitzung entsteht dadurch kein Spielzugang für Nutzer.

Mit `--script tests/capture_cat.gd` werden zusätzlich der Weg zum Napf, das Fressen am vorhandenen Napf und je 24 Ansichten und Übergänge aller neun Bewegungszustände in beiden Blickrichtungen gerendert. Die Dateien liegen unter `/tmp/cat-*.png`. `python3 godot/tests/check_cat_renders.py` prüft mit Pillow die 864 gerenderten Figuren auf abgetrennte Körperteile, Duplikate und abgeschnittene Ränder. Die alten automatisch geschnittenen Katzen-Sheets werden nicht mehr benutzt oder in die EXE exportiert.

## Projektstruktur

- `main.tscn`: Hauptszene.
- `scripts/game_state.gd`: Spielregeln, Kataloge, Datenprüfung und Dateispeicherung.
- `scripts/main.gd`: native Godot-Oberfläche, Dialoge und Aktionen.
- `scripts/room.gd`: Zimmer, Einrichtung sowie Maus- und Tastatursteuerung.
- `scripts/pet_actor.gd`: bewegliche Tierfiguren und Reaktionen.
- `scripts/cat_rig.gd`: kontinuierliche Posen, Übergänge und festgelegte Bildbereiche für die graue Katze.
- `assets/`: SVG-Grafiken und freigestellte Katzen-Körperteile, ohne React zur Laufzeit.
- `tests/run_tests.gd`: Spielregeln, Dateien und Szeneninteraktionen.
- `export_presets.cfg`: Windows-x64-Export und Linux-Kontrollbuild.
- `licenses/`: Lizenzhinweise der mitgelieferten Godot-Engine.
