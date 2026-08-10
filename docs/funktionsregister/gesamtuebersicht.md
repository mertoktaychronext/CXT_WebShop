# Gesamtübersicht – AL Funktionsregister

**Erstellt am:** 2026-08-05 (aktualisiert 2026-08-09 – HTTP-Call-Logging und Telemetry für den SellWatch-Online-Check ergänzt)
**Analysierte Projekte:** 1
**Gesamtanzahl Funktionen:** 66

---

## Projektübersicht

| Projekt | Version | Objekte | Prozeduren | Trigger | Events | Navigation/Actions | Gesamt |
|---|---|---|---|---|---|---|---|
| SL Chronext Webshop | 1.0.0.1 | 37 | 28 | 26 | 1 | 11 | 66 |
| **Gesamt** | – | **37** | **28** | **26** | **1** | **11** | **66** |

---

## Alle Funktionen – Vollständige Tabelle

| Projekt | Objekt | Objekttyp | Funktion | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|---|---|
| SL Chronext Webshop | SL General Sales Price Setup | Tabelle | `API Interface Code – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese für Verkaufspreise vorgesehen ist. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `Accept New Setup – OnValidate` | Trigger | – | Verhindert Freigabe eines Preises vor der Prüfung und sichert die Bemerkung. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer der letzten Änderung beim Anlegen ein. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `OnModify` | Trigger | – | Setzt Prüf-/Freigabekennzeichen zurück, wenn sich die Währung ändert. |
| SL Chronext Webshop | SL Sales Price Checking | Tabelle | `OnRename` | Trigger | – | Aktualisiert Datum/Benutzer bei Schlüsseländerung. |
| SL Chronext Webshop | SL Sales Price Archive | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer beim Archivieren eines Preises ein. |
| SL Chronext Webshop | SL Sales Price Archive | Tabelle | `OnModify` | Trigger | – | Aktualisiert Datum/Benutzer bei nachträglicher Änderung. |
| SL Chronext Webshop | SL Sales Price Outbound File | Tabelle | `OnInsert` | Trigger | – | Setzt den Erstellungszeitpunkt beim Anlegen eines Ausgangsdatei-Eintrags. |
| SL Chronext Webshop | SL Sales Price Inbound File | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt "Eingefügt am" beim Anlegen. |
| SL Chronext Webshop | SL Sales Price Import Protocol | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt "Erstellt am" beim Anlegen. |
| SL Chronext Webshop | SL API Interface Setup | Tabelle | `Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass Endpunkt-URL und – falls nötig – API-Schlüssel hinterlegt sind. |
| SL Chronext Webshop | SL API Interface Setup | Tabelle | `SetApiKey` | Prozedur | Public | Speichert oder löscht den API-Schlüssel sicher (verschlüsselt). |
| SL Chronext Webshop | SL API Interface Setup | Tabelle | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand aus. |
| SL Chronext Webshop | SL API Interface Setup | Tabelle | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Bildet den internen Speicherschlüssel für den API-Schlüssel. |
| SL Chronext Webshop | Watch Online Approval | Tabelle | `"Check Online" – OnValidate` | Trigger | – | Trägt automatisch das Datum der Erstfreigabe ein, sobald eine Uhr für den Online-Verkauf freigegeben wird. |
| SL Chronext Webshop | Watch Online Approval | Tabelle | `ReadJSONFile` | Prozedur | Internal | Nicht implementierte Altfunktion ohne Logik. |
| SL Chronext Webshop | Watch Online Approval | Tabelle | `CreateJsonObjectCheckOnline` | Prozedur | Public | Baut ein einfaches JSON-Dokument mit der laufenden Nummer eines Freigabe-Datensatzes. |
| SL Chronext Webshop | Watch Online Approval | Tabelle | `CreateEntryInexternalFile` | Prozedur | Public | Fragt bei einer externen Schnittstelle ab, ob eine Uhr online gehen darf, protokolliert jeden Aufruf und setzt die Online-Freigabe entsprechend der Antwort. |
| SL Chronext Webshop | Watch Online Approval | Tabelle | `BuildRedactedRequestText` | Prozedur | Internal | Baut den zu protokollierenden Request-Text mit redigiertem API-Key auf. |
| SL Chronext Webshop | Watch Online Approval | Tabelle | `LogHttpCall` | Prozedur | Internal | Legt einen Protokolleintrag in "SW Http Call Log" an. |
| SL Chronext Webshop | Watch Online Approval | Tabelle | `LogHttpCallFailureTelemetry` | Prozedur | Internal | Meldet einen fehlgeschlagenen HTTP-Aufruf per Telemetry. |
| SL Chronext Webshop | SW Http Call Log | Tabelle | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch Datum/Uhrzeit des Aufrufs ein. |
| SL Chronext Webshop | SL General Sales Price Setup | Seite | `OnOpenPage` | Trigger | – | Legt die Einstellungszeile automatisch an, falls sie noch nicht existiert. |
| SL Chronext Webshop | SL General Sales Price Setup | Seite | Navigation `APIInterfaceSetup` | Action | Public | Öffnet die Verwaltung der externen API-Schnittstellen. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `FinalPrice – OnValidate` | Trigger | – | Markiert Zeile als "nicht geprüft" bei manueller Preisänderung. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Navigation `GeneralSalesPriceSetup` | Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Navigation `SalesPriceArchiveNav` | Action | Public | Öffnet das Verkaufspreisarchiv. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Import CSV` | Action | Public | Startet CSV-Import neuer Verkaufspreise. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Validate` | Action | Public | Rundet Preise, prüft alle Preiszeilen inhaltlich. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Approve` | Action | Public | Gibt geprüfte Preiszeilen nach Rückfrage frei. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Add all Currencies` | Action | Public | Erzeugt je aktivierter Fremdwährung eine umgerechnete Preiszeile. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | Action `Upload Sales Price` | Action | Public | Übernimmt jede freigegebene Preiszeile vor dem Versand in "Sales Price" (immer "Für alle Kunden") und ins versionierte Archiv, überträgt sie danach an das externe System. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `OnOpenPage` | Trigger | – | Leert die Liste beim Öffnen. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `OnModifyRecord` | Trigger | – | Verhindert Ändern bereits freigegebener Preise. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `fnValidate` | Prozedur | Internal | Vergleicht neue Preise mit dem letzten aktiven Preis, prüft Marge/Schwankungen. |
| SL Chronext Webshop | SL Sales Price Checking List | Seite | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet den Nicht-Lagerpreis für eine Preisspanne. |
| SL Chronext Webshop | SL API Interface Setup | Seite | `ApiKey – OnValidate` | Trigger | – | Speichert einen eingegebenen API-Schlüssel sicher ab und leert danach das Eingabefeld. |
| SL Chronext Webshop | SellWatch-Overview | Seite | `OnOpenPage` | Trigger | – | Zeigt beim Öffnen nur SellWatch-Anfragen mit einer echten Anfrage-ID an. |
| SL Chronext Webshop | SellWatch-Overview | Seite | Action `Show Document` | Action | Public | Öffnet die zu einer SellWatch-Anfrage gehörende Einkaufsbestellung zur Ansicht. |
| SL Chronext Webshop | SW Http Call Log | Seite | Action `Download Request` | Action | Public | Lädt den protokollierten Request eines Eintrags als .txt-Datei herunter. |
| SL Chronext Webshop | SW Http Call Log | Seite | Action `Download Response` | Action | Public | Lädt die protokollierte Response eines Eintrags als .txt-Datei herunter. |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnAfterInitRecord` | Trigger | – | Überspringt die Kopfzeile beim CSV-Einlesen. |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnAfterInsertRecord` | Trigger | – | Ohne zusätzliche Logik. |
| SL Chronext Webshop | SL Import Sales Price | XMLport | Requestpage `OnOpenPage` | Trigger | – | Setzt Import-Option zurück. |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor (Kopfzeilen-Erkennung zurücksetzen). |
| SL Chronext Webshop | SL Import Sales Price | XMLport | `OnPostXmlPort` | Trigger | – | Zeigt Abschlussmeldung nach Import. |
| SL Chronext Webshop | SL Export Gateway Sales Price | Codeunit | `WriteBackAndArchive` | Prozedur | Public | Übernimmt eine freigegebene Preiszeile in "Sales Price" (neu oder aktualisiert, immer "Für alle Kunden") und legt danach eine neue Version im Archiv ab. |
| SL Chronext Webshop | SL Export Gateway Sales Price | Codeunit | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Preis, Vergleichspreise, Grund und Anmerkung auf den Verkaufspreis-Datensatz. |
| SL Chronext Webshop | SL Export Gateway Sales Price | Codeunit | `ArchiveCheckingLine` | Prozedur | Internal | Ermittelt die nächste Versionsnummer und legt eine neue Archivkopie der Preiszeile an. |
| SL Chronext Webshop | SL Export Gateway Sales Price | Codeunit | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis in eine JSON-Datei um und stößt den Versand an. |
| SL Chronext Webshop | SL Export Gateway Sales Price | Codeunit | `SendToApiInterface` | Prozedur | Internal | Sendet die JSON-Datei per HTTP an die externe Schnittstelle und vermerkt das Ergebnis. |
| SL Chronext Webshop | SL Export Gateway Sales Price | Codeunit | `AddFieldToJson` | Prozedur | Internal | Wandelt ein einzelnes Datenfeld typgerecht in ein JSON-Element um. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `OnRun` | Trigger | – | Startet Verarbeitung einer eingegangenen Preisdatei. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `ProcessFile` | Prozedur | Internal | Liest Datei zeilenweise ein und übergibt Daten zur Preisübernahme. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `ProcessLine` | Prozedur | Internal | Wandelt eine Dateizeile in einen Preisdatensatz um. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `EvaluateHeaderRow` | Prozedur | Internal | Prüft Anzahl und Reihenfolge der Spaltenüberschriften der Importdatei. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `WriteProtocol` | Prozedur | Internal | Vermerkt Fehlermeldungen im Protokoll. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `WriteSalesPrices` | Prozedur | Internal | Übernimmt eingelesene Preise in die echten Verkaufspreise. |
| SL Chronext Webshop | SL Import Sales Prices | Codeunit | `OnAfterSalesPriceModify` | Event Publisher | Public | Meldet Preisänderung durch den automatisierten Import an andere Programmteile. |
| SL Chronext Webshop | SellWatch Mgt | Codeunit | `OnRun` | Trigger | – | Startet die automatische Anlage neuer Lieferanten und Bestellungen aus offenen SellWatch-Ankaufsanfragen. |
| SL Chronext Webshop | SellWatch Mgt | Codeunit | `ValidateAndCreateVendor` | Prozedur | Internal | Prüft je SellWatch-Anfrage, ob bereits ein passender Lieferant existiert; legt andernfalls einen neuen Lieferanten samt Bankverbindung an. |
| SL Chronext Webshop | SellWatch Mgt | Codeunit | `CreatePurchaseOrder` | Prozedur | Internal | Erstellt für eine SellWatch-Anfrage automatisch eine Einkaufsbestellung mit einer Position für die angebotene Uhr und gibt sie frei. |
| SL Chronext Webshop | SellWatch Mgt | Codeunit | `CreatePurchaseOrderinBV` | Prozedur | Internal | Verarbeitet nachträglich alle SellWatch-Anfragen, die für die Bestellerstellung im BV-System vorgemerkt, aber noch ohne Bestellnummer sind. |
| SL Chronext Webshop | SellWatch Mgt | Codeunit | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet je nach Angebotsart, ob die Bestellung direkt in der GmbH angelegt oder für die spätere BV-Verarbeitung vorgemerkt wird. |
| SL Chronext Webshop | SellWatch Mgt | Codeunit | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Baut aus einer Einkaufsbestellung ein JSON-Dokument mit Bestellnummer, Lieferantenreferenz und Tracking-Nummer für den Datenaustausch mit SellWatch. |
| SL Chronext Webshop | SellWatch Mgt | Codeunit | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Baut ein JSON-Dokument mit dem aktuellen Status einer SellWatch-Anfrage inklusive Kontakt-, Uhren- und Auszahlungsdaten für die Rückmeldung an SellWatch. |

