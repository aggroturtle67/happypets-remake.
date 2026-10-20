# Entwicklung und Testzugang

- Das aktuelle Spiel ist `godot/` (Godot 4.6.3, GDScript). Die React-Dateien bleiben als früherer Prototyp erhalten.
- Der Nutzer möchte Änderungen über eine feste Browseradresse testen und nicht mehr für jede Version ZIP-Dateien herunterladen und entpacken.
- Standard-Testzugang: `https://aggroturtle67.github.io/happypets-remake./`. Der dafür reservierte Branch `gh-pages` enthält ausschließlich erzeugte Godot-Webdateien. GitHub Pages benötigt einmalig die Einstellung `Deploy from a branch`, `gh-pages`, `/(root)`.
- Nach beauftragten Spieländerungen: sinnvolle Prüfungen ausführen, mit `bash tools/build-web.sh` bauen, den tatsächlichen Web-Export prüfen und mit `bash tools/publish-web.sh --no-build` auf dieselbe Adresse aktualisieren. Veröffentlichung nur als erfolgt melden, wenn der Push bestätigt ist; bei noch fehlender Pages-Aktivierung den offenen Schritt benennen.
- Versionierte Asset-Namen vermeiden, dass beim Neuladen alte Bild- oder Programmdateien mit neuen vermischt werden. Keine Service-Worker-Zwischenspeicherung einschalten. Der Spielstand muss bei Updates im selben Browser erhalten bleiben.
- Für Browserprüfungen den erzeugten Ordner `godot/builds/web` lokal per HTTP bereitstellen und `node tools/test-web.mjs` ausführen. Diese Tests verwenden einen eigenen Browserkontext und verändern keine echten Spielstände.
- Weiterhin im vorhandenen Checkout arbeiten; keine zusätzlichen Worktrees ohne ausdrücklichen Wunsch. Bestehende Spielstände und den bisherigen Windows-Download erhalten.
