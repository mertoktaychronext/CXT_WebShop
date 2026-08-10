# Gesamtübersicht – AL Funktionsregister

**Erstellt am:** 2026-08-10 (vollständige Neuerstellung nach Zusammenführung der Feature-Branches „SellWatch" (PR 862) und „SalesPrice" (PR 861) im Integrationsbranch `02-DEV/development`; ersetzt die Vorversion, die ausschließlich den SalesPrice-Teil abbildete)
**Analysierte Projekte:** 1
**Gesamtanzahl Funktionen:** 68

---

## Projektübersicht

| Projekt | Version | Objekte | Prozeduren | Trigger | Events | Navigation/Actions | Gesamt |
|---|---|---|---|---|---|---|---|
| SL Chronext Webshop | 1.0.0.1 | 37 | 30 | 26 | 1 | 11 | 68 |
| **Gesamt** | – | **37** | **30** | **26** | **1** | **11** | **68** |

> Nur ein AL-Projekt vorhanden. Es bündelt zwei fachlich unabhängige Bereiche: **SellWatch** (11 Objekte, 19 Funktionen – Ankauf gebrauchter Uhren) und **SalesPrice** (26 Objekte, 49 Funktionen – Verkaufspreisverwaltung). Seit dem HTTP-Logging-Update vom 2026-08-10 teilen sich beide Bereiche zusätzlich ein gemeinsames technisches Protokoll (Table 60302/Page 60309 „CXW Http Call Log").

---

## Alle Funktionen – Vollständige Tabelle

| Projekt | Objekt | Objekttyp | Funktion | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|---|---|
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `CXW Check Online – OnValidate` | Trigger | – | Trägt automatisch das Datum der Erst-Online-Schaltung ein, sobald eine Uhr als „online" markiert wird. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `ReadJSONFile` | Prozedur | Internal | Leere, ungenutzte Hilfsfunktion aus der Altsystem-Migration. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `CreateJsonObjectCheckOnline` | Prozedur | Public | Baut eine einfache JSON-Nachricht mit der laufenden Nummer für den externen Abgleich auf. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `CreateEntryInexternalFile` | Prozedur | Public | Fragt bei der externen SellWatch-Schnittstelle die Online-Freigabe einer Uhr ab, wertet die Antwort aus und protokolliert den Aufruf. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine Protokoll-Textform der Anfrage mit redigiertem API-Schlüssel. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `LogHttpCall` | Prozedur | Internal | Legt zu jedem Aufruf der externen Schnittstelle einen Protokolleintrag an. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `LogHttpCallFailureTelemetry` | Prozedur | Internal | Meldet einen fehlgeschlagenen Schnittstellenaufruf zusätzlich an die technische Überwachung. |
| SL Chronext Webshop | CXW Http Call Log | Tabelle | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den Zeitpunkt des Aufrufs ein. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `OnRun` | Trigger | – | Startet die automatische Prüfung und Anlage von Lieferanten samt Einkaufsauftrag für neue SellWatch-Angebote. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `ValidateAndCreateVendor` | Prozedur | Internal | Sucht oder legt für ein SellWatch-Angebot den passenden Lieferanten samt Bankverbindung an. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrder` | Prozedur | Internal | Legt für ein SellWatch-Angebot automatisch einen Einkaufsauftrag mit Artikelzeile an und gibt ihn frei. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrderinBV` | Prozedur | Internal | Verarbeitet gesammelt für eine andere Gesellschaft (BV) vorgemerkte SellWatch-Angebote nach. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet, ob der Einkaufsauftrag sofort angelegt oder für eine andere Gesellschaft vorgemerkt wird. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Baut eine JSON-Rückmeldung mit Bestell- und Sendungsverfolgungsnummer für SellWatch auf. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Baut die vollständige Status-Rückmeldung (Ankunft, Online, Verkauf …) inkl. Provision für SellWatch auf. |
| SL Chronext Webshop | CXW SellWatch-Overview | Seite | Action `ShowDocument` | Action | Public | Öffnet den zu einem SellWatch-Angebot angelegten Einkaufsauftrag. |
| SL Chronext Webshop | CXW SellWatch-Overview | Seite | `OnOpenPage` | Trigger | – | Zeigt nur Angebote mit vorhandener SellWatch-Anfragenummer an. |
| SL Chronext Webshop | CXW Http Call Log | Seite | Action `DownloadRequest` | Action | Public | Lädt den protokollierten Anfrage-Inhalt eines Aufrufs als Textdatei herunter. |
| SL Chronext Webshop | CXW Http Call Log | Seite | Action `DownloadResponse` | Action | Public | Lädt den protokollierten Antwort-Inhalt eines Aufrufs als Textdatei herunter. |
| SL Chronext Webshop | CXW General Sales Price Setup | Tabelle | `CXW API Interface Code – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese für Verkaufspreise vorgesehen ist. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `CXW Accept New Setup – OnValidate` | Trigger | – | Verhindert Freigabe eines Preises vor der Prüfung und sichert die Bemerkung. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer der letzten Änderung beim Anlegen ein. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnModify` | Trigger | – | Setzt Prüf-/Freigabekennzeichen zurück, wenn sich die Währung ändert. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnRename` | Trigger | – | Aktualisiert Datum/Benutzer bei Schlüsseländerung. |
| SL Chronext Webshop | CXW Sales Price Archive | Tabelle | `OnInsert` | Trigger | – | Trägt Datum/Benutzer beim Archivieren eines Preises ein. |
| SL Chronext Webshop | CXW Sales Price Archive | Tabelle | `OnModify` | Trigger | – | Aktualisiert Datum/Benutzer bei nachträglicher Änderung. |
| SL Chronext Webshop | CXW Sales Price Outbound File | Tabelle | `OnInsert` | Trigger | – | Setzt den Erstellungszeitpunkt beim Anlegen eines Ausgangsdatei-Eintrags. |
| SL Chronext Webshop | CXW Sales Price Inbound File | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt „Eingefügt am" beim Anlegen. |
| SL Chronext Webshop | CXW Price Import Protocol | Tabelle | `OnInsert` | Trigger | – | Setzt den Zeitpunkt „Erstellt am" beim Anlegen. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `CXW Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass Endpunkt-URL und – falls nötig – API-Schlüssel hinterlegt sind. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `SetApiKey` | Prozedur | Public | Speichert oder löscht den API-Schlüssel sicher (verschlüsselt). |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand aus. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Bildet den internen Speicherschlüssel für den API-Schlüssel. |
| SL Chronext Webshop | CXW General Sales Price Setup | Seite | `OnOpenPage` | Trigger | – | Legt die Einstellungszeile automatisch an, falls sie noch nicht existiert. |
| SL Chronext Webshop | CXW General Sales Price Setup | Seite | Navigation `APIInterfaceSetup` | Action | Public | Öffnet die Verwaltung der externen API-Schnittstellen. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `FinalPrice (CXW Stock Price) – OnValidate` | Trigger | – | Markiert Zeile als „nicht geprüft" bei manueller Preisänderung. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Navigation `GeneralSalesPriceSetup` | Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Navigation `SalesPriceArchiveNav` | Action | Public | Öffnet das Verkaufspreisarchiv. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Import CSV` | Action | Public | Startet CSV-Import neuer Verkaufspreise. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Validate` | Action | Public | Rundet Preise, prüft alle Preiszeilen inhaltlich. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Approve` | Action | Public | Gibt geprüfte Preiszeilen nach Rückfrage frei. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Add all Currencies` | Action | Public | Erzeugt je aktivierter Fremdwährung eine umgerechnete Preiszeile. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | Action `Upload Sales Price` | Action | Public | Übernimmt jede freigegebene Preiszeile vor dem Versand in „Sales Price" (immer „Für alle Kunden") und ins versionierte Archiv, überträgt sie danach an das externe System. |
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
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `WriteBackAndArchive` | Prozedur | Public | Übernimmt eine freigegebene Preiszeile in „Sales Price" (neu oder aktualisiert, immer „Für alle Kunden") und legt danach eine neue Version im Archiv ab. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Preis, Vergleichspreise, Grund und Anmerkung auf den Verkaufspreis-Datensatz. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `ArchiveCheckingLine` | Prozedur | Internal | Ermittelt die nächste Versionsnummer und legt eine neue Archivkopie der Preiszeile an. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis in eine JSON-Datei um und stößt den Versand an. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `SendToApiInterface` | Prozedur | Internal | Sendet die JSON-Datei per HTTP an die externe Schnittstelle, vermerkt das Ergebnis und protokolliert jeden Aufruf im gemeinsamen HTTP-Aufrufprotokoll (Table 60302). |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine Protokoll-Textform der Anfrage mit redigiertem Authorization-Header. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `LogHttpCall` | Prozedur | Internal | Legt zu jedem Aufruf der externen Schnittstelle einen Eintrag im gemeinsamen HTTP-Aufrufprotokoll (Table 60302) an. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `AddFieldToJson` | Prozedur | Internal | Wandelt ein einzelnes Datenfeld typgerecht in ein JSON-Element um. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `OnRun` | Trigger | – | Startet Verarbeitung einer eingegangenen Preisdatei. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `ProcessFile` | Prozedur | Internal | Liest Datei zeilenweise ein und übergibt Daten zur Preisübernahme. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `ProcessLine` | Prozedur | Internal | Wandelt eine Dateizeile in einen Preisdatensatz um. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `EvaluateHeaderRow` | Prozedur | Internal | Prüft Anzahl und Reihenfolge der Spaltenüberschriften der Importdatei. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `WriteProtocol` | Prozedur | Internal | Vermerkt Fehlermeldungen im Protokoll. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `WriteSalesPrices` | Prozedur | Internal | Übernimmt eingelesene Preise in die echten Verkaufspreise. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `OnAfterSalesPriceModify` | Event Publisher | Public | Meldet Preisänderung durch den automatisierten Import an andere Programmteile. |

> Die Tabelle ist nach Projekt und Objekt sortiert (SellWatch-Objekte zuerst, dann SalesPrice-Objekte, jeweils in ID-Reihenfolge). Details siehe `funktionsregister-sl-chronext-webshop.md` im selben Ordner. Objekte ohne eigene Logik (Table 60300, alle SellWatch- und SalesPrice-Tabellenerweiterungen, Page 60308/60323, alle Seitenerweiterungen, alle sechs Enums, beide Permission Sets) sind hier nicht einzeln aufgeführt.

---

## Funktionsbereiche im Vergleich

Nur ein Projekt vorhanden – keine projektübergreifenden Überschneidungen. Innerhalb des Projekts lassen sich fünf Funktionsbereiche klar trennen:

| Funktionsbereich | Objekte | Anzahl Funktionen | Hinweis |
|---|---|---|---|
| SellWatch – Ankauf & Lieferantenanlage | Table 60300/60301, TableExtension 60303/60304, Codeunit 60305, Enum 60306, Page 60307/60308, Permission Set 60310 | 9 | Vollständig eigenständiger Ankaufsprozess (Lieferant + Einkaufsauftrag) ohne Berührung zu SalesPrice. |
| SellWatch – externe Online-Freigabe & Protokollierung | Table 60301 (HTTP-Prozeduren), Table 60302, Page 60309 | 10 | HTTP-Anbindung mit Fehlerprotokoll und Telemetrie; das Protokoll (Table 60302/Page 60309) wird seit dem HTTP-Logging-Update vom 2026-08-10 gemeinsam mit dem SalesPrice-Export-Gateway genutzt (siehe unten). |
| Preisprüfung & -freigabe (manueller Workflow) | Tabellen 60312–60313, Seiten 60322–60323, Seitenerweiterungen 60325–60327, Tabellenerweiterungen 60318/60320 | 15 | Aktiv genutzter, vollständig über die UI erreichbarer Kernprozess |
| Export-Anbindung an externe Systeme (SalesPrice) | Table 60311 (Feld), 60314, 60317, Page 60321, 60324, Codeunit 60329, Enum 60335 | 18 | Übernimmt freigegebene Preise automatisch in „Sales Price"/Archiv, überträgt sie an ein externes System und protokolliert seit dem 2026-08-10-Update jeden Aufruf im mit SellWatch gemeinsam genutzten Protokoll (Table 60302). |
| Dateibasierter Import (Integrationsbaustein, SalesPrice) | Codeunit 60330, Tabellen 60315/60316, Enum 60333 | 9 | Fachlich vollständig, aber noch nicht an eine Job-Queue angebunden. |
| Reine Datenmodell-Ergänzungen | Tabellenerweiterung 60319, Enums 60331/60332/60334, beide Permission Sets, Table 60300 | 0 | Keine eigene Logik |

---

## Empfehlungen zur Extension-Auslagerung

### Hohe Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| SellWatch-Ankaufsanbindung | SL Chronext Webshop | Vollständig eigenständiger Geschäftsprozess (Ankauf gebrauchter Uhren, eigene Tabellen, eigenes Permission Set, keine fachliche Abhängigkeit zu SalesPrice) – als eigene Extension geeignet, sobald ein zweiter Ankaufskanal oder eine getrennte Release-Strategie gewünscht ist. |
| Export-Anbindung an externe Systeme (SalesPrice) | SL Chronext Webshop | Codeunit 60329, Table 60314/60317, Page 60324 und Enum 60335 sind fachlich generisch (konfigurierbare Endpunkte, Authentifizierung, JSON-Versand per Reflection) und nicht an Verkaufspreise gebunden – als eigenständige, wiederverwendbare „Export-Gateway"-Extension geeignet, sobald ein zweiter Anwendungsfall ansteht. |

### Mittlere Priorität
| Funktionsbereich | Betroffene Projekte | Empfehlung |
|---|---|---|
| Externe HTTP-Anbindung mit Protokollierung (SellWatch) und Export-Gateway (SalesPrice) konsolidieren | SL Chronext Webshop | Seit dem HTTP-Logging-Update vom 2026-08-10 bereits umgesetzt: beide Bereiche protokollieren ihre HTTP-Aufrufe im gemeinsamen Table 60302 „CXW Http Call Log" (Feld „CXW Source Table No." unterscheidet die Quelle). Bei einer künftigen Auslagerung als eigene Extension lässt sich dieses gemeinsame Protokoll als eigenständiger, wiederverwendbarer Baustein herauslösen. |
| Dateibasierter Preisimport (SalesPrice) | SL Chronext Webshop | Sobald eine Job-Queue-Anbindung erfolgt, als eigene, wiederverwendbare Extension anlegen – vermeidet späteres, aufwändigeres Herauslösen aus dem Kernmodul. |
| Preisprüfung & -freigabe (SalesPrice) | SL Chronext Webshop | Als Kernmodul belassen; keine weitere Aufteilung sinnvoll, da Import/Prüfung/Freigabe eng zusammenhängen. |

