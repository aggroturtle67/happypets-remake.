Shop-Icon – Version 5: Originalgrafik ohne Outline

Die Grafik wird mit 200 x 200 UI-Pixeln unten links dargestellt. Outline, Leuchtschein und Hintergrundfläche sind vollständig entfernt. Die PNG bleibt unverändert. Ein Shop-Fenster öffnet sich noch nicht.

SO SETZT DU DIE DATEIEN IN DEIN LOKALES PROJEKT EIN

1. Godot schließen und die heruntergeladene ZIP entpacken.
2. Deinen vorhandenen Spielordner öffnen. Dort liegt die Datei project.godot.
3. Aus dem Paket die Ordner assets und scenes genau dorthin kopieren. Bestehende Ordner zusammenführen und die mitgelieferten gleichnamigen Dateien ersetzen. Nicht die vollständigen vorhandenen Ordner löschen.
4. Dein Projekt wieder in Godot öffnen, den Import abwarten und mit F5 das gesamte Spiel starten.

Dateien auf GitHub aktualisieren dein lokales Godot-Projekt nicht automatisch. Dieses Paket enthält den vollständigen Shop-Icon-Einbau; ältere Versionen müssen nicht vorher eingesetzt werden.

DATEIEN

assets/UI/hud/bottom_bar/shop_icon.png
scenes/UI/hud/components/shop_button.tscn
scenes/main/main/main.tscn

Die mitgelieferte main.tscn basiert auf deinem hochgeladenen Spielstand und ergänzt dort den ShopButton. Die Button-Szene verwendet keinen Glow-Shader mehr. Der Randabstand der 232 x 232 UI-Pixel großen transparenten Schaltfläche beträgt weiterhin 32 UI-Pixel links und unten. Die Grafik sitzt mit 16 UI-Pixeln Innenabstand darin, genau wie in den vorigen Versionen.

Godot 4.7.2: Projektstart und Platzierung bei mehreren Fenstergrößen geprüft. Webexport im Browser geprüft.