> Die Tabelle ist nach Projekt und Objekt sortiert. Details siehe `funktionsregister-sl-chronext-webshop.md` im selben Ordner. Objekte ohne eigene Logik (alle fünf Tabellenerweiterungen, Table 51008, Page 51002/51005, alle drei Seitenerweiterungen, alle sechs Enums, beide Permission Sets) sind hier nicht einzeln aufgeführt.

---

## Funktionsbereiche im Vergleich

Nur ein Projekt vorhanden – keine projektübergreifenden Überschneidungen. Innerhalb des Projekts lassen sich fünf Funktionsbereiche klar trennen:

| Funktionsbereich | Objekte | Anzahl Funktionen | Hinweis |
|---|---|---|---|
| Preisprüfung & -freigabe (manueller Workflow) | Tabellen 51001–51002, Seiten 51001–51002, Seitenerweiterungen 51000–51002, Tabellenerweiterungen 51000/51002 | 15 | Aktiv genutzter, vollständig über die UI erreichbarer Kernprozess |
| Export-Anbindung an externe Systeme | Table 51000 (Feld), 51004, 51007, Page 51000, 51003, Codeunit 51000, Enum 51004 | 16 | Wird inzwischen von zwei unabhängigen Prozessen genutzt: Sales-Price-Export **und** seit 2026-08-07 auch die SellWatch-Online-Freigabe (`Watch Online Approval`). |
| Dateibasierter Import (Integrationsbaustein) | Codeunit 51001, Tabellen 51005/51006, Enum 51002 | 9 | Fachlich vollständig, aber noch nicht an eine Job-Queue angebunden. |
| SellWatch-Ankaufsintegration | Table 51008/51009/51010, Codeunit 51002, Page 51004/51005/51006, Enum 51006, TableExt 51003/51004, Permission Set SWChronWSAll | 19 | Automatisierte Lieferanten-/Bestellanlage aus Ankaufsanfragen (seit 2026-08-07) sowie HTTP-Call-Logging und Telemetry für die Online-Freigabeprüfung (seit 2026-08-09). Fachlich eigenständig, siehe Auslagerungs-Empfehlung. |
| Reine Datenmodell-Ergänzungen | Tabellenerweiterung 51001, Enums 51000/51001/51003, Permission Set SLChronWSAll | 0 | Keine eigene Logik |

