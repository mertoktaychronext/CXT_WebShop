# Gesamtübersicht – AL Funktionsregister

**Erstellt am:** 2026-08-05 (aktualisiert am 2026-08-10 – alle 26 Objekte und ihre Felder von IDs 51000–51007/Präfix „SL" nach IDs 60311–60336/Präfix „CXW" umnummeriert und umbenannt (reines Rename/Renumber, keine Logikänderung); zuvor: Artikelvarianten und Country Code vollständig aus dem Datenmodell entfernt)
**Analysierte Projekte:** 1
**Gesamtanzahl Funktionen:** 47

---

## Projektübersicht

| Projekt | Version | Objekte | Prozeduren | Trigger | Events | Navigation/Actions | Gesamt |
|---|---|---|---|---|---|---|---|
| SL Chronext Webshop | 1.0.0.0 | 26 | 16 | 22 | 1 | 8 | 47 |
| **Gesamt** | – | **26** | **16** | **22** | **1** | **8** | **47** |

---

## Alle Funktionen – Vollständige Tabelle

| Projekt | Objekt | Objekttyp | Funktion | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|---|---|
| SL Chronext Webshop | CXW General Sales Price Setup | Tabelle | `CXW API Interface Code – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese für Verkaufspreise vorgesehen ist. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `CXW Accept New Setup – OnValidate` | Trigger | – | Verhindert Freigabe eines Preises vor der Prüfung und sichert die Bemerkung. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer der letzten Änderung beim Anlegen ein. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnModify` | Trigger | – | Setzt Prüf-/Freigabekennzeichen zurück, wenn sich die Währung ändert. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnRename` | Trigger | – | Aktualisiert Datum/Benutzer bei Schlüsseländerung. |
| SL Chronext Webshop | CXW Sales Price Archive | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer beim Archivieren eines Preises ein. |
| SL Chronext Webshop | CXW Sales Price Archive | Tabelle | `OnModify` | Trigger | – | Aktualisiert Datum/Benutzer bei nachträglicher Änderung. |
| SL Chronext Webshop | CXW Sales Price Outbound File | Tabelle | `OnInsert` | Trigger | – | Setzt den Erstellungszeitpunkt beim Anlegen eines Ausgangsdatei-Eintrags. |
| SL Chronext Webshop | CXW Sales Price Inbound File | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt "Eingefügt am" beim Anlegen. |
| SL Chronext Webshop | CXW Price Import Protocol | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt "Erstellt am" beim Anlegen. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `CXW Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass Endpunkt-URL und – falls nötig – API-Schlüssel hinterlegt sind. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `SetApiKey` | Prozedur | Public | Speichert oder löscht den API-Schlüssel sicher (verschlüsselt). |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand aus. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Bildet den internen Speicherschlüssel für den API-Schlüssel. |
| SL Chronext Webshop | CXW General Sales Price Setup | Seite | `OnOpenPage` | Trigger | – | Legt die Einstellungszeile automatisch an, falls sie noch nicht existiert. |
| SL Chronext Webshop | CXW General Sales Price Setup | Seite | Navigation `APIInterfaceSetup` | Action | Public | Öffnet die Verwaltung der externen API-Schnittstellen. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `FinalPrice (CXW Stock Price) – OnValidate` | Trigger | – | Markiert Zeile als "nicht geprüft" bei manueller Preisänderung. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Navigation `GeneralSalesPriceSetup` | Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Navigation `SalesPriceArchiveNav` | Action | Public | Öffnet das Verkaufspreisarchiv. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Import CSV` | Action | Public | Startet CSV-Import neuer Verkaufspreise. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Validate` | Action | Public | Rundet Preise, prüft alle Preiszeilen inhaltlich. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Approve` | Action | Public | Gibt geprüfte Preiszeilen nach Rückfrage frei. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Add all Currencies` | Action | Public | Erzeugt je aktivierter Fremdwährung eine umgerechnete Preiszeile. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Upload Sales Price` | Action | Public | Übernimmt jede freigegebene Preiszeile vor dem Versand in "Sales Price" (immer "Für alle Kunden") und ins versionierte Archiv, überträgt sie danach an das externe System. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `OnOpenPage` | Trigger | – | Leert die Liste beim Öffnen. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `OnModifyRecord` | Trigger | – | Verhindert Ändern bereits freigegebener Preise. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `fnValidate` | Prozedur | Internal | Vergleicht neue Preise mit dem letzten aktiven Preis, prüft Marge/Schwankungen. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet den Nicht-Lagerpreis für eine Preisspanne. |
| SL Chronext Webshop | CXW API Interface Setup | Seite | `ApiKey – OnValidate` | Trigger | – | Speichert einen eingegebenen API-Schlüssel sicher ab und leert danach das Eingabefeld. |
| SL Chronext Webshop | CXW Import Sales Price | XMLport | `OnAfterInitRecord` | Trigger | – | Überspringt die Kopfzeile beim CSV-Einlesen. |
| SL Chronext Webshop | CXW Import Sales Price | XMLport | `OnAfterInsertRecord` | Trigger | – | Ohne zusätzliche Logik. |
| SL Chronext Webshop | CXW Import Sales Price | XMLport | Requestpage `OnOpenPage` | Trigger | – | Setzt Import-Option zurück. |
| SL Chronext Webshop | CXW Import Sales Price | XMLport | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor (Kopfzeilen-Erkennung zurücksetzen). |
| SL Chronext Webshop | CXW Import Sales Price | XMLport | `OnPostXmlPort` | Trigger | – | Zeigt Abschlussmeldung nach Import. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `WriteBackAndArchive` | Prozedur | Public | Übernimmt eine freigegebene Preiszeile in "Sales Price" (neu oder aktualisiert, immer "Für alle Kunden") und legt danach eine neue Version im Archiv ab. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Preis, Vergleichspreise, Grund und Anmerkung auf den Verkaufspreis-Datensatz. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `ArchiveCheckingLine` | Prozedur | Internal | Ermittelt die nächste Versionsnummer und legt eine neue Archivkopie der Preiszeile an. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis in eine JSON-Datei um und stößt den Versand an. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `SendToApiInterface` | Prozedur | Internal | Sendet die JSON-Datei per HTTP an die externe Schnittstelle und vermerkt das Ergebnis. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `AddFieldToJson` | Prozedur | Internal | Wandelt ein einzelnes Datenfeld typgerecht in ein JSON-Element um. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `OnRun` | Trigger | – | Startet Verarbeitung einer eingegangenen Preisdatei. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `ProcessFile` | Prozedur | Internal | Liest Datei zeilenweise ein und übergibt Daten zur Preisübernahme. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `ProcessLine` | Prozedur | Internal | Wandelt eine Dateizeile in einen Preisdatensatz um. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `EvaluateHeaderRow` | Prozedur | Internal | Prüft Anzahl und Reihenfolge der Spaltenüberschriften der Importdatei. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `WriteProtocol` | Prozedur | Internal | Vermerkt Fehlermeldungen im Protokoll. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `WriteSalesPrices` | Prozedur | Internal | Übernimmt eingelesene Preise in die echten Verkaufspreise. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `OnAfterSalesPriceModify` | Event Publisher | Public | Meldet Preisänderung durch den automatisierten Import an andere Programmteile. |

> Die Tabelle ist nach Projekt und Objekt sortiert. Details siehe `funktionsregister-sl-chronext-webshop.md` im selben Ordner. Objekte ohne eigene Logik (alle drei Tabellenerweiterungen, Page 60323, alle drei Seitenerweiterungen, alle fünf Enums, das Permission Set) sind hier nicht einzeln aufgeführt.

---

## Funktionsbereiche im Vergleich

Nur ein Projekt vorhanden – keine projektübergreifenden Überschneidungen. Innerhalb des Projekts lassen sich drei Funktionsbereiche klar trennen:

| Funktionsbereich | Objekte | Anzahl Funktionen | Hinweis |
|---|---|---|---|
| Preisprüfung & -freigabe (manueller Workflow) | Tabellen 60312–60313, Seiten 60322–60323, Seitenerweiterungen 60325–60327, Tabellenerweiterungen 60318/60320 | 15 | Aktiv genutzter, vollständig über die UI erreichbarer Kernprozess |
| Export-Anbindung an externe Systeme | Table 60311 (Feld), 60314, 60317, Page 60321, 60324, Codeunit 60329, Enum 60335 | 16 | Neu erfasster Baustein: übernimmt freigegebene Preise automatisch in "Sales Price"/Archiv und überträgt sie an ein externes System. |
| Dateibasierter Import (Integrationsbaustein) | Codeunit 60330, Tabellen 60315/60316, Enum 60333 | 9 | Fachlich vollständig, aber noch nicht an eine Job-Queue angebunden. |
| Reine Datenmodell-Ergänzungen | Tabellenerweiterung 60319, Enums 60331/60332/60334, Permission Set | 0 | Keine eigene Logik |

---

## Empfehlungen zur Extension-Auslagerung

### Hohe Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| Export-Anbindung an externe Systeme | SL Chronext Webshop | Codeunit 60329, Table 60314/60317, Page 60324 und Enum 60335 sind fachlich generisch (konfigurierbare Endpunkte, Authentifizierung, JSON-Versand per Reflection) und nicht an Verkaufspreise gebunden – als eigenständige, wiederverwendbare "Export-Gateway"-Extension geeignet, sobald ein zweiter Anwendungsfall ansteht. |
| Dateibasierter Preisimport | SL Chronext Webshop | Sobald eine Job-Queue-Anbindung erfolgt, als eigene, wiederverwendbare Extension anlegen – vermeidet späteres, aufwändigeres Herauslösen aus dem Kernmodul. |

### Mittlere Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| Preisprüfung & -freigabe | SL Chronext Webshop | Als Kernmodul belassen; keine weitere Aufteilung sinnvoll, da Import/Prüfung/Freigabe eng zusammenhängen. |

---

## Projektabhängigkeiten

Nur ein Projekt vorhanden, `dependencies` in `app.json` ist leer – keine Abhängigkeiten zu dokumentieren.

---

**Hinweis zu diesem Update:** Gegenüber der Vorversion (2026-08-05, 26 Objekte/47 Funktionen) hat sich die Objekt- und Funktionsanzahl nicht verändert. Zwei Changes (`remove-item-variants`, `remove-country-code`) haben `"Variant Code"` (Table 60312/60313), `"Country Code"` (Table 60313) und `"Country/Region Code"` (TableExtension 60319) entfernt, ohne Prozeduren/Trigger/Events hinzuzufügen oder zu löschen; betroffene Beschreibungen (u. a. `UpdateSalesPriceFields`) wurden angepasst. Ergebnis unverändert: 26 Objekte, 47 Funktionen.

**Update 2026-08-10:** Alle 26 Objekte und ihre Felder wurden reinen Rename/Renumber-Charakters von den IDs 51000–51007 (Präfix „SL") in den registrierten idRange-Block 60311–60336 (Präfix „CXW") verschoben – ohne Änderung an Geschäftslogik, Verhalten oder Feld-Captions. Details und die zwei wegen des 30-Zeichen-Limits von AL gekürzten Bezeichner (Table 60316 „CXW Price Import Protocol", Feld „CXW Non Stock Price Thresh %" auf Table 60311) siehe `funktionsregister-sl-chronext-webshop.md`.
