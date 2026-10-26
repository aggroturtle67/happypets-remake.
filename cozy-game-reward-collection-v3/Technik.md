# Pflegebelohnungen v3

- Die Oekonomie und Speicherung bleiben gegenueber v2 unveraendert.
- Neue harte `landing_radius`-Grenze um die projizierte Objektposition, getrennt vom erhoehten Emitter. Kein raumweiter Fallback; belegte nahe Plaetze erzeugen Backpressure.
- Dichtere Platzierung mit `spacing_factor = 0.8`, `symbol_gap = 4`; Nachbarschaftsabstand wird weiterhin geprueft.
- Fertige Betraege >=6 erhalten immer mindestens zwei Einzel und zwei Doppel. Kontinuierliche Gutschriften werden pro Quelle/Aktionsart in einem laufenden Stream gepaart. Zwei erste Einzel werden sofort ausgespielt, danach Doppel. Uebrige einzelne Punkte werden nach4 ruhigen Sekunden ausgegeben. Es wird kein unverdienter Punkt vorweggenommen.
- Waehrungen und Quellen bleiben getrennt. IDs werden weiterhin dedupliziert. Queue, offene Restpunkte und aktive Symbole erhalten exakt die bereits verbuchte Summe.
- 32/48 statt24/36 Staubpartikel; XP-Staub0.85 Groessenfaktor und1.2 Helligkeitsfaktor. Original-PNGs unveraendert, bestehender gemeinsamer Shader weiterverwendet.
- Einstellungen: `data/UI/reward_effects.tres`, Resource-Skript `scripts/ui/rewards/reward_effects_settings.gd`.
- Regression: `godot --headless --path <Projekt> --script res://tests/rewards/test_reward_collection.gd` mit `COZYGAME_TEST_MODE=1`.
- Enthaltene Tests pruefen >=6-Mindestmischung, langsam eintreffende Einzelcredits, harte Maximaldistanz bei grossen Bursts, Queue-Wellen, Summenerhalt, Genau-einmal-Einsammeln, Partikel/UI und gespeicherte Gutschrift vor Szenenwechsel.