---

## Projektabhängigkeiten

Nur ein Projekt vorhanden, `dependencies` in `app.json` ist leer – keine externen Abhängigkeiten zu dokumentieren. Innerhalb des Projekts bestehen weiterhin keine Aufrufe zwischen SellWatch- und SalesPrice-Fachlogik; beide Bereiche teilen sich Extension und ID-Bereich (60300–60349) sowie seit dem HTTP-Logging-Update vom 2026-08-10 zusätzlich die technische Protokoll-Tabelle „CXW Http Call Log" (Table 60302) – eine rein infrastrukturelle, keine fachliche Kopplung.

---

**Hinweis zu diesem Update:** Diese Version ersetzt vollständig die Vorversion (26 Objekte/47 Funktionen), die nach dem Merge der Feature-Branches „SellWatch" (PR 862) und „SalesPrice" (PR 861) in den Integrationsbranch `02-DEV/development` ausschließlich den SalesPrice-Teil abbildete, obwohl die 11 SellWatch-Objekte im Quellcode vollständig vorhanden sind und mitkompilieren. Alle 37 Objekte wurden direkt aus dem aktuellen Quellcode neu erfasst. Ergebnis: 37 Objekte (11 SellWatch + 26 SalesPrice), 66 Funktionen/Trigger/Events/Actions (19 SellWatch + 47 SalesPrice). Details siehe `funktionsregister-sl-chronext-webshop.md`.

**Update 2026-08-10 (HTTP-Call-Logging vereinheitlicht):** Table 60302/Page 60309 (bisher „CXW SW Http Call Log", ausschließlich SellWatch) wurden in „CXW Http Call Log" umbenannt und um das Feld „CXW Source Table No." erweitert, damit sie Aufrufe aus beliebigen Quelltabellen aufnehmen können. `Codeunit 60329 "CXW Export Gateway Sales Price"` protokolliert seither jeden HTTP-Aufruf von `SendToApiInterface` dort ebenfalls (2 neue Prozeduren: `BuildRedactedRequestText`, `LogHttpCall`). Ergebnis dieses Updates: 68 statt 66 Funktionen/Trigger/Events/Actions (19 SellWatch + 49 SalesPrice).
