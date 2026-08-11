# Entwicklerhandbuch – SL Chronext Webshop

## Überblick

Diese Business-Central-Erweiterung (AL) bildet die Verwaltung von Webshop-Verkaufspreisen ab: CSV-Import in eine Zwischenablage-Tabelle, fachliche Prüfung (Marge, Preisschwankungen), Freigabe durch einen Sachbearbeiter, optional die automatische Vervielfältigung eines Preises auf alle aktivierten Fremdwährungen, und das Hochladen freigegebener Preise an ein externes System. Die Aktion "Upload Sales Price" schreibt jeden freigegebenen Preis in die Standardtabelle "Sales Price" und als versionierten Eintrag in "CXW Sales Price Archive", bevor er an eine konfigurierbare API-Schnittstelle gesendet wird. Ein zweiter, unabhängiger Baustein für dateibasierten Preisimport (nicht produktiv angebunden) rundet das Projekt ab. Das Projekt ist eine Migration aus einem gewachsenen Dynamics-NAV-Altsystem in modernes, SaaS-fähiges AL.

> **Update 2026-08-10:** Alle 26 Objekte dieser Erweiterung (bisher IDs 51000–51007, Präfix „SL") wurden reinen Rename/Renumber-Charakters in den registrierten idRange-Block 60311–60336 (Präfix „CXW") verschoben, ebenso alle von ihnen definierten Felder (Präfix „CXW "/„CXW"). Geschäftslogik, Verhalten und Feld-Captions sind unverändert. Zwei Bezeichner mussten wegen des 30-Zeichen-Limits von AL zusätzlich gekürzt werden: Table 60316 „CXW Price Import Protocol" (ohne „Sales" im Bezeichner) und das Feld „CXW Non Stock Price Thresh %" auf Table 60311 (Caption weiterhin "Non Stock Price Threshold %"). Dieses Handbuch wurde entsprechend aktualisiert.

Als zweiter, fachlich unabhängiger Baustein enthält die Erweiterung **SellWatch**: Ankaufsanfragen für gebrauchte Uhren, die vom Partner SellWatch eingehen, werden automatisiert zu Lieferant und Einkaufsbestellung verarbeitet (Codeunit 60305 "CXW SellWatch Mgt"); eine schreibgeschützte Übersichtsseite (Page 60307 "CXW SellWatch-Overview") zeigt Verkäufer-, Uhren- und Bestelldaten. Ein separater Mechanismus prüft per HTTP, ob eine Uhr im SellWatch-Onlineshop sichtbar ist (Table 60301 "CXW Watch Online Approval"), und protokolliert jeden Aufruf inklusive Fehlertelemetrie (Table 60302 "CXW Http Call Log", Page 60309). SellWatch und die Verkaufspreisverwaltung sind fachlich getrennt, teilen sich aber dieselbe Schnittstellen-Stammdatentabelle "CXW API Interface Setup" (Table 60317) sowie seit dem HTTP-Logging-Update das gemeinsame Protokoll `"CXW Http Call Log"`: der Online-Check verwendet dort den fest verdrahteten Code `'WOA'`.

> **Update 2026-08-10 (HTTP-Call-Logging vereinheitlicht):** Table 60302/Page 60309 hießen zuvor `"CXW SW Http Call Log"` und waren fest mit `"CXW Watch Online Approval"` verdrahtet. Umbenannt in `"CXW Http Call Log"` (Caption `'Http Call Log'`) und um ein neues Feld `"CXW Source Table No."` (gleiches Muster wie `"CXW API Interface Setup"."CXW Source Table No."`) ergänzt, sodass `"CXW Source Entry No"` je nach `"CXW Source Table No."` wahlweise auf `"CXW Watch Online Approval"` (60301) oder `"CXW Sales Price Outbound File"` (60314) verweist. `Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface` protokolliert seither jeden Aufruf (Erfolg, Non-Success-HTTP-Status, Netzwerkfehler) im selben Protokoll wie SellWatch, inklusive Redigierung des `Authorization`-Headers (analog zur bestehenden `X-API-KEY`-Redigierung bei SellWatch). Beide Permission Sets (`CXWChronWSAll`, `CXW SWChronWSAll`) wurden entsprechend angepasst.

