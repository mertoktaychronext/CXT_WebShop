# Entwicklerhandbuch – SL Chronext Webshop

## Überblick

Diese Business-Central-Erweiterung (AL) bildet die Verwaltung von Webshop-Verkaufspreisen ab: CSV-Import in eine Zwischenablage-Tabelle, fachliche Prüfung (Marge, Preisschwankungen), Freigabe durch einen Sachbearbeiter, optional die automatische Vervielfältigung eines Preises auf alle aktivierten Fremdwährungen, und das Hochladen freigegebener Preise an ein externes System. Die Aktion "Upload Sales Price" schreibt jeden freigegebenen Preis in die Standardtabelle "Sales Price" und als versionierten Eintrag in "CXW Sales Price Archive", bevor er an eine konfigurierbare API-Schnittstelle gesendet wird. Ein zweiter, unabhängiger Baustein für dateibasierten Preisimport (nicht produktiv angebunden) rundet das Projekt ab. Das Projekt ist eine Migration aus einem gewachsenen Dynamics-NAV-Altsystem in modernes, SaaS-fähiges AL.

> **Update 2026-08-10:** Alle 26 Objekte dieser Erweiterung (bisher IDs 51000–51007, Präfix „SL") wurden reinen Rename/Renumber-Charakters in den registrierten idRange-Block 60311–60336 (Präfix „CXW") verschoben, ebenso alle von ihnen definierten Felder (Präfix „CXW "/„CXW"). Geschäftslogik, Verhalten und Feld-Captions sind unverändert. Zwei Bezeichner mussten wegen des 30-Zeichen-Limits von AL zusätzlich gekürzt werden: Table 60316 „CXW Price Import Protocol" (ohne „Sales" im Bezeichner) und das Feld „CXW Non Stock Price Thresh %" auf Table 60311 (Caption weiterhin "Non Stock Price Threshold %"). Dieses Handbuch wurde entsprechend aktualisiert.

Als zweiter, fachlich unabhängiger Baustein enthält die Erweiterung **SellWatch**: Ankaufsanfragen für gebrauchte Uhren, die vom Partner SellWatch eingehen, werden automatisiert zu Lieferant und Einkaufsbestellung verarbeitet (Codeunit 60305 "CXW SellWatch Mgt"); eine schreibgeschützte Übersichtsseite (Page 60307 "CXW SellWatch-Overview") zeigt Verkäufer-, Uhren- und Bestelldaten. Ein separater Mechanismus prüft per HTTP, ob eine Uhr im SellWatch-Onlineshop sichtbar ist (Table 60301 "CXW Watch Online Approval"), und protokolliert jeden Aufruf inklusive Fehlertelemetrie (Table 60302 "CXW Http Call Log", Page 60309). SellWatch und die Verkaufspreisverwaltung sind fachlich getrennt, teilen sich aber dieselbe Schnittstellen-Stammdatentabelle "CXW API Interface Setup" (Table 60317) sowie seit dem HTTP-Logging-Update das gemeinsame Protokoll `"CXW Http Call Log"`: der Online-Check verwendet dort den fest verdrahteten Code `'WOA'`.

Als dritter, ebenfalls fachlich unabhängiger Baustein enthält die Erweiterung die **Workshop-Ankaufsprüfung** (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60340, Codeunit 60331, PermissionSets 60301/60302): Angekaufte Uhren werden nach Ankunft über die Aktion "Send to Workshop" auf der Purchase-Order-Page an eine externe Werkstatt übergeben (inkl. Erfassung der Herstellerseriennummer), die per bidirektionaler Custom-API (Page 60339, OAuth2-S2S-authentifiziert) Echtheit und Artikelmerkmale zurückmeldet. Eine job-queue-gesteuerte Codeunit (60331) verarbeitet geprüfte Zeilen: bei bestätigter Echtheit wird nur der Wareneingang gebucht und die gemeldeten Attribute werden als Standard-Artikelattribute übernommen; bei widerlegter Echtheit wird die Bestellung storniert. Details siehe Abschnitt "Workshop-Ankaufsprüfung" unten.

