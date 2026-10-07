## Why

Die Uhrendaten, die SellWatch strukturiert liefert (Marke, Modell, Referenz, Baujahr, Zustand, Box, Papiere, Besteuerung, Geschlecht), landen heute nur als Text in der Artikelbeschreibung, nicht als Artikelattribute. Dadurch kommen bei SellWatch-Uhren auf der Werkstattzeile leere Stammdaten an (Marke, Modell, … werden dort per Attribut-ID gelesen). Zugleich ordnet die Werkstatt ihre zehn Prüfmerkmale über englische Attributnamen zu („Dial Color“, „Gender“ …), die es in BC nicht gibt: die Vorbelegung funktioniert nur über die ChronextBC-Ersatz-IDs, und das Rückschreiben legt bei der ersten Verarbeitung neue englische Text-Attribute an, statt die vorhandenen deutschen Attribute zu füllen.

Zielbild: Attribute eines SellWatch-Artikels werden automatisch durch die SellWatch-Anlage und durch die Werkstatt geschrieben; bei manuell angelegten Artikeln werden sie manuell gepflegt.

## What Changes

- **SellWatch-Artikelanlage schreibt Artikelattribute:** `CreateSellWatchItem` trägt nach Anlage des Artikels die Werte aus der SellWatch-Anfrage in die Artikelattribute ein (per Attribut-ID): Marke → 1, Modell → 2, Referenz → 5, Baujahr → 8 Jahr, Zustand → 10, Box vorhanden → 11 Box (ja/nein), Papiere vorhanden → 13 Zertifikat (ja/nein), Besteuerung → 12, Geschlecht → 24. Leere Werte werden übersprungen; ein nicht ganzzahliges Baujahr wird übersprungen, ohne die Angebotsverarbeitung abzubrechen.
- **Werkstatt-Zuordnung über Attribut-IDs statt Namen:** Die Prüfmerkmale der Werkstattzeile werden fest auf die vorhandenen Attribute gemappt: Dial Color → 22 Zifferblatt Farbe 1, Case Diameter → 18 Gehäuse Größe, Bracelet Material → 23 Armband Material, Case Material → 16 Gehäuse Material, Movement → 15 Werk, Gender → 24 Geschlecht, Crystal → 20 Glas. Vorbelegung und Rückschreiben nutzen dieselbe ID.
- **Platzhalter:** „Features“, „Attribut 9“ und „Attribut 10“ haben (noch) kein Attribut. Sie bleiben auf der Werkstattzeile und in der API bestehen, werden aber weder vorbelegt noch zurückgeschrieben, bis ihnen eine Attribut-ID zugeordnet wird.
- **BREAKING (Verhalten):** Die Ersatz-Logik (ChronextBC-Fallback, „unveränderter Ersatzwert wird nicht zurückgeschrieben“) entfällt. Ein von der Werkstatt unverändert bestätigter Wert wird nun in dasselbe Attribut zurückgeschrieben, aus dem er vorbelegt wurde (keine Wertänderung). Es werden keine neuen Attribute mehr angelegt.
- Unbekannte Werte bei Options-Attributen werden wie bisher als neuer Attributwert angelegt (SellWatch und Werkstatt).
- Die Schreib-Logik für Attributwerte wird in Codeunit 60335 zusammengeführt und von SellWatch und Werkstatt gemeinsam genutzt.
- **Seriennummernverfolgung für SellWatch-Artikel:** Jeder SellWatch-Artikel muss mit Seriennummernverfolgung angelegt werden. Der Artikelverfolgungscode wird an den beiden SellWatch-Artikelvorlagen eingerichtet; vor der Artikelanlage wird geprüft, dass die zuständige Vorlage einen Code mit Seriennummernverfolgung beim Einkauf hat, sonst bleibt das Angebot mit Fehler offen. Damit scheitert eine falsch eingerichtete Vorlage sofort bei der Anlage statt erst bei „Send to Workshop“.

## Capabilities

### New Capabilities
- `sellwatch-item-attributes`: Übernahme der Uhrendaten einer SellWatch-Anfrage in die Artikelattribute des neu angelegten Artikels.

### Modified Capabilities
- `sellwatch-item-template-setup`: neue Anforderung – die SellWatch-Artikelvorlage muss einen Artikelverfolgungscode mit Seriennummernverfolgung haben.
- `workshop-line-attribute-prefill`: Zuordnung der Prüfmerkmale über feste Attribut-IDs statt Namen, Wegfall der Ersatz-Logik, Platzhalter ohne Attribut werden weder vorbelegt noch zurückgeschrieben, Rückschreiben legt keine Attribute mehr an.

## Impact

- `src/Codeunits/Codeunit60305.CXWSellWatchMgt.al` – Attributübernahme in `CreateSellWatchItem`.
- `src/Codeunits/Codeunit60335.CXWWorkshopLineMgt.al` – ID-Mapping, gemeinsame Schreibprozedur, Wegfall von `GetWorkshopAttributeName`/`GetWorkshopAttributeFallbackId`/`IsUnchangedFallbackValue`/`FindItemAttributeId`.
- `src/Codeunits/Codeunit60331.CXWProcessWorkshopLines.al` – Rückschreiben über ID, lokale Schreibprozeduren entfallen.
- `src/Pages/Pag60338.CXWWorkshopLines.al` – ToolTips der Prüfmerkmale (beschreiben heute die Ersatz-Logik); Übersetzungen.
- Permission Sets: SellWatch-Verarbeitung braucht Schreibrechte auf „Item Attribute Value“/„Item Attribute Value Mapping“.
- Keine Datenmigration (in Produktion existieren keine englischen Attribute).
- Doku: Benutzer-/Key-User-Handbuch (Werkstatt, SellWatch), Funktionsregister.
