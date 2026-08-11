# Gesamtübersicht – AL Funktionsregister

**Erstellt am:** 2026-08-11 (Neuerstellung nach dem AWS-SigV4-Update und der Umstellung von Page 60324 auf bedingte Feldanzeige mit neuer Detailkarte Page 60325)
**Analysierte Projekte:** 1
**Gesamtanzahl Funktionen:** 87

---

## Projektübersicht

| Projekt | Version | Objekte | Prozeduren | Trigger | Events | Navigation/Actions | Gesamt |
|---|---|---|---|---|---|---|---|
| SL Chronext Webshop | 1.0.0.1 | 37 | 43 | 31 | 1 | 12 | 87 |
| **Gesamt** | – | **37** | **43** | **31** | **1** | **12** | **87** |

> Nur ein AL-Projekt vorhanden. Es bündelt zwei fachlich unabhängige Bereiche: **SellWatch** (Ankauf gebrauchter Uhren, ID-Bereich 60300–60310) und **SalesPrice/Verkaufspreisverwaltung** (ID-Bereich 60311–60336). Beide teilen sich ein gemeinsames HTTP-Aufrufprotokoll (Table 60302/Page 60309) und eine gemeinsame Schnittstellen-Konfigurationstabelle (Table 60317) mit austauschbarer Authentifizierung. Seit dem AWS-SigV4-Update unterstützt diese Konfiguration zusätzlich zu API-Schlüssel und Basis-Authentifizierung auch AWS Signature V4 (inkl. optionalem X-API-Key-Zweitfaktor, konfigurierbarer HTTP-Methode und SOAPAction-Header), und seit dem Conditional-Fields-Update zeigt eine neue Detailkarte (Page 60325) nur noch die zur gewählten Authentifizierungsart passenden Felder.

---

## Alle Funktionen – Vollständige Tabelle