> **Update 2026-08-13 (Workshop-Ankaufsprüfung nachdokumentiert):** Die Workshop-Ankaufsprüfung existierte bereits seit einer früheren Erweiterung, war aber in keinem der drei Handbücher dokumentiert. Dieses Update ergänzt sie in allen drei Handbüchern (DE/EN) sowie im `docs/README.md`; zusätzlich wurde die veraltete Aussage zu fest hinterlegten SellWatch-Variantencodes korrigiert (siehe Bekannte Einschränkungen) – keine Code-Änderungen.

> **Update 2026-08-10 (HTTP-Call-Logging vereinheitlicht):** Table 60302/Page 60309 hießen zuvor `"CXW SW Http Call Log"` und waren fest mit `"CXW Watch Online Approval"` verdrahtet. Umbenannt in `"CXW Http Call Log"` (Caption `'Http Call Log'`) und um ein neues Feld `"CXW Source Table No."` (gleiches Muster wie `"CXW API Interface Setup"."CXW Source Table No."`) ergänzt, sodass `"CXW Source Entry No"` je nach `"CXW Source Table No."` wahlweise auf `"CXW Watch Online Approval"` (60301) oder `"CXW Sales Price Outbound File"` (60314) verweist. `Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface` protokolliert seither jeden Aufruf (Erfolg, Non-Success-HTTP-Status, Netzwerkfehler) im selben Protokoll wie SellWatch, inklusive Redigierung des `Authorization`-Headers (analog zur bestehenden `X-API-KEY`-Redigierung bei SellWatch). Beide Permission Sets (`CXWChronWSAll`, `CXW SWChronWSAll`) wurden entsprechend angepasst.

> **Update 2026-08-10:** Ebenfalls am 2026-08-10 wurden die 11 SellWatch-Objekte (bisher IDs 51001–51010, uneinheitliche Präfixe „SW"/„SellWatch"/kein Präfix) als reines Rename/Renumber in den registrierten idRange-Block 60300–60310 verschoben und einheitlich mit „CXW " präfixiert, ebenso die rund 70 von ihnen definierten Felder. Feld-Captions, Enum-Werte und Geschäftslogik sind unverändert (siehe `openspec/changes/archive/2026-08-10-sellwatch-cxw-renumbering/`). IDs 60311–60349 waren zu diesem Zeitpunkt bereits für die Verkaufspreisverwaltung reserviert bzw. belegt; SellWatch nutzt seither 60300–60310, der Rest von 60300–60349 bleibt für künftige Objekte frei.

## Technischer Stack

| Komponente | Technologie | Version |
|---|---|---|
| Erweiterungstyp | Microsoft Dynamics 365 Business Central (AL) | Platform/Application 26.0.0.0 |
| Runtime | AL Runtime | 17.0 |
| Objekt-ID-Bereich | Kundenbereich | 60300–60349 (genutzt: 60300–60310 SellWatch, 60311–60336 Verkaufspreisverwaltung, 60318–60340 Workshop-Ankaufsprüfung – Objekttypen überschneiden sich, da jeder Objekttyp einen eigenen ID-Namensraum hat); 51000–51049 bleibt registriert, wird aber seit dem Rename vom 2026-08-10 von keinem Objekt dieser Erweiterung mehr belegt |
| Abhängigkeiten | – | keine (`dependencies: []` in `app.json`) |
| Publisher | Salini Life | – |
| Extension-ID | `5df32934-5708-418c-ba16-44b30feb51f4` | – |

## Projektstruktur