> **Update 2026-08-10:** Ebenfalls am 2026-08-10 wurden die 11 SellWatch-Objekte (bisher IDs 51001–51010, uneinheitliche Präfixe „SW"/„SellWatch"/kein Präfix) als reines Rename/Renumber in den registrierten idRange-Block 60300–60310 verschoben und einheitlich mit „CXW " präfixiert, ebenso die rund 70 von ihnen definierten Felder. Feld-Captions, Enum-Werte und Geschäftslogik sind unverändert (siehe `openspec/changes/archive/2026-08-10-sellwatch-cxw-renumbering/`). IDs 60311–60349 waren zu diesem Zeitpunkt bereits für die Verkaufspreisverwaltung reserviert bzw. belegt; SellWatch nutzt seither 60300–60310, der Rest von 60300–60349 bleibt für künftige Objekte frei.

## Technischer Stack

| Komponente | Technologie | Version |
|---|---|---|
| Erweiterungstyp | Microsoft Dynamics 365 Business Central (AL) | Platform/Application 26.0.0.0 |
| Runtime | AL Runtime | 17.0 |
| Objekt-ID-Bereich | Kundenbereich | 60300–60349 (genutzt: 60300–60310 SellWatch, 60311–60336 Verkaufspreisverwaltung); 51000–51049 bleibt registriert, wird aber seit dem Rename vom 2026-08-10 von keinem Objekt dieser Erweiterung mehr belegt |
| Abhängigkeiten | – | keine (`dependencies: []` in `app.json`) |
| Publisher | Salini Life | – |
| Extension-ID | `5df32934-5708-418c-ba16-44b30feb51f4` | – |

## Projektstruktur

```
app.json                          # Extension-Manifest, idRanges 51000-51049 + 60300-60349
src/
  Tables/                         # 10 Tabellen (60300-60302 SellWatch; 60311-60313, 60314-60317 Verkaufspreisverwaltung)
  TableExtensions/                # 5 Erweiterungen (Purchase Line, Purchase Header – SellWatch; Country/Region, Sales Price, Currency – Verkaufspreisverwaltung)
  PageExtensions/                 # 3 Erweiterungen (Countries/Regions, Sales Prices, Currencies) – nur Verkaufspreisverwaltung
  Pages/                          # 7 Seiten + 1 Xmlport (60307-60309 SellWatch; 60321-60324 + Xmlport 60328 Verkaufspreisverwaltung)
  Codeunits/                      # 3 Codeunits (SellWatch Mgt – SellWatch; Export Gateway Sales Price, Import Sales Prices – Verkaufspreisverwaltung)
  Enums/                          # 7 Enums (SW Order Status – SellWatch; 6 weitere – Verkaufspreisverwaltung)
  PermissionSets/                 # 2 Permission Sets (CXW SWChronWSAll – SellWatch; CXWChronWSAll – Verkaufspreisverwaltung)
Translations/                     # .g.xlf (generiert) + de-DE.xlf (gepflegt)
openspec/
  specs/                          # dauerhafte Capability-Spezifikationen (z.B. sales-price-currency-copy, sellwatch-http-call-logging, sellwatch-standard-table-extensions)
  changes/                        # laufende und archivierte Change-Proposals
docs/                             # dieses Handbuch + Funktionsregister
```

**Namenskonvention der Dateien:** `Tab<ID>.<PascalCaseName>.al`, `Pag<ID>.<Name>.al`, `TabExt<ID>.<Name>.al`, `PagExt<ID>.<Name>.al`, `Enum<ID>.<Name>.al`, `Codeunit<ID>.<Name>.al`, `XmlPort<ID>.<Name>.al`.

## Lokale Entwicklungsumgebung einrichten

### Voraussetzungen