| Projekt | Objekt | Objekttyp | Funktion | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|---|---|
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `OnRun` | Trigger | – | Startet den automatisierten Ablauf: prüft neue SellWatch-Verkäuferanfragen und legt daraus Lieferanten und Bestellungen an. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `ValidateAndCreateVendor` | Prozedur | Internal | Sucht offene SellWatch-Anfragen, legt bei Bedarf einen neuen Lieferanten mit Bankverbindung an und stößt die Bestellerstellung an. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrder` | Prozedur | Internal | Legt für eine SellWatch-Anfrage eine Einkaufsbestellung an, gibt sie frei und markiert die Anfrage als erledigt. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrderinBV` | Prozedur | Internal | Legt nachträglich Bestellungen für Anfragen an, die für eine andere Gesellschaft vorgemerkt wurden. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet je nach Angebotsart, ob die Bestellung direkt angelegt oder für eine andere Gesellschaft vorgemerkt wird. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Erstellt aus einer Einkaufsbestellung eine Nachricht mit Bestellnummer und Sendungsverfolgungsnummer. Aktuell nicht angebunden. |
| SL Chronext Webshop | CXW SellWatch Mgt | Codeunit | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Erstellt eine Statusmeldung für SellWatch mit Verkäufer-, Uhren- und Auszahlungsdaten. Aktuell nicht angebunden. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `WriteBackAndArchive` | Prozedur | Public | Übernimmt einen geprüften Preis in die Standard-Preistabelle und legt eine Archivversion an. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Preis- und Zusatzangaben aus der Prüfzeile in den Verkaufspreis-Datensatz. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `ResolveUnitPriceLCY` | Prozedur | Internal | Ermittelt den Verkaufspreis in Landeswährung über den hinterlegten oder zuletzt gültigen Wechselkurs. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `ArchiveCheckingLine` | Prozedur | Internal | Legt eine neue, fortlaufend nummerierte Archivversion einer geprüften Preiszeile an. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis in eine Nachricht um und sendet sie an das konfigurierte externe System. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `SendToApiInterface` | Prozedur | Internal | Baut die Anfrage an die externe Schnittstelle auf (Methode, Authentifizierung, Zusatz-Header), sendet sie und protokolliert das Ergebnis. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `BuildSigV4Headers` | Prozedur | Internal | Berechnet die digitale AWS-Signatur für besonders abgesicherte externe Endpunkte. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `SanitizeHeaderText` | Prozedur | Internal | Entfernt unsichtbare/ungültige Zeichen aus Zugangsdaten, damit die Übertragung nicht an einem Formatfehler scheitert. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `HexEncode` | Prozedur | Internal | Technische Hilfsfunktion für die Signaturberechnung. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `Sha256HexLower` | Prozedur | Internal | Technische Hilfsfunktion für die Signaturberechnung (Prüfsumme). |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `HmacChainStep` | Prozedur | Internal | Technische Hilfsfunktion, ein Rechenschritt der AWS-Signaturberechnung. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `DeriveSigningKey` | Prozedur | Internal | Leitet aus dem AWS-Zugangsschlüssel den Signaturschlüssel ab. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `HmacSignatureHexLower` | Prozedur | Internal | Berechnet die endgültige AWS-Signatur. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine Protokollversion der Anfrage mit durch Platzhalter ersetzten Zugangsdaten. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `LogHttpCall` | Prozedur | Internal | Schreibt Erfolg/Fehlschlag eines Sendevorgangs ins Aufrufprotokoll. |
| SL Chronext Webshop | CXW Export Gateway Sales Price | Codeunit | `AddFieldToJson` | Prozedur | Internal | Wandelt ein einzelnes Datenfeld in das passende Nachrichtenformat um. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `OnRun` | Trigger | – | Startet den Import einer hochgeladenen Preisdatei. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `ProcessFile` | Prozedur | Internal | Liest eine importierte Datei zeilenweise ein und übernimmt die Preisdaten oder meldet einen Fehler. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `ProcessLine` | Prozedur | Internal | Liest eine Zeile der Importdatei aus und ordnet die Werte den Preisfeldern zu. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Kopfzeile der Importdatei dem erwarteten Format entspricht. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `WriteProtocol` | Prozedur | Internal | Schreibt eine Fehlermeldung zu einem Importvorgang ins Importprotokoll. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `WriteSalesPrices` | Prozedur | Internal | Übernimmt die eingelesenen Preisdaten in die Standard-Preistabelle. |
| SL Chronext Webshop | CXW Import Sales Prices | Codeunit | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert anderen Erweiterungen, dass ein Verkaufspreis per Import aktualisiert wurde. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `CXW Check Online – OnValidate` | Trigger | – | Trägt automatisch das Datum der Erst-Online-Schaltung ein, sobald eine Uhr als „online" markiert wird. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `ReadJSONFile` | Prozedur | Internal | Leere, ungenutzte Altfunktion ohne Wirkung. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `CreateJsonObjectCheckOnline` | Prozedur | Public | Baut eine einfache Nachricht mit der laufenden Nummer eines Datensatzes auf. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `CreateEntryInexternalFile` | Prozedur | Public | Fragt bei SellWatch die Online-Freigabe einer Uhr ab und aktualisiert den Datensatz entsprechend. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine Protokolltextform der Anfrage mit redigiertem Schlüssel. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `LogHttpCall` | Prozedur | Internal | Legt zu jedem Aufruf der externen Schnittstelle einen Protokolleintrag an. |
| SL Chronext Webshop | CXW Watch Online Approval | Tabelle | `LogHttpCallFailureTelemetry` | Prozedur | Internal | Meldet einen fehlgeschlagenen Schnittstellenaufruf an die technische Überwachung. |
| SL Chronext Webshop | CXW Http Call Log | Tabelle | `OnInsert` | Trigger | – | Vermerkt automatisch Datum und Uhrzeit beim Anlegen eines neuen Protokolleintrags. |
| SL Chronext Webshop | CXW General Sales Price Setup | Tabelle | `CXW API Interface Code – OnValidate` | Trigger | – | Prüft beim Auswählen einer Schnittstelle, dass diese für Verkaufspreise vorgesehen ist. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnInsert` | Trigger | – | Vermerkt automatisch, wann und von wem eine Prüfzeile angelegt wurde. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnModify` | Trigger | – | Vermerkt die letzte Änderung; setzt bei Währungswechsel Freigabe und Anmerkungen zurück. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `OnRename` | Trigger | – | Vermerkt automatisch, wann und von wem eine Prüfzeile umbenannt wurde. |
| SL Chronext Webshop | CXW Sales Price Checking | Tabelle | `CXW Accept New Setup – OnValidate` | Trigger | – | Verhindert die Freigabe einer nicht validierten Preiszeile und sichert eine vorhandene Anmerkung. |
| SL Chronext Webshop | CXW Sales Price Archive | Tabelle | `OnInsert` | Trigger | – | Vermerkt automatisch, wann und von wem ein Archiveintrag angelegt wurde. |
| SL Chronext Webshop | CXW Sales Price Archive | Tabelle | `OnModify` | Trigger | – | Vermerkt automatisch, wann und von wem ein Archiveintrag zuletzt geändert wurde. |
| SL Chronext Webshop | CXW Sales Price Outbound File | Tabelle | `OnInsert` | Trigger | – | Vermerkt automatisch den Anlagezeitpunkt einer ausgehenden Datei. |
| SL Chronext Webshop | CXW Sales Price Inbound File | Tabelle | `OnInsert` | Trigger | – | Vermerkt automatisch den Anlagezeitpunkt einer eingehenden Datei. |
| SL Chronext Webshop | CXW Price Import Protocol | Tabelle | `OnInsert` | Trigger | – | Vermerkt automatisch den Anlagezeitpunkt eines Protokolleintrags. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `CXW Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass alle für die Authentifizierungsart nötigen Zugangsdaten vollständig hinterlegt sind. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `SetApiKey` / `GetApiKey` | Prozedur | Public | Speichert bzw. liest den allgemeinen API-Schlüssel sicher und verschlüsselt. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Technische Hilfsfunktion (interner Speicherschlüssel). |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `SetAwsSecretAccessKey` / `GetAwsSecretAccessKey` | Prozedur | Public | Speichert bzw. liest den geheimen AWS-Zugriffsschlüssel sicher und verschlüsselt. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `GetAwsSecretAccessKeyIsolatedStorageKey` | Prozedur | Internal | Technische Hilfsfunktion (interner Speicherschlüssel). |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `SetAwsSessionToken` / `GetAwsSessionToken` | Prozedur | Public | Speichert bzw. liest das temporäre AWS-Sitzungstoken sicher und verschlüsselt. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `GetAwsSessionTokenIsolatedStorageKey` | Prozedur | Internal | Technische Hilfsfunktion (interner Speicherschlüssel). |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `IsApiKeyFieldRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart ein API-Schlüssel benötigt wird. |
| SL Chronext Webshop | CXW API Interface Setup | Tabelle | `IsAwsFieldsRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart die AWS-Felder benötigt werden. |
| SL Chronext Webshop | CXW SellWatch-Overview | Seite | `ShowDocument` | Aktion | – | Öffnet die zur Anfrage gehörende Einkaufsbestellung. |
| SL Chronext Webshop | CXW SellWatch-Overview | Seite | `OnOpenPage` | Trigger | – | Zeigt beim Öffnen nur Anfragen mit gültiger SellWatch-Referenznummer. |
| SL Chronext Webshop | CXW Http Call Log | Seite | `DownloadRequest` | Aktion | – | Lädt den protokollierten Anfragetext als Datei herunter. |
| SL Chronext Webshop | CXW Http Call Log | Seite | `DownloadResponse` | Aktion | – | Lädt den protokollierten Antworttext als Datei herunter. |
| SL Chronext Webshop | CXW General Sales Price Setup | Seite | `APIInterfaceSetup` | Aktion | – | Öffnet die Verwaltung der externen Schnittstellen. |
| SL Chronext Webshop | CXW General Sales Price Setup | Seite | `OnOpenPage` | Trigger | – | Legt beim ersten Öffnen automatisch den Einstellungsdatensatz an. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `FinalPrice – OnValidate` | Trigger | – | Setzt die Freigabe zurück, sobald der Verkaufspreis geändert wird. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `GeneralSalesPriceSetup` | Aktion | – | Öffnet die Grundeinstellungen. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `SalesPriceArchiveNav` | Aktion | – | Öffnet die Preishistorie. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `Import CSV` | Aktion | – | Startet den Import einer Preisdatei nach Prüfung der Grundeinstellungen. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `Validate` | Aktion | – | Rundet Preise und prüft jede Zeile automatisch auf Auffälligkeiten. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `Approve` | Aktion | – | Gibt geprüfte und validierte Preiszeilen nach Bestätigung zur Übernahme frei. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `Add all Currencies` | Aktion | – | Legt für jede aktivierte Fremdwährung automatisch eine umgerechnete Preiszeile an. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `Upload Sales Price` | Aktion | – | Übernimmt freigegebene Preiszeilen in die Standard-Preistabelle und sendet sie an die externe Schnittstelle. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `OnOpenPage` | Trigger | – | Leert beim Öffnen die Arbeitsliste. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits freigegebenen Preiszeilen. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `fnValidate` | Prozedur | Internal | Prüft jede offene Preiszeile automatisch auf Auffälligkeiten und markiert sie als validiert. |
| SL Chronext Webshop | CXW Sales Price Checking List | Seite | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für Artikel ohne Lagerbestand einen Nichtlagerpreis anhand eines Aufschlags. |
| SL Chronext Webshop | CXW API Interface Setup | Seite | `CXW Code – OnDrillDown` | Trigger | – | Öffnet die Detailkarte der ausgewählten Schnittstelle. |
| SL Chronext Webshop | CXW API Interface Setup | Seite | `EditDetails` | Aktion | – | Öffnet die Detailkarte der aktuellen Schnittstelle. |
| SL Chronext Webshop | CXW API Interface Setup Card | Seite | `CXW Auth Type – OnValidate` | Trigger | – | Blendet beim Wechsel der Authentifizierungsart sofort die passenden Felder ein bzw. aus. |
| SL Chronext Webshop | CXW API Interface Setup Card | Seite | `ApiKey – OnValidate` | Trigger | – | Speichert den eingegebenen API-Schlüssel sicher und verschlüsselt. |
| SL Chronext Webshop | CXW API Interface Setup Card | Seite | `AwsSecretAccessKey – OnValidate` | Trigger | – | Speichert den eingegebenen geheimen AWS-Zugriffsschlüssel sicher und verschlüsselt. |
| SL Chronext Webshop | CXW API Interface Setup Card | Seite | `AwsSessionToken – OnValidate` | Trigger | – | Speichert das eingegebene AWS-Sitzungstoken sicher und verschlüsselt. |
| SL Chronext Webshop | CXW API Interface Setup Card | Seite | `OnAfterGetCurrRecord` | Trigger | – | Blendet beim Öffnen/Wechseln einer Schnittstelle die passenden Felder ein bzw. aus. |
| SL Chronext Webshop | CXW Import Sales Price | Xmlport | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import automatisch die Kopfzeile der Datei. |
| SL Chronext Webshop | CXW Import Sales Price | Xmlport | `OnAfterInsertRecord` | Trigger | – | Ungenutzt, ohne zusätzliche Wirkung. |
| SL Chronext Webshop | CXW Import Sales Price | Xmlport | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor (merkt sich die Kopfzeile). |
| SL Chronext Webshop | CXW Import Sales Price | Xmlport | `OnPostXmlPort` | Trigger | – | Zeigt nach Abschluss des Imports eine Bestätigungsmeldung. |
| SL Chronext Webshop | CXW Import Sales Price | Xmlport | `requestpage – OnOpenPage` | Trigger | – | Setzt beim Öffnen des Importdialogs eine interne Option zurück. |

> Die Tabelle ist nach Projekt und Objekt sortiert. Für Details zu einzelnen Objekten siehe `funktionsregister-sl-chronext-webshop.md` im selben Ordner.

---

## Funktionsbereiche im Vergleich

| Funktionsbereich | Objekte | Anzahl Funktionen | Hinweis |
|---|---|---|---|
| HTTP-Versand & Protokollierung | Codeunit 60329, Table 60301/60302, Page 60309 | 24 | Gemeinsames Muster (Aufbau, Senden, Protokollieren, Redigieren) in SellWatch und Verkaufspreisverwaltung parallel implementiert — Kandidat für einen gemeinsamen Basis-Baustein. |
| Externe Authentifizierung (API-Key/Basic/AWS SigV4) | Table 60317, Page 60324/60325, Codeunit 60329 | 15 | Zentral auf Table 60317 gepflegt, seit dem Conditional-Fields-Update mit dedizierter, auth-typ-abhängiger Detailkarte. |
| Preisprüfung & Freigabe | Page 60322, Table 60312 | 16 | Kernprozess der Verkaufspreisverwaltung, eng an die fachlichen Freigabe-Regeln (Marge, Schwellenwerte) gekoppelt. |
| SellWatch-Bestellabwicklung | Codeunit 60305, Table 60300, TableExtension 60303/60304 | 5 | Eigenständiger, vom Preisexport unabhängiger Ablauf. |
| CSV-Import (nicht produktiv) | Codeunit 60330, Xmlport 60328, Table 60315/60316 | 12 | Laut Code-Kommentaren aktuell nicht angebunden. |

---

## Empfehlungen zur Extension-Auslagerung

### Hohe Priorität
| Funktionsbereich | Betroffene Objekte | Empfehlung |
|---|---|---|
| SellWatch als eigenständige Extension | Table 60300/60301, TableExtension 60303/60304, Codeunit 60305, Page 60307/60308 | Fachlich vollständig unabhängig vom Preisexport; ID-Bereich bereits sauber getrennt (60300–60310). Auslagerung wäre überwiegend eine Verschiebe-Operation, kein Umbau. |

### Mittlere Priorität
| Funktionsbereich | Betroffene Objekte | Empfehlung |
|---|---|---|
| Gemeinsame HTTP-Infrastruktur als Basis-Baustein | Table 60302, Table 60317, Page 60309/60324/60325 | Bei einer Aufteilung in SellWatch- und SalesPrice-Extensions sollte dieser Teil als dritter, gemeinsam referenzierter Baustein bestehen bleiben, statt dupliziert zu werden. |
| CSV-Import-Pfad separat betrachten | Codeunit 60330, Table 60315/60316, Xmlport 60328 | Da nicht produktiv angebunden: vor einer Auslagerung klären, ob der Pfad noch benötigt wird oder entfernt werden kann. |

---

## Projektabhängigkeiten

Keine externen Projektabhängigkeiten (`app.json` → `dependencies: []`). Intern nutzt die Verkaufspreisverwaltung dieselbe Schnittstellen-Konfigurationstabelle (Table 60317) und dasselbe Aufrufprotokoll (Table 60302) wie SellWatch — beide Bereiche sind innerhalb des einen Projekts lose über diese beiden gemeinsamen Tabellen gekoppelt, nicht über direkte Prozeduraufrufe.
