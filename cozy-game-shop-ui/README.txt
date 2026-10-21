Shop-Icon – Version 4: breiterer und dezenterer Konturschein

WICHTIG: Dateien auf GitHub aktualisieren dein Godot-Projekt auf deinem Windows-PC nicht automatisch. Dieses Paket muss zuerst in dein vorhandenes Projekt kopiert werden.

SO SETZT DU DIE DATEIEN EIN

1. Godot schließen.
2. Die heruntergeladene ZIP mit Rechtsklick > Alle extrahieren entpacken.
3. Deinen vorhandenen Spielordner öffnen. Im richtigen Ordner liegt die Datei project.godot. Dort sind bereits die Ordner assets und scenes vorhanden.
4. Aus dem entpackten Paket die beiden Ordner assets und scenes genau dorthin kopieren. Bestehende Ordner zusammenführen und die mitgelieferten gleichnamigen Dateien ersetzen. Nicht die kompletten vorhandenen Ordner löschen. Es darf kein zusätzlicher Ordner assets/assets oder scenes/scenes entstehen.
5. Dein Projekt wieder in Godot öffnen und den Import abwarten.
6. Mit F5 das gesamte Projekt starten. F6 startet nur eine einzelne Szene; dort ist das HUD möglicherweise nicht enthalten.

Die mitgelieferte scenes/main/main/main.tscn basiert auf deinem hochgeladenen Spielstand und ergänzt dort den ShopButton. Das Paket enthält die vollständige Shop-Icon-Ergänzung; Versionen 1 bis 3 müssen nicht vorher eingesetzt werden.

WAS DU SEHEN SOLLTEST

Unten links erscheint dein Korb mit einer 200 x 200 UI-Pixel großen Grafik und einem breiten, zurückhaltenden, weich auslaufenden Konturschein. Die helle rechteckige Hintergrundfläche ist entfernt. Das Icon bleibt beim Bewegen der Raumkamera an derselben Stelle. Ein Shop-Fenster öffnet sich noch nicht.

ORDNERSTRUKTUR

assets/UI/hud/bottom_bar/shop_icon.png
assets/UI/shaders/soft_icon_glow.gdshader
assets/UI/shaders/soft_icon_glow.gdshader.uid
scenes/UI/hud/components/shop_button.tscn
scenes/main/main/main.tscn

Die PNG ist unverändert. Der neue Effekt entsteht im Shader; die Unschärfe reicht jetzt bis zu 20 statt 8 UI-Pixeln und leuchtet deutlich schwächer.

Godot 4.7.2: Projektstart und Positionierung in vier Fenstergrößen geprüft. Der neue Webexport wurde zusätzlich im Browser geprüft.