- Visual Studio Code mit der offiziellen **AL Language**-Extension.
- Zugriff auf eine Business-Central-Umgebung (Sandbox oder On-Premises) mit Version 26.0 oder kompatibel.
- Die Symbole der Zielumgebung (`.alpackages/`, wird per "Download Symbols" der AL-Extension erzeugt, ist per `.gitignore` von der Versionierung ausgeschlossen).

### Installation

```bash
# Symbole der Zielumgebung herunterladen (in VS Code Command Palette):
AL: Download Symbols

# Projekt kompilieren (VS Code Command Palette):
AL: Package (Kompilieren)

# In verbundene Umgebung veröffentlichen:
AL: Publish
```

Ein Build-/Test-Skript (`Makefile`, `npm`-Scripts o.ä.) existiert in diesem Projekt nicht – der Build läuft ausschließlich über die AL-Extension bzw. AL-Go-Pipelines, falls diese separat eingerichtet werden.

### Konfiguration

Keine Umgebungsvariablen im klassischen Sinn. Relevante Konfiguration erfolgt über `app.json` (`idRanges`, `features: ["NoImplicitWith","TranslationFile"]`) sowie zur Laufzeit über die Tabelle **"CXW General Sales Price Setup"** (siehe Key-User-Handbuch).

## Architektur

```
CSV-Datei
   │  Action "Import CSV"
   ▼
Xmlport 60328 "CXW Import Sales Price"
   │  schreibt Zeilen in
   ▼
Table 60312 "CXW Sales Price Checking"  ◄── Page 60322 "CXW Sales Price Checking List"
   │  (Item No./Currency Code – kein eigener Länder-        (Validate / Approve / Add all Currencies /
   │   code und kein Variantencode mehr auf dieser Tabelle)   Upload Sales Price)
   │
   │  Action "Upload Sales Price" → Codeunit 60329 "CXW Export Gateway Sales Price"
   │
   ├─► WriteBackAndArchive: legt Standardtabelle "Sales Price" neu an bzw.
   │      aktualisiert sie (Sales Type = All Customers) und fügt eine neue,
   │      hochgezählte Version in Table 60313 "CXW Sales Price Archive" ein
   │      (Ansicht über Page 60323, nur lesend)
   │
   └─► CreateExternalInterfaceFile: wandelt den "Sales Price"-Datensatz per
          Reflection in JSON um, legt ihn in Table 60314 "CXW Sales Price
          Outbound File" ab und sendet ihn per HttpClient an den in Table
          60317 "CXW API Interface Setup" (Page 60324) hinterlegten Endpunkt –
          ausgewählt über das Feld "CXW API Interface Code" auf Table 60311.
          SendToApiInterface protokolliert seit dem HTTP-Logging-Update jeden
          Aufruf (Erfolg, Non-Success-Status, Netzwerkfehler) in Table 60302
          "CXW Http Call Log" ("CXW Source Table No." = 60314), Authorization-
          Header redigiert – dasselbe Protokoll, das SellWatch für seinen
          Online-Check nutzt (siehe unten). Seit dem AWS-SigV4-Update unterstützt
          "CXW Auth Type" (Enum 60335) neben None/ApiKeyHeader/BasicAuth auch
          AWSSigV4: SendToApiInterface signiert die Anfrage dann selbst per
          AWS Signature Version 4 (Authorization- und X-Amz-Date-Header, optional
          X-Amz-Security-Token bei temporären/STS-Credentials) – benötigte
          Zusatzfelder auf Table 60317 (siehe Tabellenübersicht unten); Details
          zum Signieralgorithmus siehe
          `openspec/changes/sales-price-aws-sigv4-auth/design.md`.

Steuerdaten für "Add all Currencies":
Table Extension "CXWCurrency" (auf Standard-Tabelle "Currency", Feld "CXW Sales Price Activated")
   ◄── Page Extension "CXWCurrencies" (auf Standard-Seite "Currencies")

Land/Region liefert nur noch informative Zusatzangaben (Besteuerungsart, Lieferzeit,
Standard-Fremdwährung) über Table Extension "CXW Country Region" / Page Extension
"CXW Country Region Card" – keine Aktivierungslogik mehr.

Unabhängiger, nicht produktiv angebundener Baustein:
Datei (CSV) → Table 60315 "CXW Sales Price Inbound File"
            → Codeunit 60330 "CXW Import Sales Prices" (OnRun)
            → schreibt direkt in Standard-Tabelle "Sales Price"
            → Fehler in Table 60316 "CXW Price Import Protocol"
```

