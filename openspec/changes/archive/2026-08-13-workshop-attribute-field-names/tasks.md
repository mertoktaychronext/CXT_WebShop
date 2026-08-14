## 1. Datenmodell

- [x] 1.1 Tabelle 60318 "CXW Workshop Line" (`src/Tables/Tab60318.CXWWorkshopLine.al`): Feld 11 von `"CXW Attribute 1"` auf `"CXW Dial Color"` umbenannt (Feld-ID, Caption, DataClassification unverändert).
- [x] 1.2 Feld 12: `"CXW Attribute 2"` → `"CXW Case Diameter"`.
- [x] 1.3 Feld 13: `"CXW Attribute 3"` → `"CXW Bracelet Material"`.
- [x] 1.4 Feld 14: `"CXW Attribute 4"` → `"CXW Case Material"`.
- [x] 1.5 Feld 15: `"CXW Attribute 5"` → `"CXW Movement"`.
- [x] 1.6 Feld 16: `"CXW Attribute 6"` → `"CXW Gender"`.
- [x] 1.7 Feld 17: `"CXW Attribute 7"` → `"CXW Crystal"`.
- [x] 1.8 Feld 18: `"CXW Attribute 8"` → `"CXW Features"`.
- [x] 1.9 Felder 19/20 (`"CXW Attribute 9"`/`"CXW Attribute 10"`) unverändert gelassen.

## 2. Referenzen anpassen

- [x] 2.1 Codeunit 60331, `GetWorkshopLineAttributeValue`: alle 8 Referenzen auf die neuen Feldbezeichner umgestellt (Case 9/10 unverändert).
- [x] 2.2 Page 60338: die 8 Feld-Steuerelemente auf die neuen Feldbezeichner umgestellt (Control-Name und Rec-Referenz).
- [x] 2.3 Page 60339 "CXW Workshop Line API": nur die `Rec`-Referenzen auf die neuen Feldbezeichner umgestellt — OData-Eigenschaftsnamen `attribute1`–`attribute8` unverändert (verifiziert).
- [x] 2.4 Geprüft: keine verbleibenden Referenzen auf `"CXW Attribute 1"`–`"CXW Attribute 8"` im Projekt (`CXW Attribute [1-8]"` liefert keine Treffer mehr); `"CXW Attribute 9"`/`"CXW Attribute 10"` weiterhin vorhanden wie erwartet.

## 3. Prüfung

- [x] 3.1 AL-Extension kompiliert fehlerfrei — verifiziert per `al compile` (Microsoft AL Compiler 18.0.37.11445): 50/50 Dateien, 0 Fehler, 1 vorbestehende Warnung (AL0603, Codeunit60330, nicht Teil dieser Änderung).
- [x] 3.2 **Wichtiger Fund**: Die Annahme aus design.md ("Trans-Unit-IDs basieren auf Feld-ID, nicht auf AL-Namen") war falsch — die IDs basieren auf einem Hash, der den AL-Feld-/Control-Namen einschließt. Nach der Umbenennung hatten sich 16 Trans-Unit-IDs geändert (8 Table-Field-Captions + 8 Page-Control-ToolTips auf Page 60338). `de-DE.xlf` wurde entsprechend nachgezogen: für alle 16 betroffenen Einträge `id`-Attribut und "Xliff Generator"-Notiz auf die neuen Feldnamen aktualisiert, Source/Target-Text unverändert übernommen (gleiche Captions/ToolTips wie zuvor). 436/436 Trans-Units zwischen g.xlf und de-DE.xlf abgeglichen, keine leeren Targets, valides XML.
- [x] 3.3 Geprüft (statisch, kein Live-BC verfügbar): Page 60339 exponiert weiterhin `attribute1`–`attribute8` unter unverändertem OData-Eigenschaftsnamen, jetzt korrekt auf die neuen `Rec`-Felder verweisend.

## 4. Dokumentation

- [x] 4.1 Funktionsregister (`funktionsregister-sl-chronext-webshop.md`, `gesamtuebersicht.md`) geprüft: keine Stelle referenziert die AL-Feldbezeichner wörtlich (nur die bereits korrekten fachlichen Namen) — keine Änderung nötig.