---

## Empfehlungen zur Extension-Auslagerung

### Hohe Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| SellWatch-Ankaufsintegration | SL Chronext Webshop | Table 51008/51009/51010, Codeunit 51002, Page 51004/51005/51006, Enum 51006, TableExt 51003/51004 und Permission Set SWChronWSAll bilden einen fachlich vollständig eigenständigen Prozess ohne inhaltliche Berührung zur Preisprüfung – als eigene Extension herauslösbar, sobald SellWatch getrennt vom Preis-Webshop weiterentwickelt oder ausgerollt werden soll. |
| Export-Anbindung an externe Systeme | SL Chronext Webshop | Codeunit 51000, Table 51004/51007, Page 51003 und Enum 51004 sind fachlich generisch (konfigurierbare Endpunkte, Authentifizierung, JSON-Versand) und werden inzwischen bereits von zwei unabhängigen Prozessen genutzt (Sales-Price-Export und SellWatch) – damit ein noch stärkerer Kandidat als zuvor für eine eigene, gemeinsame Basis-Extension, von der beide Fach-Extensions abhängen. |
| Dateibasierter Preisimport | SL Chronext Webshop | Sobald eine Job-Queue-Anbindung erfolgt, als eigene, wiederverwendbare Extension anlegen – vermeidet späteres, aufwändigeres Herauslösen aus dem Kernmodul. |