### SellWatch

```
Table 60300 "CXW SellWatch Vendor Info" (Zeilen extern angelegt – kein
Xmlport/API-Page dafür im Projekt gefunden; Berechtigung dazu über das
Permission Set 60310 "CXW SWChronWSAll")
   │
   │  Codeunit 60305 "CXW SellWatch Mgt".OnRun → ValidateAndCreateVendor
   │  (Trigger selbst ist nicht im AL-Code verdrahtet – kein Installations-
   │   Codeunit, kein Job-Queue-Eintrag, kein Event-Subscriber im Projekt
   │   gefunden; siehe Bekannte Einschränkungen)
   ▼
Zeilen mit "CXW Created" = false:
   ├─► sucht per Name/Address/Phone No./E-Mail einen bestehenden "Vendor";
   │      legt sonst einen neuen "Vendor" + "Vendor Bank Account" an
   │      (Bankverbindungscode = letzte 4 Stellen der IBAN + Währungscode)
   │
   └─► CreatePurchaseOrder: legt "Purchase Header" (Document Type = Order)
          und eine "Purchase Line" an – Item No./Variant Code abhängig von
          "CXW Offer Type" (C2C-SW / CPST-SW / TI-SW), Menge 1, Amount und
          "Direct Unit Cost" = "CXW Final Offer Price", "CXW Used good" = true
          (Table Extension 60303 auf "Purchase Line") – gibt die Bestellung
          über Codeunit "Release Purchase Document" (PerformManualRelease)
          frei und markiert die Vendor-Info-Zeile als "CXW Created" = true,
          "CXW PO Number"/"CXW VendorNo" befüllt

Unabhängig davon, je Artikel/Variante:
Table 60301 "CXW Watch Online Approval"
   │  CreateEntryInexternalFile (aktuell aus keiner anderen Stelle im
   │  Code aufgerufen)
   ▼
HTTP GET an <Endpoint URL>/<Item No>/<Variant Code>/check, Header
"X-API-KEY" – Endpoint/Key aus Table 60317 "CXW API Interface Setup",
Code fest verdrahtet auf 'WOA' (dieselbe Tabelle wie die Verkaufspreis-
verwaltung, siehe Codeunit 60329)
   │  Antwortfeld "shouldBeOnline" = 'TRUE' → setzt "CXW Check Online" +
   │  ggf. "CXW First Online Date"; sonst "CXW Remark" = 'Watch is offline'
   └─► protokolliert jeden Aufruf (Erfolg wie Fehlschlag, API-Key im
          gespeicherten Request-Text redigiert) in Table 60302
          "CXW Http Call Log" ("CXW Source Table No." = 60301); bei
          Fehlschlag zusätzlich Telemetrie (Session.LogMessage,
          Event-ID 'SW-0101')

Ansicht (read-only, kein Insert/Modify/Delete über die Seiten):
Page 60307 "CXW SellWatch-Overview" (Liste, SourceTable Table 60300,
   Filter "CXW SRid" <> '', Aktion "Show Document" öffnet die Purchase Order)
Page 60308 "CXW SellWatch info" (CardPart auf Table 60300 – Uhren-Detaildaten)
Page 60309 "CXW Http Call Log" (Liste, SourceTable Table 60302 – jetzt
   gemeinsames Protokoll für SellWatch UND Verkaufspreisverwaltung,
   Spalte "CXW Source Table No." unterscheidet die Quelle; Aktionen
   "Download Request"/"Download Response" laden den jeweiligen Blob als .txt)

JSON-Builder ohne aktuellen Aufrufer im Projekt (vermutlich für externe
Rückmeldungen an SellWatch gedacht, siehe Bekannte Einschränkungen):
Codeunit 60305: CreateSourceFilePurchaseRequest(Purchase Header): Text
Codeunit 60305: CreateSourceFileOrderStatusSE(SellWatch Vendor Info; Enum
   "CXW SW Order Status"): Text
```

