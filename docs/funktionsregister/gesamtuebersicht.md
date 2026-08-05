# Gesamtübersicht – AL Funktionsregister

**Erstellt am:** 2026-08-05 (aktualisiert nach Senior-Dev-Cleanup, UI-Anbindung, Kommentar-Entfernung)
**Analysierte Projekte:** 1
**Gesamtanzahl Funktionen:** 34

---

## Projektübersicht

| Projekt | Version | Objekte | Prozeduren | Trigger | Events | Navigation/Actions | Gesamt |
|---|---|---|---|---|---|---|---|
| SL Chronext Webshop | 1.0.0.0 | 18 | 8 | 19 | 1 | 6 | 34 |
| **Gesamt** | – | **18** | **8** | **19** | **1** | **6** | **34** |

---

## Alle Funktionen – Vollständige Tabelle

| Projekt | Objekt | Objekttyp | Funktion | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|---|---|
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `Accept New Setup – OnValidate` | Trigger | – | Verhindert Freigabe eines Preises vor der Prüfung und sichert die Bemerkung. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `Country Code – OnValidate` | Trigger | – | Übernimmt bei Länderauswahl automatisch die hinterlegte Fremdwährung. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer der letzten Änderung beim Anlegen ein. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `OnModify` | Trigger | – | Setzt Prüf-/Freigabekennzeichen zurück, wenn Land oder Währung sich ändern. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `OnRename` | Trigger | – | Aktualisiert Datum/Benutzer bei Schlüsseländerung. |
| SL Chronext Webshop | SL Sales Price Archive | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer beim Archivieren eines Preises ein. |
| SL Chronext Webshop | SL Sales Price Archive | Tabelle | `OnModify` | Trigger | – | Aktualisiert Datum/Benutzer bei nachträglicher Änderung. |
| SL Chronext Webshop | SL Sales Price Inbound File | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt "Eingefügt am" beim Anlegen. |
| SL Chronext Webshop | SL Sales Price Import Protocol | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt "Erstellt am" beim Anlegen. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `NonDEPrice – OnValidate` | Trigger | – | Verhindert Umschalten des Preismodus bei vorhandenen Zeilen. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `FinalPrice – OnValidate` | Trigger | – | Markiert Zeile als "nicht geprüft" bei manueller Preisänderung. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `OnOpenPage` | Trigger | – | Leert die Liste beim Öffnen. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `OnModifyRecord` | Trigger | – | Verhindert Ändern freigegebener Preise; blockt deutsche Preise im internationalen Modus. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Navigation `GeneralSalesPriceSetup` | Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Navigation `SalesPriceArchiveNav` | Action | Public | Öffnet das Verkaufspreisarchiv. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Import CSV` | Trigger (OnAction) | Public | Startet CSV-Import neuer Verkaufspreise. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Validate` | Trigger (OnAction) | Public | Rundet Preise, ergänzt Währungen, prüft alle Preiszeilen inhaltlich; meldet fehlenden Ländercode klar statt mit Systemfehler. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Approve` | Trigger (OnAction) | Public | Gibt geprüfte Preiszeilen nach Rückfrage frei. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Add all Currencies` | Trigger (OnAction) | Public | Erzeugt je aktivierter Fremdwährung eine umgerechnete Preiszeile (ersetzt die frühere, länderbasierte "Add All Countries"). |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `fnValidate` | Prozedur | Internal | Vergleicht neue Preise mit dem letzten aktiven Preis, prüft Marge/Schwankungen. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet den Nicht-Lagerpreis für eine Preisspanne. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `CheckDEPrice` | Prozedur | Internal | Verhindert Mischen von deutschen und internationalen Preisen. |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnAfterInitRecord` | Trigger | – | Überspringt die Kopfzeile beim CSV-Einlesen. |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnAfterInsertRecord` | Trigger | – | Ohne zusätzliche Logik (die frühere Länderberechnung läuft jetzt über die Actions in Page 51001). |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor (Kopfzeilen-Erkennung zurücksetzen). |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnPostXmlPort` | Trigger | – | Zeigt Abschlussmeldung nach Import. |
| SL Chronext Webshop | SL Import Sales Price | XMLport | Requestpage `OnOpenPage` | Trigger | – | Setzt Import-Option zurück. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `OnRun` | Trigger | – | Startet Verarbeitung einer eingegangenen Preisdatei. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `ProcessFile` | Prozedur | Internal | Liest Datei zeilenweise ein und übergibt Daten zur Preisübernahme. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `ProcessLine` | Prozedur | Internal | Wandelt eine Dateizeile in einen Preisdatensatz um. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `EvaluateHeaderRow` | Prozedur | Internal | Prüft Anzahl und exakte Reihenfolge der Spaltenüberschriften der Importdatei (verhindert stille Fehlzuordnung bei vertauschten Spalten). |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `WriteProtocol` | Prozedur | Internal | Vermerkt Fehlermeldungen im Protokoll. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `WriteSalesPrices` | Prozedur | Internal | Übernimmt eingelesene Preise in die echten Verkaufspreise. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `OnAfterSalesPriceModify` | Event Publisher | Public | Meldet Preisänderung durch den automatisierten Import an andere Programmteile. |

> Die Tabelle ist nach Projekt und Objekt sortiert. Details siehe `funktionsregister-sl-chronext-webshop.md` im selben Ordner. Objekte ohne eigene Logik (Table 51000, beide Tabellenerweiterungen, beide Seitenerweiterungen, Page 51000/51002, alle drei Enums, das Permission Set) sind hier nicht einzeln aufgeführt – siehe Einzeldatei für die vollständige Objektliste inkl. Begründung.

---

## Funktionsbereiche im Vergleich

Nur ein Projekt vorhanden – keine projektübergreifenden Überschneidungen. Innerhalb des Projekts lassen sich zwei Funktionsbereiche klar trennen:

| Funktionsbereich | Objekte | Anzahl Funktionen | Hinweis |
|---|---|---|---|
| Preisprüfung & -freigabe (manueller Workflow) | Tabellen 51000–51002, Seiten 51000–51002, Seitenerweiterungen 51000/51001, XMLport 51000 | 25 | Aktiv genutzter, vollständig über die UI erreichbarer Kernprozess |
| Dateibasierter Import (Integrationsbaustein) | Codeunit 51001, Tabellen 51005/51006, Enum 51002 | 9 | Fachlich vollständig, aber noch nicht an eine Job-Queue angebunden (siehe `docs/SCHWACHSTELLEN.md`, N3) |
| Reine Datenmodell-Ergänzungen | Tabellenerweiterungen 51000/51001, Enums 51000/51001, Permission Set | 0 | Keine eigene Logik |

---

## Empfehlungen zur Extension-Auslagerung

### Hohe Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| Dateibasierter Preisimport | SL Chronext Webshop | Sobald eine Job-Queue-Anbindung erfolgt, als eigene, wiederverwendbare Extension anlegen – vermeidet späteres, aufwändigeres Herauslösen aus dem Kernmodul. |

### Mittlere Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| Preisprüfung & -freigabe | SL Chronext Webshop | Als Kernmodul belassen; keine weitere Aufteilung sinnvoll, da Import/Prüfung/Freigabe/Archiv eng zusammenhängen. |

---

## Projektabhängigkeiten

Nur ein Projekt vorhanden, `dependencies` in `app.json` ist leer – keine Abhängigkeiten zu dokumentieren.

---

**Hinweis zu diesem Update:** Gegenüber der ersten Fassung (2026-08-04, 35 Funktionen über 16 Objekte) wurde die tote Prozedur `CheckEntries` (bereits damals wirkungslos, inzwischen entfernt) herausgenommen, ebenso Table 51004 "SL Sales Price Outbound File" (verwaist nach Löschung von Codeunit 51000, vom Nutzer entfernt). Ergänzt wurden die beiden neuen Navigation-Actions in Page 51001 sowie die Objekte ohne eigene Logik (2 Seitenerweiterungen, 1 Permission Set), die zuvor nicht existierten. Ergebnis: 18 Objekte, 34 Funktionen.