### Mittlere Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| Preisprüfung & -freigabe | SL Chronext Webshop | Als Kernmodul belassen; keine weitere Aufteilung sinnvoll, da Import/Prüfung/Freigabe eng zusammenhängen. |

---

## Projektabhängigkeiten

Nur ein Projekt vorhanden, `dependencies` in `app.json` ist leer – keine externen Abhängigkeiten zu dokumentieren. Intern besteht seit 2026-08-07 eine neue Abhängigkeit der SellWatch-Integration (Table 51009) auf die generische Schnittstellen-Tabelle `SL API Interface Setup` (Table 51007) — relevant, falls die beiden Bereiche künftig in getrennte Extensions aufgeteilt werden (siehe oben).

---

**Hinweis zum Update vom 2026-08-05:** Gegenüber der damaligen Vorversion hatte sich die Objekt- und Funktionsanzahl nicht verändert. Zwei Changes (`remove-item-variants`, `remove-country-code`) hatten `"Variant Code"` (Table 51001/51002), `"Country Code"` (Table 51002) und `"Country/Region Code"` (TableExtension 51001) entfernt, ohne Prozeduren/Trigger/Events hinzuzufügen oder zu löschen. Ergebnis damals: 26 Objekte, 47 Funktionen.

**Hinweis zum Update vom 2026-08-07:** Die SellWatch-Ankaufsintegration wurde aus einem NAV-Altsystem migriert und komplett neu hinzugefügt (Table 51008/51009, Codeunit 51002, Page 51004/51005, Enum 51006, TableExt 51003/51004, Permission Set SWChronWSAll). Ergebnis damals: 35 Objekte, 60 Funktionen (+9 Objekte / +13 Funktionen).

**Hinweis zum Update vom 2026-08-09:** Table 51010 "SW Http Call Log" und Page 51006 "SW Http Call Log" neu hinzugefügt; `CreateEntryInexternalFile` (Table 51009) protokolliert jetzt jeden HTTP-Aufruf der SellWatch-Online-Freigabeprüfung inkl. drei neuer interner Hilfsprozeduren und meldet Fehlschläge zusätzlich per Telemetry. Ergebnis: 37 Objekte, 66 Funktionen (+2 Objekte / +6 Funktionen).