## Objektschnittstellen (öffentliche Prozeduren & Events)

Vollständige Liste aller Prozeduren, Trigger und Events: siehe `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`. Die wichtigsten öffentlichen Schnittstellen:

| Objekt | Element | Zweck |
|---|---|---|
| Codeunit 60329 | `WriteBackAndArchive(SalesPriceChecking: Record "CXW Sales Price Checking"; var SalesPrice: Record "Sales Price")` | Schreibt/aktualisiert einen "Sales Price"-Datensatz aus einer freigegebenen Preiszeile (Sales Type = All Customers) und archiviert eine neue Version. `[TryFunction]` – ein Fehlschlag wird abgefangen und als `false` zurückgemeldet, statt den gesamten Batch des Aufrufers abzubrechen. |
| Codeunit 60329 | `CreateExternalInterfaceFile(SalesPrice: Record "Sales Price"): Boolean` | Wandelt einen "Sales Price"-Datensatz per Reflection in JSON um, legt ihn in Table 60314 ab, sendet ihn an die konfigurierte API-Schnittstelle und protokolliert den Aufruf in Table 60302 "CXW Http Call Log". |
| Page 60322 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Berechnet den Nicht-Lagerpreis für Zeilen innerhalb einer Preisspanne. Aktuell aus keiner aktiven Stelle im Code aufgerufen. |
| Codeunit 60330 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Wird ausgelöst, wenn der automatisierte Dateiimport einen bestehenden Verkaufspreis ändert. Aktuell ohne Subscriber. |
| Table 60317 | `SetApiKey(NewApiKey: Text)` / `GetApiKey(): Text` | Speichert/liest den API-Schlüssel einer Schnittstelle im Isolated Storage (Modul-Scope) statt in einem Klartext-Tabellenfeld. |
| Codeunit 60305 | `OnRun` / `ValidateAndCreateVendor` (lokal) | Verarbeitet alle Table-60300-Zeilen mit "CXW Created" = false: Lieferant + Bankverbindung anlegen/finden, Einkaufsbestellung erzeugen und freigeben. Kein Aufrufer dieses `OnRun` im Projekt gefunden (siehe Bekannte Einschränkungen). |
| Codeunit 60305 | `CreateSourceFilePurchaseRequest(PurchaseHeader: Record "Purchase Header"): Text` | Baut das JSON für eine Bestellrückmeldung (SRid, purchase_order, optional tracking_number). Aktuell aus keiner anderen Stelle im Code aufgerufen. |
| Codeunit 60305 | `CreateSourceFileOrderStatusSE(SellWatchInfo: Record "CXW SellWatch Vendor Info"; Status: Enum "CXW SW Order Status"): Text` | Baut das JSON für eine Statusmeldung an SellWatch (Name, E-Mail, Uhrendaten, Link zur Online-Freigabe, Auszahlungswährung/-betrag aus der archivierten Einkaufszeile). Aktuell aus keiner anderen Stelle im Code aufgerufen. |
| Table 60301 | `CreateEntryInexternalFile(var WOA: Record "CXW Watch Online Approval")` | Fragt per HTTP GET beim SellWatch-Endpunkt ab, ob eine Uhr online sein sollte, aktualisiert die Zeile entsprechend und protokolliert den Aufruf in Table 60302 ("CXW Source Table No." = 60301). Aktuell aus keiner anderen Stelle im Code aufgerufen. |

Vollständige Liste aller Objekte mit Funktionsanzahl: siehe `docs/funktionsregister/gesamtuebersicht.md`.

## Tabellenübersicht (Kurzreferenz)