```
app.json                          # Extension-Manifest, idRanges 51000-51049 + 60300-60349
src/
  Tables/                         # 11 Tabellen (60300-60302 SellWatch; 60311-60317 Verkaufspreisverwaltung; 60318 Workshop)
  TableExtensions/                # 5 Erweiterungen (Purchase Line, Purchase Header – SellWatch; Sales Price, Currency – Verkaufspreisverwaltung; Purchase Line – Workshop)
  PageExtensions/                 # 4 Erweiterungen (Sales Prices, Currencies – Verkaufspreisverwaltung; Purchase Order, Purchase Order Subform – Workshop)
  Pages/                          # 12 Seiten + 1 Xmlport (60307-60309 + 60337 SellWatch; 60321-60325 + Xmlport 60328 Verkaufspreisverwaltung; 60338-60340 Workshop)
  Codeunits/                      # 4 Codeunits (SellWatch Mgt – SellWatch; Export Gateway Sales Price, Import Sales Prices – Verkaufspreisverwaltung; Process Workshop Lines – Workshop)
  Enums/                          # 8 Enums (SW Order Status – SellWatch; 6 weitere – Verkaufspreisverwaltung; Workshop Line Status – Workshop)
  PermissionSets/                 # 5 Permission Sets (CXW SWChronWSAll, CXW Sell Watch API – SellWatch; CXWChronWSAll – Verkaufspreisverwaltung; CXW Workshop All, CXW Workshop API – Workshop)
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
          60317 "CXW API Interface Setup" (Übersicht: Page 60324; Detaileinrichtung
          je Schnittstelle inkl. HTTP-Methode/SOAPAction/Authentifizierung:
          Page 60325 "CXW API Interface Setup Card", per Drilldown auf den Code
          oder Aktion "Edit Details" aus Page 60324 erreichbar) hinterlegten Endpunkt –
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
          `openspec/changes/sales-price-aws-sigv4-auth/design.md`. Seit dem
          Conditional-Fields-Update blendet Page 60325 "CXW API Interface Setup
          Card" die authentifizierungsspezifischen Felder (API Key, alle
          AWS-Felder) je nach gewähltem "CXW Auth Type" ein/aus, gesteuert über
          die neuen Table-60317-Prozeduren `IsApiKeyFieldRelevant()` /
          `IsAwsFieldsRelevant()` – dieselben Prozeduren, die auch die
          Aktivierungssperre auf "CXW Active" verwendet, damit beide Stellen
          nicht auseinanderlaufen können. Page 60324 selbst zeigt nur noch die
          Übersichtsspalten (Code, Description, Endpoint URL, Auth Type,
          Active); Details siehe
          `openspec/changes/api-interface-setup-conditional-fields/design.md`.

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
Table 60300 "CXW SellWatch Vendor Info" (Zeilen extern angelegt – über
Page 60337 "CXW SellWatch API" (PageType = API, siehe unten) oder direkt
in der Tabelle; Berechtigung dazu über das Permission Set 60310
"CXW SWChronWSAll")
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

#### Page 60337 "CXW SellWatch API" – Schreibzugang für externe Systeme

Ergänzt die reine Anzeige-Seite 60307 um einen `PageType = API`-Endpunkt, über den externe Systeme per HTTP-Aufruf neue SellWatch-Anfragen anlegen oder bestehende ändern können. Beide Seiten liegen über derselben Tabelle 60300, sind aber unabhängige Objekte (eine Page kann nicht gleichzeitig `List` und `API` sein).

- **Endpunkt-Muster:** `.../api/saliniLife/sellWatch/v2.0/companies({companyId})/sellWatchVendorInfos` (Standard-BC-OData-v4-Muster aus `APIPublisher`/`APIGroup`/`APIVersion`/`EntitySetName`); einzelner Datensatz per `.../sellWatchVendorInfos({id})`.
- **Methoden:** `POST` zum Anlegen, `PATCH` zum Ändern; `DELETE` ist nicht erlaubt (`DeleteAllowed = false`).
- **Authentifizierung:** Standard-BC-API-Authentifizierung (Web Service Access Key oder Entra-ID-OAuth) – keine eigene Auth-Logik im AL-Code. Berechtigung zusätzlich über Permission Set 60310 "CXW SWChronWSAll" (Eintrag `page "CXW SellWatch API" = X`).
- **Beschreibbare Felder:** alle Vendor-/Uhren-/Angebotsfelder (u. a. Vendor Name, Adresse, IBAN/BIC, E-Mail, Brand/Model/Reference/SKU, Watch Condition, Offer Type, Final Offer Price, Currency Code, SRid).
- **Nicht beschreibbar (system-eigen):** `CXW Entry No` (Primärschlüssel), `CXW Created`, `CXW PO Number`, `CXW VendorNo` (werden ausschließlich von Codeunit 60305 gesetzt) sowie das FlowField `CXW Tracking Number`. Werte für diese Felder im Payload werden beim Insert/Modify ignoriert bzw. zurückgesetzt.
- **Validierung:** `OnInsertRecord`/`OnModifyRecord` verlangen `CXW SRid`, `CXW Brand`, `CXW Model` und `CXW Final Offer Price` und lehnen ein doppeltes `CXW SRid` mit einem Fehler (HTTP 4xx) ab, statt den Datensatz unvollständig oder doppelt anzulegen.
- Neu angelegte/aktualisierte Zeilen erscheinen unverändert auf Page 60307 und werden von Codeunit 60305 wie manuell erfasste Zeilen weiterverarbeitet.

### Workshop-Ankaufsprüfung

```
Purchase Order (Sachbearbeiter)
   │  Aktion "Send to Workshop" (PageExtension 60328 "CXW Workshop
   │  Purchase Order", auf Page "Purchase Order")
   ▼
Je offener Zeile (Type = Item, Quantity <> 0, Sent to Workshop = false):
   ├─► Confirm "Ist Artikel {No.} {Description} wirklich angekommen?"
   │     Nein → "CXW Not Arrived" := true, Zeile übersprungen (kein Abbruch)
   │     Ja   → Page 60340 "CXW Serial No. Input" (StandardDialog, modal)
   │              Pflichtfeld Herstellerseriennummer; leer/Abbruch → Fehler
   │              für diese Zeile gesammelt, weiter mit nächster Zeile
   ▼
Bei gültiger Eingabe:
   "CXW Manufacturer Serial No." + "CXW Sent to Workshop" := true auf
   Purchase Line (TableExtension 60321 "CXW Workshop Purchase Line")
   ▼
Table 60318 "CXW Workshop Line" neu angelegt (PK: Document Type/No./
Line No.), Status = New, Item No. aus der Purchase Line übernommen
   │
   │  PageExtension 60329 "CXW Workshop Purch Order Subf" sperrt ab
   │  "Sent to Workshop" = true die Standardfelder der Zeile (Editable = false)
   ▼
Externe Werkstatt liest/schreibt über
Page 60339 "CXW Workshop Line API" (PageType = API, OAuth2-S2S,
   Endpunkt-Muster .../api/saliniLife/workshop/v1.0/companies({companyId})/
   workshopLines; Insert/Delete gesperrt, Statusrückschritte gesperrt)
   │  Werkstatt setzt: isAuthentic, Attribute 1-10, Status = "WS checked"
   ▼
Codeunit 60331 "CXW Process Workshop Lines" (job-queue-gesteuert, OnRun
   → ProcessCheckedLines, SetRange Status = "WS checked")
   │  pro Zeile: ProcessLineWithErrorHandling kapselt TryProcessLine
   │  ([TryFunction]) – ein Fehlschlag blockiert nicht die übrigen Zeilen
   │
   ├─► Genuine = true → ProcessGenuineLine:
   │      "Qty. to Receive" = Bestellmenge, Codeunit "Purch.-Post"
   │      (Receive = true, Invoice = false), danach GetAttributeMapping
   │      überträgt Attribute 1-8 (fachlich benannt: Dial Color, Case
   │      Diameter, Bracelet Material, Case Material, Movement, Gender,
   │      Crystal, Features; 9-10 weiterhin Platzhalter) als Standard-
   │      Artikelattribute (Item Attribute/Item Attribute Value/Item
   │      Attribute Value Mapping, fehlende Einträge automatisch als
   │      Typ Text angelegt) → Status = "Processed", "CXW Last Error" := ''
   │
   ├─► Genuine = false → ProcessNonGenuineLine:
   │      Status = "Processed" (bewusst VOR dem PO-Löschen gesetzt, damit
   │      der Cascade-Delete-Schutz in TabExt60321 greift), danach
   │      Purchase Order ggf. reopened und gelöscht
   │
   └─► Fehlschlag (beliebige Stelle im Verarbeitungspfad) → Status = Error
          (nur aus "WS checked" heraus erlaubt, sonst OnModify-Fehler),
          "CXW Last Error" = GetLastErrorText(); Commit() nach jeder Zeile
          sichert bereits erfolgreiche Zeilen unabhängig vom Ausgang der
          nächsten

Ansicht (read-only): Page 60338 "CXW Workshop Lines" (Liste, alle Felder
   inkl. Status, Attribute, Last Error)

Löschverhalten (TableExtension 60321, OnDelete der Purchase Line):
   Workshop Line im Status New/WS checked → wird mitgelöscht
   Workshop Line im Status Processed → bleibt als Prüfnachweis bestehen
```

#### Page 60339 "CXW Workshop Line API" – bidirektionaler Zugang für die Werkstatt

Im Unterschied zu Page 60337 (SellWatch, reiner Insert/Update-Empfang) erlaubt diese API sowohl Lesen (offene Zeilen) als auch Schreiben (Prüfergebnis) durch dieselbe externe Partei.

- **Endpunkt-Muster:** `.../api/saliniLife/workshop/v1.0/companies({companyId})/workshopLines`.
- **Methoden:** `GET` zum Abholen, `PATCH` zum Zurückschreiben; `POST`/`DELETE` gesperrt (`InsertAllowed = false`, `DeleteAllowed = false`) – Zeilen entstehen ausschließlich aus BC heraus über "Send to Workshop".
- **Beschreibbare Felder:** `dialColor`, `caseDiameter`, `braceletMaterial`, `caseMaterial`, `movement`, `gender`, `crystal`, `features` (fachlich benannt, entsprechen den AL-Feldbezeichnern 1–8), `attribute9`, `attribute10` (weiterhin generisch, da ohne fachlichen Namen), `genuine`, `status`. Schlüssel-, Artikel- und Seriennummernfelder sind gesperrt (`OnModifyRecord` lehnt Änderungsversuche mit Fehler ab).
- **Update 2026-08-13 (Breaking Change):** Die OData-Eigenschaftsnamen `attribute1`–`attribute8` wurden auf die fachlichen Namen umgestellt (z. B. `attribute1` → `dialColor`). Anders als bei der internen AL-Feldbezeichner-Umbenennung zuvor ist dies eine **Breaking Change am externen API-Vertrag** – der externe Workshop-Dienst muss seine Integration entsprechend anpassen. `attribute9`/`attribute10` bleiben unverändert, da für sie noch kein fachlicher Name vorliegt.
- **Statusrückschritte gesperrt:** greift über den `OnModify`-Trigger der Tabelle selbst (feuert unabhängig davon, ob die Änderung über die API oder intern erfolgt) – `WS checked` → `New` sowie jeder Wechsel weg von `Processed` werden abgelehnt; ein direkter Wechsel auf `Error` ist nur aus `WS checked` heraus erlaubt.
- **Berechtigung:** Permission Set 60302 "CXW Workshop API" – ausschließlich `tabledata "CXW Workshop Line" = RM`, kein Zugriff auf Purchase Line, Item oder andere Tabellen.

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
| Codeunit 60331 | `OnRun` / `ProcessCheckedLines` (lokal) | Job-Queue-Einstiegspunkt; verarbeitet alle Table-60318-Zeilen mit Status "WS checked" einzeln über `ProcessLineWithErrorHandling`. |
| Codeunit 60331 | `ProcessLineWithErrorHandling` / `TryProcessLine` (beide lokal) | Kapselt die Verarbeitung einer einzelnen Zeile als `[TryFunction]`; bei Fehlschlag wird Status auf `Error` gesetzt und `GetLastErrorText()` in "CXW Last Error" geschrieben, ohne die Verarbeitung der übrigen Zeilen zu blockieren (`Commit()` nach jeder Zeile). |
| Codeunit 60331 | `GetAttributeMapping(AttributeIndex: Integer): Text[250]` (lokal) | Zentrale, austauschbare Zuordnung Attributindex → Name des Standard-Artikelattributs; Index 1–8 liefert die fachlichen Namen (Dial Color, Case Diameter, …), Index 9–10 weiterhin Platzhalter "Attribut 9"/"Attribut 10". |

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
| 60318 CXW Workshop Line | Document Type, Document No., Line No. | Ein Datensatz je an die Werkstatt übergebener Bestellzeile: Item No., Manufacturer Serial No., Status (Enum 60337: New/WS checked/Processed/Error), isAuthentic (Echtheits-Kennzeichen), acht fachlich benannte Attributfelder (Dial Color … Features) + zwei Platzhalter (Attribut 9/10), Created At, Checked At, Last Error |

## Permission Set

Das Permission Set **`CXWChronWSAll`** (ID 60336, `src/PermissionSets/CXWChronWSAll.permissionset.al`) deckt Lese-/Schreibzugriff auf alle sieben Tabellen der Verkaufspreisverwaltung sowie – seit dem HTTP-Logging-Update – auf das mit SellWatch geteilte Table 60302 "CXW Http Call Log" ab, dazu Ausführungsrechte für beide Codeunits, Xmlport 60328 und die fünf Seiten (die vier der Verkaufspreisverwaltung plus Page 60309 "CXW Http Call Log"). Tabellenerweiterungen und Seitenerweiterungen benötigen keine eigenen Einträge, da sie über die Berechtigung des jeweiligen Basisobjekts (z. B. Standard-Zugriff auf "Currency"/"Country/Region") mit abgedeckt sind; die Standardtabelle "Sales Price", in die Codeunit 60329 schreibt, ist ebenso über die Base-App-Berechtigungen abgedeckt, nicht über dieses Set. Das Set muss noch aktiv einer Benutzergruppe zugewiesen werden.

Für SellWatch deckt das separate Permission Set **`CXW SWChronWSAll`** (ID 60310, `src/PermissionSets/CXWSWChronWSAll.permissionset.al`) RIMD-Zugriff auf die beiden SellWatch-eigenen Tabellen (60300–60301) sowie das mit der Verkaufspreisverwaltung geteilte Table 60302 "CXW Http Call Log" ab, dazu Ausführungsrechte für Codeunit 60305 und die drei SellWatch-Seiten (60307–60309, wobei Page 60309 "CXW Http Call Log" ebenfalls geteilt ist). Die Table Extensions 60303/60304 auf "Purchase Line"/"Purchase Header" benötigen wie bei der Verkaufspreisverwaltung keinen eigenen Eintrag, da sie über die Standardberechtigung auf die jeweilige Basistabelle mit abgedeckt sind. Auch dieses Set muss noch aktiv einer Benutzergruppe zugewiesen werden.

Für die Workshop-Ankaufsprüfung gibt es zwei getrennte Permission Sets: **`CXW Workshop All`** (ID 60301, `src/PermissionSets/CXWWorkshopAll.permissionset.al`) für den vollständigen internen Zugriff auf Table 60318, alle Workshop-Seiten und Codeunit 60331 – inklusive der für Wareneingang, Stornierung und Artikelattribute benötigten Standardtabellen (Purchase Header/Line, Item, Item Attribute, Item Attribute Value, Item Attribute Value Mapping), damit die Job-Queue-Codeunit eigenständig lauffähig ist – und **`CXW Workshop API`** (ID 60302, `src/PermissionSets/CXWWorkshopAPI.permissionset.al`) als schlankes Gegenstück ausschließlich für den externen Workshop-Benutzer: nur `tabledata "CXW Workshop Line" = RM`, kein Insert/Delete, kein Zugriff auf Purchase Line oder Item. Beide Sets müssen noch aktiv zugewiesen werden (`CXW Workshop All` an interne Sachbearbeiter/den Job-Queue-Ausführungsbenutzer, `CXW Workshop API` ausschließlich an den dedizierten OAuth2-S2S-Benutzer der Werkstatt).

## Tests ausführen

Es existieren aktuell **keine** AL-Testcodeunits in diesem Projekt. Als Grundlage für zukünftige Tests eignet sich die Spezifikation `openspec/specs/sales-price-currency-copy/spec.md` (10 Szenarien für die Aktion "Add all Currencies") – zu beachten ist, dass diese Spezifikation vor der Umstellung von Land- auf Currency-Aktivierung entstand und vor Testerstellung gegen den aktuellen Stand geprüft werden sollte. Für SellWatch liefern `openspec/specs/sellwatch-http-call-logging/spec.md` (Szenarien für Erfolgs-/Fehlschlag-Logging, API-Key-Redaktion und Telemetrie von `CreateEntryInexternalFile`) und `openspec/specs/sellwatch-standard-table-extensions/spec.md` (Szenarien für "CXW Used good" und "CXW Tracking Number") eine vergleichbare Grundlage. Für die Workshop-Ankaufsprüfung liegen die Szenarien noch verteilt auf mehrere, teils noch nicht archivierte OpenSpec-Changes (`openspec/changes/purchase-workshop-integration/specs/` sowie die darauf aufbauenden Deltas in `openspec/changes/archive/2026-08-13-workshop-line-error-handling/` und `openspec/changes/archive/2026-08-13-workshop-attribute-*`) – vor einer Testerstellung sollten diese zu einer konsolidierten Spec unter `openspec/specs/workshop-line-processing/` zusammengeführt werden (siehe Bekannte Einschränkungen).

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
- **(Behoben, danach wieder zurückgesetzt) SellWatch-Artikelanlage nutzt eine Artikelvorlage statt fester Variantencodes, die Auswahl der Vorlage ist aber weiterhin nicht konfigurierbar.** Ursprünglich waren Artikel-/Variantencodes für SellWatch-Einkaufszeilen fest im Code hinterlegt (`C2C-SW`, `CPST-SW`, `TI-SW`); das wurde durch eine dynamische Artikelanlage per Artikelvorlage ersetzt (`CreateSellWatchItem`, Codeunit 60305, `Item.TransferFields(ItemTemplate, true)`). Welche Artikelvorlage dabei verwendet wird, ist aber weiterhin **nicht** konfigurierbar: der Code nimmt per `ItemTemplate.FindFirst()` ohne Filter einfach die erste beliebige Artikelvorlage aus der Tabelle "Item Templ." – bei mehr als einer angelegten Vorlage im System ist das Ergebnis nicht vorhersehbar. Ein Change (`sellwatch-item-template-setup`), der dafür ein Einrichtungsfeld auf der Purchases & Payables Setup vorsah, wurde entworfen und implementiert, aber die unkommitteten Code-Änderungen gingen vor dem Commit verloren (nur die OpenSpec-Planungsdokumente sind unter `openspec/changes/archive/2026-08-13-sellwatch-item-template-setup/` erhalten) – bei Bedarf erneut umsetzen. Der zugehörige `// TODO: Item Template einrichtenbar, Wo?` im Code ist weiterhin offen.
- **Der Online-Check (`CreateEntryInexternalFile`) verwendet einen fest verdrahteten Schnittstellen-Code `'WOA'`** auf Table 60317 "CXW API Interface Setup" – derselben Tabelle, die auch die Verkaufspreisverwaltung für ihren Preisexport nutzt (dort über das konfigurierbare Feld "CXW API Interface Code"). Für SellWatch ist der Code nicht konfigurierbar, sondern muss exakt `'WOA'` lauten.
- **Workshop-Ankaufsprüfung deckt nur den Standardfall "eine Purchase Order = eine Purchase Line" ab.** Gemischte Bestellungen (mehrere Zeilen, teils echt/teils nicht echt) sind nicht implementiert – bei Nicht-Echtheit storniert `ProcessNonGenuineLine` (Codeunit 60331) aktuell die *gesamte* Purchase Order, auch wenn nur eine von mehreren Zeilen betroffen wäre (`// TODO:`-markiert im Code).
- **Zwei der zehn Workshop-Attributfelder (Attribut 9/10) haben weiterhin keine fachliche Bezeichnung** (Platzhalter-Captions), im Unterschied zu den bereits benannten Attributen 1–8 (Dial Color … Features).
- **Die Basis-Spezifikation der Workshop-Ankaufsprüfung ist nicht sauber archiviert.** Der ursprüngliche Change `purchase-workshop-integration` (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60340, Codeunit 60331, PermissionSets 60301/60302) liegt fehlplatziert unter `openspec/changes/archive/2026-08-13-workshop-line-error-handling/purchase-workshop-integration/` statt an einer regulären, datierten Archiv-Stelle und ist für `openspec list`/`openspec status` unsichtbar (Stand: 30/34 Tasks). Mehrere spätere Changes (`workshop-line-error-handling`, `workshop-attribute-names`, `workshop-attribute-field-names`) liefern Delta-Specs gegen die Capabilities `workshop-line-processing`/`workshop-line-api`, die dadurch nie zu einer kanonischen Spec unter `openspec/specs/` konsolidiert wurden. Vor weiteren Änderungen an der Workshop-Verarbeitung sollte dies bereinigt werden.
