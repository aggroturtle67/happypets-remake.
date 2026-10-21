Shop-Icon für dein hochgeladenes CozyGame-Clean-Projekt

Die Ordner assets und scenes aus diesem Paket in deinen vorhandenen Projektordner kopieren (dort, wo project.godot liegt). Die mitgelieferte main.tscn ersetzt die hochgeladene Fassung und ergänzt ausschließlich den ShopButton.

Dateien:
- assets/UI/hud/bottom_bar/shop_icon.png: deine unveränderte PNG-Grafik
- scenes/UI/hud/components/shop_button.tscn: eigenständiger UI-Baustein
- scenes/main/main/main.tscn: Einbindung im bestehenden HUD

Das Icon sitzt unten links, zeigt die Grafik mit 200 x 200 UI-Pixeln auf einer cremefarbenen, abgerundeten Fläche von 232 x 232 UI-Pixeln mit dezentem Schatten. Der Randabstand links und unten beträgt weiterhin 32 UI-Pixel. Die Grafik behält ihre Proportionen. Das HUD bleibt unabhängig von der Raumkamera. Der Shop öffnet noch kein Fenster und führt keine Käufe aus.

Godot 4.7.2: Import sowie Start geprüft. Platzierung bei 1920x1080, 1280x720, 800x600 und 2560x1440 geprüft.