| Tabelle | Primärschlüssel | Zweck |
|---|---|---|
| 60300 CXW SellWatch Vendor Info | Entry No | Eingehende SellWatch-Ankaufsanfrage: Verkäufer-, Bank-, Uhren- und Angebotsdaten; "CXW Created" markiert, ob Lieferant/Bestellung bereits automatisiert angelegt wurden; FlowField "CXW Tracking Number" liest aus Table Extension 60304 auf "Purchase Header" |
| 60301 CXW Watch Online Approval | Entry No | Ergebnis der Online-Sichtbarkeitsprüfung je Artikel/Variante ("CXW Check Online", "CXW First Online Date", "CXW Remark"); FlowField "CXW SRid" liest "Vendor Order No." der zugehörigen Bestellung |
| 60302 CXW Http Call Log | Entry No | Gemeinsames Protokoll jedes HTTP-Aufrufs von `CreateEntryInexternalFile` (SellWatch) UND `SendToApiInterface` (Verkaufspreis-Export) – Erfolg/Fehlschlag, Statuscode, redigierter Request, Response als Blob; "CXW Source Table No." (60301 bzw. 60314) + "CXW Source Entry No" identifizieren die auslösende Zeile |
| 60311 CXW General Sales Price Setup | Primary Key (Singleton) | Grundeinstellungen, inkl. Export-Schalter und ausgewählter API-Schnittstelle |
| 60312 CXW Sales Price Checking | Item No., Currency Code | Zwischenablage für Import/Prüfung/Freigabe |
| 60313 CXW Sales Price Archive | + Version No. | Historie; wird bei "Upload Sales Price" (Page 60322) über Codeunit 60329 automatisch befüllt, Version No. je Item No./Currency Code hochgezählt |
| 60314 CXW Sales Price Outbound File | Entry No. | Gesendete JSON-Nutzdaten mit Versandstatus und Antworttext, zur Fehleranalyse fehlgeschlagener Übertragungen |
| 60315 CXW Sales Price Inbound File | Entry No. | Für automatisierten Dateiimport (nicht produktiv angebunden) |
| 60316 CXW Price Import Protocol | Entry No. | Fehlerprotokoll zum automatisierten Import (fachlich weiterhin das Sales-Price-Import-Protokoll; „Sales" im technischen Bezeichner wegen des 30-Zeichen-Limits von AL entfallen) |
| 60317 CXW API Interface Setup | Code | Endpunkt-URL, Authentifizierungsart und (im Isolated Storage abgelegter) API-Schlüssel je externer Schnittstelle; bei "CXW Auth Type" = AWSSigV4 zusätzlich AWS Access Key ID/Region/Service (Klartextfelder) sowie AWS Secret Access Key/Session Token (im Isolated Storage) |

## Permission Set

Das Permission Set **`CXWChronWSAll`** (ID 60336, `src/PermissionSets/CXWChronWSAll.permissionset.al`) deckt Lese-/Schreibzugriff auf alle sieben Tabellen der Verkaufspreisverwaltung sowie – seit dem HTTP-Logging-Update – auf das mit SellWatch geteilte Table 60302 "CXW Http Call Log" ab, dazu Ausführungsrechte für beide Codeunits, Xmlport 60328 und die fünf Seiten (die vier der Verkaufspreisverwaltung plus Page 60309 "CXW Http Call Log"). Tabellenerweiterungen und Seitenerweiterungen benötigen keine eigenen Einträge, da sie über die Berechtigung des jeweiligen Basisobjekts (z. B. Standard-Zugriff auf "Currency"/"Country/Region") mit abgedeckt sind; die Standardtabelle "Sales Price", in die Codeunit 60329 schreibt, ist ebenso über die Base-App-Berechtigungen abgedeckt, nicht über dieses Set. Das Set muss noch aktiv einer Benutzergruppe zugewiesen werden.

Für SellWatch deckt das separate Permission Set **`CXW SWChronWSAll`** (ID 60310, `src/PermissionSets/CXWSWChronWSAll.permissionset.al`) RIMD-Zugriff auf die beiden SellWatch-eigenen Tabellen (60300–60301) sowie das mit der Verkaufspreisverwaltung geteilte Table 60302 "CXW Http Call Log" ab, dazu Ausführungsrechte für Codeunit 60305 und die drei SellWatch-Seiten (60307–60309, wobei Page 60309 "CXW Http Call Log" ebenfalls geteilt ist). Die Table Extensions 60303/60304 auf "Purchase Line"/"Purchase Header" benötigen wie bei der Verkaufspreisverwaltung keinen eigenen Eintrag, da sie über die Standardberechtigung auf die jeweilige Basistabelle mit abgedeckt sind. Auch dieses Set muss noch aktiv einer Benutzergruppe zugewiesen werden.

## Tests ausführen

Es existieren aktuell **keine** AL-Testcodeunits in diesem Projekt. Als Grundlage für zukünftige Tests eignet sich die Spezifikation `openspec/specs/sales-price-currency-copy/spec.md` (10 Szenarien für die Aktion "Add all Currencies") – zu beachten ist, dass diese Spezifikation vor der Umstellung von Land- auf Currency-Aktivierung entstand und vor Testerstellung gegen den aktuellen Stand geprüft werden sollte. Für SellWatch liefern `openspec/specs/sellwatch-http-call-logging/spec.md` (Szenarien für Erfolgs-/Fehlschlag-Logging, API-Key-Redaktion und Telemetrie von `CreateEntryInexternalFile`) und `openspec/specs/sellwatch-standard-table-extensions/spec.md` (Szenarien für "CXW Used good" und "CXW Tracking Number") eine vergleichbare Grundlage.

## Deployment

Kein CI/CD-Setup (z. B. AL-Go-Workflow) im Projekt gefunden. Deployment erfolgt aktuell manuell über "AL: Publish" aus VS Code in die Zielumgebung.

## Beitragen / Konventionen

- Alle neuen Objekte erhalten IDs im registrierten Bereich **60300–60349** (siehe `app.json`, `idRanges`; der ältere Bereich 51000–51049 bleibt zwar registriert, wird aber seit dem Rename vom 2026-08-10 nicht mehr belegt), pro Objekttyp unabhängig gezählt.
- Der Code enthält bewusst **keine** Kommentare (auf ausdrücklichen Kundenwunsch entfernt) – fachliche Hintergründe und Design-Entscheidungen werden stattdessen in diesem Handbuch und im Funktionsregister dokumentiert. Bei Änderungen bitte diesen Stil beibehalten und Kontext hier statt im Code ergänzen.
- Abgeschlossene, funktionale Änderungen werden als OpenSpec-Change dokumentiert (`openspec/changes/`, nach Fertigstellung archiviert unter `openspec/changes/archive/`) und als dauerhafte Spezifikation unter `openspec/specs/` abgelegt.
- Übersetzungen: `.g.xlf` wird durch den Compiler erzeugt und darf **nicht** manuell editiert werden; Pflege erfolgt ausschließlich in `Translations/SL Chronext Webshop.de-DE.xlf`.

## Bekannte Einschränkungen

- **"Approve" selbst übernimmt Preise nicht in die Standardtabelle "Sales Price" oder in "CXW Sales Price Archive".** Die Aktion setzt nur die Freigabe-Kennzeichen auf Table 60312. Die Übernahme erfolgt erst im nachgelagerten Schritt "Upload Sales Price" (Page 60322, Codeunit 60329), der vor der Dateierzeugung sowohl "Sales Price" (Sales Type = All Customers) als auch "CXW Sales Price Archive" (mit hochgezählter Version No.) beschreibt.
- **(Behoben am 2026-08-10) `"CXW Unit Price (LCY)"` wurde nie automatisch befüllt** – `WriteBackAndArchive` schrieb bislang nur das Standardfeld `"Unit Price"`, während `fnValidate` auf Page 60322 beim Vergleich mit dem vorherigen Preis durch `"CXW Unit Price (LCY)"` dividierte. Da dieses Feld bei jedem automatisiert geschriebenen Datensatz `0` blieb, führte jeder zweite "Validate"-Lauf für ein bereits einmal hochgeladenes Artikel/Währungs-Paar zuverlässig zu `Attempted to divide by zero.` und brach den gesamten Batch ab. Seit `Codeunit 60329`.`ResolveUnitPriceLCY` befüllt `WriteBackAndArchive` das Feld bei jedem Schreiben automatisch (Umrechnung über den auf der Preiszeile bereits erfassten Wechselkurs bzw. per Fallback-Lookup); zusätzlich überspringt `fnValidate` den Vergleich statt zu dividieren, wenn der vorherige Datensatz noch `0` enthält. Bereits vor dem Fix geschriebene "Sales Price"-Datensätze bleiben bei `0`, bis sie das nächste Mal über "Upload Sales Price" neu geschrieben werden – kein rückwirkendes Backfill (siehe `openspec/changes/archive/2026-08-10-sales-price-unit-price-lcy-autofill/design.md`).
- **`Reason Code` als Enum ohne echten Leerwert**: Das Enum hat immer einen Default-Wert (`CatMan`), es gibt keinen Zustand "kein Grund angegeben".
- **Dateibasierter Import (Codeunit 60330, Tables 60315–60316)** ist vollständig implementiert, aber an keiner Stelle produktiv verdrahtet oder terminiert (kein Job Queue Eintrag). `WriteSalesPrices` ruft `SalesPrice.Get(...)` jetzt mit genau den 8 echten Primärschlüsselfeldern der Standardtabelle "Sales Price" auf (verifiziert anhand der Symbole in `.alpackages/Microsoft_Base Application_*.app`), mit `''` für "Variant Code" – die zuvor dokumentierte Schlüssel-Abweichung ist damit behoben.
- **Keine automatisierten Tests** vorhanden.
- **Der eigentliche Auslöser von Codeunit 60305 "CXW SellWatch Mgt".OnRun ist nicht Teil des AL-Quellcodes.** Im Projekt existiert weder ein Installations-/Upgrade-Codeunit noch ein Event-Subscriber noch eine API-Page, die `OnRun` aufruft oder Zeilen in Table 60300 einfügt. In der Praxis muss die Ausführung daher über einen zur Laufzeit angelegten Job-Queue-Eintrag, einen manuellen Aufruf oder eine außerhalb dieses Codes liegende Integration erfolgen; das steht nicht im Widerspruch zur im Benutzerhandbuch beschriebenen automatisierten Verarbeitung, ist im Code selbst aber nicht nachvollziehbar.
- **`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE` (Codeunit 60305) und `CreateEntryInexternalFile` (Table 60301, für den eigentlichen Online-Check) werden aktuell von keiner anderen Stelle im Projekt aufgerufen.** Insbesondere die beiden JSON-Builder wirken wie vorbereitete, aber (noch) nicht angebundene Rückmeldungen an SellWatch.
- **`CreatePurchaseOrderinBV` und `CreatePurchaseOrderinGmBH` (Codeunit 60305, beide lokal)** sind ebenfalls nicht aufgerufen – Reste der im Quellsystem laut Code-Kommentar bereits deaktivierten GMBH/BV-Fallunterscheidung. `ReadJSONFile` (Table 60301, lokal) ist ein leerer Stub ohne Funktion.
- **Artikel-/Variantencodes für SellWatch-Einkaufszeilen sind fest im Code hinterlegt** (`C2C-SW`, `CPST-SW`, `TI-SW`, abhängig von "CXW Offer Type"). Existiert der jeweilige Artikel/die Variante nicht im Artikelstamm, schlägt `PLRec.Validate("No.", ...)` in `CreatePurchaseOrder` fehl; es gibt keine Konfigurationsseite für diese Zuordnung.
- **Der Online-Check (`CreateEntryInexternalFile`) verwendet einen fest verdrahteten Schnittstellen-Code `'WOA'`** auf Table 60317 "CXW API Interface Setup" – derselben Tabelle, die auch die Verkaufspreisverwaltung für ihren Preisexport nutzt (dort über das konfigurierbare Feld "CXW API Interface Code"). Für SellWatch ist der Code nicht konfigurierbar, sondern muss exakt `'WOA'` lauten.
