## 1. Tabelle

- [x] 1.1 Tabelle 60318 "CXW Workshop Line" (`src/Tables/Tab60318.CXWWorkshopLine.al`): Caption von Feld 11 `"CXW Attribute 1"` von 'Attribut 1' auf 'Dial Color' ändern.
- [x] 1.2 Feld 12 `"CXW Attribute 2"`: Caption auf 'Case Diameter' ändern.
- [x] 1.3 Feld 13 `"CXW Attribute 3"`: Caption auf 'Bracelet Material' ändern.
- [x] 1.4 Feld 14 `"CXW Attribute 4"`: Caption auf 'Case Material' ändern.
- [x] 1.5 Feld 15 `"CXW Attribute 5"`: Caption auf 'Movement' ändern.
- [x] 1.6 Feld 16 `"CXW Attribute 6"`: Caption auf 'Gender' ändern.
- [x] 1.7 Feld 17 `"CXW Attribute 7"`: Caption auf 'Crystal' ändern.
- [x] 1.8 Feld 18 `"CXW Attribute 8"`: Caption auf 'Features' ändern.
- [x] 1.9 Felder 19/20 (`"CXW Attribute 9"`/`"CXW Attribute 10"`) unverändert gelassen (weiterhin 'Attribut 9'/'Attribut 10').
- [x] 1.10 Kommentar oberhalb der Felder auf `// TODO: Attributnamen für Attribut 9/10 final klären - Platzhalter-Captions "Attribut 9"-"Attribut 10"` angepasst.

## 2. Verarbeitung

- [x] 2.1 Codeunit 60331 "CXW Process Workshop Lines" (`src/Codeunits/Codeunit60331.CXWProcessWorkshopLines.al`), Prozedur `GetAttributeMapping`: Rückgabewerte für Index 1–8 auf 'Dial Color', 'Case Diameter', 'Bracelet Material', 'Case Material', 'Movement', 'Gender', 'Crystal', 'Features' geändert; Index 9/10 unverändert 'Attribut 9'/'Attribut 10'.
- [x] 2.2 Kommentar oberhalb der Prozedur auf `// TODO: Attributnamen für Attribut 9/10 final klären (Platzhalter!) - zentrale Zuordnung WL-Feld -> Item-Attribute-Name.` angepasst.

## 3. Übersetzungen

- [x] 3.1 `Translations/CHX.Webshop.g.xlf` per `al compile` regeneriert (enthält die 8 neuen Captions als Quelltext). `Translations/CHX.Webshop.de-DE.xlf` per `managing-bc-translations`-Skill synchronisiert: Quelltext und deutsche Übersetzung für alle 8 Felder aktualisiert (Dial Color → Zifferblattfarbe, Case Diameter → Gehäusedurchmesser, Bracelet Material → Armbandmaterial, Case Material → Gehäusematerial, Movement → Werk, Gender → Geschlecht [BC-Standardbegriff, analog Employee-Tabelle], Crystal → Glas, Features → Ausstattung). 436/436 Trans-Units zwischen g.xlf und de-DE.xlf abgeglichen, keine NAB-Reste, valides XML.

## 4. Dokumentation

- [x] 4.1 `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md` und `docs/funktionsregister/gesamtuebersicht.md` aktualisiert: Tab60318-Beschreibung und `GetAttributeMapping`-Beschreibung spiegeln die acht fachlichen Attributnamen wider, Changelog-Zeilen ergänzt.

## 5. Prüfung

- [x] 5.1 AL-Extension kompiliert fehlerfrei — verifiziert per `al compile` (Microsoft AL Compiler 18.0.37.11445) gegen `.alpackages`: 50/50 Dateien, 0 Fehler, 1 vorbestehende Warnung (AL0603, Codeunit60330, nicht Teil dieser Änderung).
- [x] 5.2 Code-Pfad statisch geprüft (kein Live-BC verfügbar): In `ProcessGenuineLine` wird `GetAttributeMapping(AttributeIndex)` mit demselben `AttributeIndex` wie `GetWorkshopLineAttributeValue` aufgerufen — Index 1 liefert korrekt "Dial Color" für `CXW Attribute 1`, durchgängig bis Index 8/"Features". Mapping ist korrekt 1:1 verdrahtet.
