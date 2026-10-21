Shop-Icon für dein hochgeladenes CozyGame-Clean-Projekt

Die Ordner assets und scenes aus diesem Paket in deinen vorhandenen Projektordner kopieren (dort, wo project.godot liegt). Die mitgelieferte main.tscn ersetzt die hochgeladene Fassung und ergänzt ausschließlich den ShopButton.

Dateien:
- assets/UI/hud/bottom_bar/shop_icon.png: deine unveränderte PNG-Grafik
- scenes/UI/hud/components/shop_button.tscn: eigenständiger UI-Baustein
- scenes/main/main/main.tscn: Einbindung im bestehenden HUD

Das Icon sitzt unten links, ist 144 x 144 UI-Pixel groß und hat links sowie unten 32 UI-Pixel Randabstand. Die Grafik behält ihre Proportionen. Das HUD bleibt unabhängig von der Raumkamera. Der Shop öffnet noch kein Fenster und führt keine Käufe aus.

Godot 4.7.2: Import sowie Start geprüft. Platzierung bei 1920x1080, 1280x720, 800x600 und 2560x1440 geprüft.
