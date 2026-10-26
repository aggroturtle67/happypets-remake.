# Pflegebelohnungen: Aufbau und Pruefung

- `scripts/managers/game_manager.gd`: `award_care(points, kind, source)` berechnet die Differenz der **kumulierten ganzen** XP/Coins vor/nach der vorhandenen Rechnung. Auch ein Levelwechsel kann die XP-Differenz daher nicht verfaelschen. Nur positive echte Differenzen erzeugen ein Ereignis. Die gespeicherten Restzaehler bleiben erhalten. Der kombinierte Snapshot wird vor UI-Beobachtern und vor dem Ereignis gespeichert. Fremde Level-Boni aus Signal-Callbacks werden nicht in die Pflege-Differenz einbezogen.
- `care_reward_credited(event_id, kind, source, coins, xp)` ist der eigene UI-Kanal. `add_xp`, `change_coins`, Levelwechsel und `restore_progress` senden ihn nicht. Die fortlaufende ID verhindert doppelte visuelle Verarbeitung.
- Nur die vorhandenen Reward-Aufrufe in Clean, echtem Fressen und wirksamem Streicheln erhalten ihren jeweiligen Quellknoten. Die Bedarfsmengen, Futterportionen, Schwellen und Belohnungsraten wurden nicht geaendert.
- `scripts/interactions/interaction_controller.gd` haengt die modulare Szene `scenes/UI/rewards/reward_presenter.tscn` einmal an das bestehende HUD. Die Hauptszene und ihre Positionen werden nicht ersetzt.
- `reward_presenter.gd`: kurze quellbezogene Buendelung, werttreue Warteschlange, freie Bodenplaetze, Kameraprojektion, Hover, UI-Ziele, Pulse und genau zwei Plus-Anzeigen. Eine Mischung benoetigt nur zwei ganzzahlige Zaehler; hohe Werte erzeugen keine riesigen Symbol-Arrays. Ein begrenztes Starttempo pro Frame ist eine Leistungssteuerung, kein Wert-/Symbollimit. Ist der sichtbare Boden belegt, bleiben alle restlichen Werte in der Warteschlange.
- `reward_value_plan.gd`: verlustfreie zufaellige Zerlegung in Einer/Zweier. Fuer Werte ab3 gibt es mindestens einen Einer und einen Zweier.
- `reward_token.gd` / `reward_token.tscn`: Flug, Nachfedern, seltener Schimmer, atomarer Statuswechsel beim Hover, Aufloesen und Partikelflug. Kein Zugriff auf GameManager, Bedarfswerte oder Save-Dateien. Erst die letzte Partikelankunft bestaetigt den Symbolwert einmal an die Anzeige.
- `reward_plus.gd`: unabhaengiger Coin-/XP-Akkumulator mit abbrechbarer Ausblendung. Neue Werte waehrend der Ausblendung erhalten die bestehende Summe. Nach abgeschlossener Inaktivitaetsphase beginnt eine neue Serie.
- `data/UI/reward_effects.tres`: alle tunbaren Werte und sechs austauschbare Originaltexturen. Die Bilddateien selbst bleiben unveraendert. Der Shader nutzt die Originaltextur fuer leichtes Leuchten und Alpha-Aufloesung; die fliegenden Partikel verwenden deine zusaetzlichen goldenen/blauen PNGs ohne Umfaerbung.

## Koordinaten und Aufraeumen

Quellknoten sind Node2D-Objekte der aktiven Raum-Canvas. Ihre Weltposition wird ueber die Raum-Canvas und die inverse HUD-Canvas in logische UI-Pixel umgerechnet. Landepunkte werden wieder als Weltposition gespeichert und beim Kameraschwenk projiziert. Waehrend der Einsammlung loest sich das Symbol von der Welt und seine Partikel verfolgen die aktuellen UI-Ziele. Die zwei UI-Ziele werden je Renderframe neu bestimmt und von allen Partikeln gemeinsam genutzt; Fensteraenderungen verschieben sie korrekt. Rootfenster-Stretch wird von Godot uebernommen.

HUD-Rechtecke werden einmal pro Frame gesammelt. Ein Platzraster mit zufaelligem Versatz und raeumlichen Abstandsbuckets verhindert dichte Ueberlagerungen und vermeidet Bodenfremdflaechen, HUD und das Quellobjekt. Die Rasterbelegung wird auch nach Kamerabewegungen aus den wirklichen Weltpositionen neu aufgebaut. Alle Controls der Effekte ignorieren Mausklicks, bestehende Aktions- und Streichelsteuerung funktioniert weiter.

Quellknoten sind schwach referenziert, Fluege haben einen letzten gueltigen Ursprung. Beim Szenenwechsel werden Signalverbindung, Tweens, Partikel und Pulse aufgeraeumt. Nicht eingesammelte visuelle Belege werden nicht persistiert oder erneut ausgespielt; die echte Gutschrift wird schon vor dem ersten Symbol gespeichert.

Die drei UI-Zielpfade koennen im Inspektor der reward_presenter-Szene umgebunden werden, falls die Topbar spaeter umstrukturiert wird.

## Einstellungen

Godot-Inspektor: `data/UI/reward_effects.tres`. Distanzen sind logische Viewportpixel; die Fensterskalierung uebernimmt Godot.

| Gruppe | Wichtige Eigenschaften |
| --- | --- |
| Original artwork | `coin_single`, `coin_double`, `xp_single`, `xp_double`, `coin_particle`, `xp_particle` |
| Jump and landing | `flight_speed`, `flight_duration`, `flight_distance`, `scatter`, `jump_height`, `landing_bounce`, `symbol_size`, `size_variation`, `symbol_gap`, `land_on_room_floor` |
| Hover and collection | `magnet_radius`, `collection_duration`, `collection_jump`, `single_particles`, `double_particles`, `particle_speed`, `particle_duration`, `particle_size`, `particle_scatter` |
| UI feedback | `ui_pulse`, `plus_duration`, `plus_fade` |
| Grouping and performance | `batch_quiet_time`, `batch_max_time`, `spawn_interval`, `spawns_per_frame` |

## Automatische Tests

Projektpfad waehlen und mit Godot4.7 ausfuehren. Das Flag verhindert, dass die normalen Autoloads beim Teststart einen echten Offline-Spielstand fortschreiben. Test-Speicherdaten haben einen eigenen Namen.

Linux/macOS:

```sh
COZYGAME_TEST_MODE=1 godot --headless --path . --script res://tests/rewards/test_reward_collection.gd
```

Windows PowerShell (Godot-Programmpfad entsprechend einsetzen):

```powershell
$env:COZYGAME_TEST_MODE = "1"
& "C:\Godot\Godot_v4.7-stable_win64.exe" --headless --path . --script res://tests/rewards/test_reward_collection.gd
Remove-Item Env:COZYGAME_TEST_MODE
```

Geprueft werden alle drei echten Aktionspfade, kein FX bei Nachfuellen/anderen Quellen/Laden, exakte Werte bei Tausenden zufaelligen Symbolplaenen, Einer/Zweier/Mischungen, hohe Werte ohne Cap, Mehrfachereignisse, sofortiges Speichern, Boden/HUD-Platzierung, Kameraprojektion, Schimmer, naher Hover, doppelte Hover-Aufrufe, parallele Partikelankunft, unveraenderter Kontostand beim Einsammeln, Puls-Ruecksetzung, Plus-Summen inklusive Addition waehrend Fade, mehrere Fensteraspekte und Szenenwechsel ohne Verlust oder Wiederauszahlung.
