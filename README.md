# Pfotenstube

Ein gemütliches 2D-Haustierspiel, inspiriert vom damaligen Happy Pets. **Die aktuelle Entwicklung verwendet Godot 4.6.3 und GDScript.** Der frühere React-Prototyp bleibt als Gestaltungsvorlage erhalten.

## Direkt im Browser spielen

[Pfotenstube öffnen](https://aggroturtle67.github.io/happypets-remake./). Die Godot-Version läuft direkt im Browser. Neue Versionen erscheinen unter derselben Adresse; zum Testen genügt Neuladen. ZIP-Dateien sind dafür nicht mehr erforderlich.

Die Webdateien liegen auf dem Branch `gh-pages`. GitHub Pages muss einmalig in den [Pages-Einstellungen](https://github.com/aggroturtle67/happypets-remake./settings/pages) auf **Deploy from a branch → gh-pages → /(root)** eingestellt und gespeichert werden. Die [Browser-Anleitung](docs/BROWSER-SPIELEN.md) beschreibt den Start und die Übernahme von Spielständen.

## Bisherige Windows-Testversion

1. [Pfotenstube für Windows herunterladen](https://github.com/aggroturtle67/happypets-remake./raw/refs/heads/downloads/Pfotenstube-Windows.zip).
2. Rechtsklick auf das ZIP → **Alle extrahieren**.
3. Im entpackten Ordner **Pfotenstube.exe** doppelklicken.

Du brauchst keinen Godot-Editor, kein Node.js und kein Konto. Enthalten sind Pflege, Streicheln, Adoption, Münzen, Level, Tagesziele, Möbel und lokale Spielstände. Der Windows-Export ist erstellt; ein tatsächlicher Windows-Lauf wurde in dieser Linux-Cloud nicht geprüft.

![Die aktuelle Godot-Version der Pfotenstube](docs/godot-screenshot.png)

## Mit Godot weiterarbeiten

Im Godot-Projektmanager [godot/project.godot](godot/project.godot) importieren und **F5** drücken. Alternativ den [Quellcode als ZIP](https://github.com/aggroturtle67/happypets-remake./archive/refs/heads/main.zip) herunterladen, entpacken und darin `godot/project.godot` importieren.

Die [Godot-Anleitung](godot/README.md) beschreibt Bedienung, Speicherort und Prüfungen. Die Cloud-Einrichtung wird mit `bash tools/setup-godot.sh` wiederholt; daraus entstehen auch die beiden ZIP-Pakete unter `exports/`.

Der Standard zum Testen ist der Web-Export: `bash tools/build-web.sh` erstellt ihn, `bash tools/publish-web.sh --no-build` veröffentlicht den geprüften Stand auf `gh-pages`.

Das Spiel ist ein erster Prototyp. Zucht, Freundesbesuche, Konten und Mehrspielerfunktionen sind noch nicht enthalten. Grafiken und Name sind eigenständig; eine Facebook-Verbindung gibt es nicht.

## Früherer Browser-Prototyp

`src/`, `public/`, `tests/` sowie die npm-/Vite-Konfiguration gehören zur früheren Browser-Version. Sie werden für die Godot-Version nicht benötigt. Ihre Anleitung steht unter [docs/WEB-PROTOTYP.md](docs/WEB-PROTOTYP.md). Ihre Spielstände sind nicht mit dem Godot-Format kompatibel.
