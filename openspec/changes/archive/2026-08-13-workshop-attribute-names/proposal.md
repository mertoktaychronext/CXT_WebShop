## Why

Tabelle "CXW Workshop Line" (60318) und Codeunit "CXW Process Workshop Lines" (60331) verwenden aktuell für alle zehn generischen Attributfelder die Platzhalter-Bezeichnung "Attribut 1"–"Attribut 10" (mit `// TODO: Attributnamen final klären`). Für acht der zehn Attribute liegen jetzt die tatsächlichen fachlichen Bezeichnungen vor, mit denen der Workshop die Uhren-Attribute meldet: `dial_color`, `case_diameter`, `bracelet_material`, `case_material`, `movement`, `gender`, `crystal`, `features`. Ohne diese Benennung sind weder die Spalten auf der Workshop-Line-Übersicht noch die daraus erzeugten Standard-Artikelattribute für Sachbearbeiter verständlich.

## What Changes

- Tabelle 60318 "CXW Workshop Line": Captions der Felder `CXW Attribute 1`–`CXW Attribute 8` von "Attribut 1"–"Attribut 8" auf die fachlichen Bezeichnungen umgestellt (Title-Case-Anzeigename, z. B. "Dial Color" für `dial_color`), gemäß dem bestehenden Caption-Stil der übrigen Tabellenfelder (Title Case statt snake_case). Felder `CXW Attribute 9` und `CXW Attribute 10` bleiben unverändert Platzhalter ("Attribut 9"/"Attribut 10"), da für sie noch keine fachliche Bezeichnung vorliegt.
- Codeunit 60331 "CXW Process Workshop Lines", Prozedur `GetAttributeMapping`: liefert für Index 1–8 dieselben fachlichen Bezeichnungen wie die neuen Feld-Captions (statt "Attribut 1"–"Attribut 8") als Name des zu befüllenden Standard-Artikelattributs; Index 9–10 liefern weiterhin "Attribut 9"/"Attribut 10".
- Kein Wechsel des AL-Feldbezeichners (`CXW Attribute 1` etc. bleibt unverändert) — nur Captions und die Mapping-Rückgabewerte ändern sich.
- Deutsche und englische Übersetzungseinträge für die acht neuen Captions ergänzen.

## Capabilities

### New Capabilities
(keine)

### Modified Capabilities
- `workshop-line-processing`: Die Anforderung "Übernahme der Attribute in Standard-Artikelattribute" wird um die konkrete Namenszuordnung für die ersten acht der zehn Attributfelder präzisiert (bisher nur Platzhalter). Diese Capability wurde im noch nicht archivierten Change `purchase-workshop-integration` eingeführt (`specs/workshop-line-processing/spec.md` dort); diese Änderung liefert dazu die Delta-Requirements.

## Impact

- **Geänderte Objekte**: Table 60318 "CXW Workshop Line" (8 Feld-Captions), Codeunit 60331 "CXW Process Workshop Lines" (Prozedur `GetAttributeMapping`).
- **Keine Datenmigration**: Es ändert sich nur die Anzeige-Bezeichnung und der bei künftigen Verarbeitungsläufen für neue "Item Attribute"-Datensätze verwendete Name; bereits angelegte "Item Attribute"-Datensätze mit dem Namen "Attribut 1"–"Attribut 8" aus vorherigen (Test-)Läufen werden dadurch nicht automatisch umbenannt oder migriert (siehe design.md).
- **Keine API-Vertragsänderung**: Die externe Workshop-API (Page 60339) exponiert weiterhin generische Felder `attribute1`–`attribute10`; nur die interne BC-seitige Bezeichnung/Zuordnung ändert sich.
- **Betroffen**: Übersetzungsdateien (`Translations/CHX.Webshop.g.xlf`, `Translations/CHX.Webshop.de-DE.xlf`), Funktionsregister-Dokumentation.
- **Weiterhin offen**: Fachliche Bezeichnung für Attribut 9 und 10 (bleibt `// TODO:`-markiert, wie im Basis-Change vorgesehen).
