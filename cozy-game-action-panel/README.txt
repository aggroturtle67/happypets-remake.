Aktionspanel – Maus, Futtersack und Schaufel

BEDIENUNG

Das Panel sitzt unten rechts. Klicke den entsprechenden Bereich der Grafik an:
- Pfeil/Maus: Gegenstände auswählen und die Katze durch Anklicken streicheln. Das Streicheln bestätigt ein kurzer Herz-Hinweis. Die Katzenanimationen werden nicht verändert.
- Futtersack: Den Napf anklicken, um ihn vollständig aufzufüllen.
- Schaufel: Das Katzenklo anklicken, um es vollständig zu reinigen.

Der Cursor wird zum gewählten Werkzeug. Nach einer erfolgreichen Futter- oder Reinigungsaktion wechselt er automatisch zurück zur Maus. Ein falsches Ziel verändert nichts; das Werkzeug bleibt ausgewählt. Bei einem bereits vollen Napf bzw. sauberen Klo erscheint ein Hinweis und das Werkzeug bleibt ebenfalls ausgewählt. Mit Escape kannst du jederzeit zur Maus zurückwechseln.

Für die erste Testversion startet der Napf halbvoll und das neu eingebundene Klo verschmutzt. Die oberen Bedürfnisbalken sind weiterhin die bisherigen Anzeigen des Projekts; sie sind nicht an den Napffüllstand oder die Klo-Verschmutzung gekoppelt.

EINBAU IN DEIN LOKALES GODOT-PROJEKT

GitHub aktualisiert die Dateien auf deinem PC nicht automatisch.

1. Godot schließen und diese ZIP entpacken.
2. Die vier Ordner assets, data, scenes und scripts aus dem Paket in deinen vorhandenen Spielordner kopieren, direkt neben project.godot. Ordner zusammenführen und die mitgelieferten gleichnamigen Dateien ersetzen. Keine vollständigen vorhandenen Ordner löschen.
3. Dein Projekt wieder in Godot öffnen und den Import abwarten.
4. Im Dateisystem-Dock scripts/tools/install_action_panel.gd doppelt anklicken. Im Script-Editor Strg + Umschalt + X drücken, um das Einbau-Skript auszuführen. Es ergänzt die Hauptszene und meldet unten im Ausgabefenster: Aktionspanel eingebaut.
5. Mit F5 das gesamte Projekt starten.

WICHTIG ZU DEINER SHOP-POSITION

Deine Hauptszene wird absichtlich nicht als Ersatzdatei mitgeliefert. Das Einbau-Skript ergänzt nur die neuen Knoten und behält die vorhandenen Werte deines ShopButtons bei, einschließlich der von dir selbst geänderten Position. Falls der ShopButton noch gar nicht eingebaut ist, ergänzt das Skript auch diesen. Das Skript kann erneut ausgeführt werden und erzeugt keine doppelten Panels.

ORDNER

assets/UI/hud/action_panel/action_panel.png – deine unveränderte Panel-Grafik
assets/UI/cursors/ – deine unveränderten Cursor-PNGs
scenes/UI/hud/action_panel/action_panel.tscn – Panel-Szene
scripts/ui/hud/action_panel/action_panel.gd – Bedienung und Bereichsauswahl
scripts/interactions/interaction_controller.gd – Zielprüfung, Cursor und Aktionen
scripts/tools/install_action_panel.gd – Einbau im Godot-Editor

data/needs/litter_boxes/litter_box_basic.tres ergänzt das vorhandene Katzenklo. Seine Szene und der RoomManager sind für die Platzierung im Raum mitgeliefert. Die vorhandenen Katzenanimationsdateien sind unverändert.

GEPRÜFT

Godot 4.7.2: echte Eingabeklicks auf Panel, Napf, Klo und Katze; falsche Ziele; Rückwechsel zur Maus; bereits volle/saubere Ziele; vier Fenstergrößen; Kameraunabhängigkeit. Der Einbau wurde mit eigener Shop-Position, erneutem Ausführen und Speichern/Laden der Szene geprüft. Im Browser wurden drei verschiedene Cursor und beide Aktionen mit echtem Mausinput geprüft.
