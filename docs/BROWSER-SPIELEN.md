# Pfotenstube im Browser

## Einmalig einschalten

1. [GitHub Pages öffnen](https://github.com/aggroturtle67/happypets-remake./settings/pages).
2. Unter **Build and deployment → Source** die Option **Deploy from a branch** wählen.
3. Bei **Branch** den Branch **gh-pages** und daneben **/(root)** auswählen.
4. **Save** anklicken. GitHub stellt die Seite anschließend bereit; das kann einige Minuten dauern.
5. [Pfotenstube öffnen](https://aggroturtle67.github.io/happypets-remake./).

Danach immer dieselbe Spieladresse verwenden. Neue Spielversionen brauchen nur ein Neuladen im Browser, keinen ZIP-Download. Das Spiel bleibt ein Godot-Spiel; die frühere React-Version wird hier nicht verwendet.

## Spielstand

Der Fortschritt wird automatisch in diesem Browser gespeichert und bleibt bei Spielupdates erhalten. Ein anderer Browser oder ein anderes Gerät hat einen eigenen Spielstand. Beim Löschen der Browserdaten wird der lokale Stand entfernt.

Unter **Hilfe → Spielstand exportieren** kann eine JSON-Sicherung heruntergeladen werden. Mit **Spielstand importieren** lässt sie sich wieder einlesen.

Wer bereits die Windows-Version gespielt hat, kann dort unter **Hilfe → Spielstand exportieren** eine Sicherung erstellen und sie im Browserspiel importieren. Die Browser-Version startet sonst mit einem neuen Spielstand. Der vorhandene Windows-Spielstand wird nicht verändert.

## Entwicklung

```bash
bash tools/build-web.sh
python3 -m http.server 8063 --bind 127.0.0.1 --directory godot/builds/web
```

In einem zweiten Terminal prüft `node tools/test-web.mjs` den tatsächlichen Godot-Web-Export in Chromium: Spielstart, Füttern, Export und Import, ungültige Dateien und Speichern nach Neuladen sowie einem simulierten Wechsel der Programmdateien. Die Browserdaten des Nutzers werden dabei nicht berührt.

Nach erfolgreicher Prüfung veröffentlicht `bash tools/publish-web.sh --no-build` den aktuellen Export auf dem dafür vorgesehenen Branch. Programmdateien tragen eine Versionskennung. Die vorherige Version ihrer Dateien bleibt für bereits offene Seiten kurzzeitig verfügbar; Service Worker werden nicht verwendet. Die einmalige Pages-Einstellung muss bei Updates nicht wiederholt werden.
