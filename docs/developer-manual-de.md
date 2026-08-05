# Entwicklerhandbuch – SL Chronext Webshop

## Überblick

Diese Business-Central-Erweiterung (AL) bildet die Verwaltung von Webshop-Verkaufspreisen ab: CSV-Import in eine Zwischenablage-Tabelle, fachliche Prüfung (Marge, Preisschwankungen), Freigabe durch einen Sachbearbeiter, und optional die automatische Vervielfältigung eines Preises auf alle aktivierten Fremdwährungen. Ein zweiter, unabhängiger Baustein für dateibasierten Preisimport (nicht produktiv angebunden) rundet das Projekt ab. Das Projekt ist eine Migration aus einem gewachsenen Dynamics-NAV-Altsystem in modernes, SaaS-fähiges AL.

## Technischer Stack

| Komponente | Technologie | Version |
|---|---|---|
| Erweiterungstyp | Microsoft Dynamics 365 Business Central (AL) | Platform/Application 26.0.0.0 |
| Runtime | AL Runtime | 17.0 |
| Objekt-ID-Bereich | Kundenbereich | 51000–51049 |
| Abhängigkeiten | – | keine (`dependencies: []` in `app.json`) |
| Publisher | Salini Life | – |
| Extension-ID | `5df32934-5708-418c-ba16-44b30feb51f4` | – |

## Projektstruktur

```
app.json                          # Extension-Manifest, idRanges 51000-51049
src/
  Tables/                         # 5 Tabellen (51000, 51001, 51002, 51005, 51006)
  TableExtensions/                # 3 Erweiterungen (Country/Region, Sales Price, Currency)
  PageExtensions/                 # 3 Erweiterungen (Countries/Regions, Sales Prices, Currencies)
  Pages/                          # 3 Seiten + 1 Xmlport
  Codeunits/                      # 1 Codeunit (Import Sales Prices)
  Enums/                          # 3 Enums
  PermissionSets/                 # 1 Permission Set (SLChronWSAll)
Translations/                     # .g.xlf (generiert) + de-DE.xlf (gepflegt)
openspec/
  specs/                          # dauerhafte Capability-Spezifikationen (z.B. sales-price-currency-copy)
  changes/archive/                # abgeschlossene, archivierte Change-Proposals
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

Keine Umgebungsvariablen im klassischen Sinn. Relevante Konfiguration erfolgt über `app.json` (`idRanges`, `features: ["NoImplicitWith","TranslationFile"]`) sowie zur Laufzeit über die Tabelle **"SL General Sales Price Setup"** (siehe Key-User-Handbuch).

## Architektur

```
CSV-Datei
   │  Action "Import CSV"
   ▼
Xmlport 51000 "SL Import Sales Price"
   │  schreibt Zeilen in
   ▼
Table 51001 "SL Sales Price Checking"  ◄── Page 51001 "SL Sales Price Checking List"
   │  (Item No./Variant Code/Currency Code, kein eigener      (Validate / Approve / Add all Currencies)
   │   Ländercode mehr auf dieser Tabelle)
   │
   └─► Table 51002 "SL Sales Price Archive"        (nur lesend über Page 51002 genutzt;
                                                      automatische Befüllung derzeit inaktiv,
                                                      siehe "Bekannte Einschränkungen")

Steuerdaten für "Add all Currencies":
Table Extension "SLCurrency" (auf Standard-Tabelle "Currency", Feld "Sales Price Activated")
   ◄── Page Extension "SLCurrencies" (auf Standard-Seite "Currencies")

Land/Region liefert nur noch informative Zusatzangaben (Besteuerungsart, Lieferzeit,
Standard-Fremdwährung) über Table Extension "SL Country Region" / Page Extension
"SL Country Region Card" – keine Aktivierungslogik mehr.

Unabhängiger, nicht produktiv angebundener Baustein:
Datei (CSV) → Table 51005 "SL Sales Price Inbound File"
            → Codeunit 51001 "SL Import Sales Prices" (OnRun)
            → schreibt direkt in Standard-Tabelle "Sales Price"
            → Fehler in Table 51006 "SL Sales Price Import Protocol"
```

## Objektschnittstellen (öffentliche Prozeduren & Events)

Vollständige Liste aller Prozeduren, Trigger und Events: siehe `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`. Die wichtigsten öffentlichen Schnittstellen:

| Objekt | Element | Zweck |
|---|---|---|
| Page 51001 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Berechnet den Nicht-Lagerpreis für Zeilen innerhalb einer Preisspanne. Aktuell aus keiner aktiven Stelle im Code aufgerufen. |
| Codeunit 51001 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Wird ausgelöst, wenn der automatisierte Dateiimport einen bestehenden Verkaufspreis ändert. Aktuell ohne Subscriber. |

## Tabellenübersicht (Kurzreferenz)

| Tabelle | Primärschlüssel | Zweck |
|---|---|---|
| 51000 SL General Sales Price Setup | Primary Key (Singleton) | Grundeinstellungen |
| 51001 SL Sales Price Checking | Item No., Variant Code, Currency Code | Zwischenablage für Import/Prüfung/Freigabe |
| 51002 SL Sales Price Archive | + Country Code, Version No. | Historie (aktuell nur lesend genutzt) |
| 51005 SL Sales Price Inbound File | Entry No. | Für automatisierten Dateiimport (nicht produktiv angebunden) |
| 51006 SL Sales Price Import Protocol | Entry No. | Fehlerprotokoll zum automatisierten Import |

> Hinweis: Table 51002 "SL Sales Price Archive" führt aus historischen Gründen weiterhin einen eigenen Ländercode – das Archiv wurde bei der Umstellung von Land auf Währung (Table 51001) nicht mit umgestellt, da es aktuell ohnehin nicht automatisch befüllt wird.

## Permission Set

Das Permission Set **`SLChronWSAll`** (ID 51000, `src/PermissionSets/SLChronWSAll.permissionset.al`) deckt Lese-/Schreibzugriff auf alle fünf Tabellen sowie Ausführungsrechte für Codeunit 51001, Xmlport 51000 und die drei Seiten der Erweiterung ab. Tabellenerweiterungen und Seitenerweiterungen benötigen keine eigenen Einträge, da sie über die Berechtigung des jeweiligen Basisobjekts (z. B. Standard-Zugriff auf "Currency"/"Country/Region") mit abgedeckt sind. Das Set muss noch aktiv einer Benutzergruppe zugewiesen werden.

## Tests ausführen

Es existieren aktuell **keine** AL-Testcodeunits in diesem Projekt. Als Grundlage für zukünftige Tests eignet sich die Spezifikation `openspec/specs/sales-price-currency-copy/spec.md` (10 Szenarien für die Aktion "Add all Currencies") – zu beachten ist, dass diese Spezifikation vor der Umstellung von Land- auf Currency-Aktivierung entstand und vor Testerstellung gegen den aktuellen Stand geprüft werden sollte.

## Deployment

Kein CI/CD-Setup (z. B. AL-Go-Workflow) im Projekt gefunden. Deployment erfolgt aktuell manuell über "AL: Publish" aus VS Code in die Zielumgebung.

## Beitragen / Konventionen

- Alle neuen Objekte erhalten IDs im Bereich **51000–51049** (siehe `app.json`, `idRanges`), pro Objekttyp unabhängig gezählt.
- Der Code enthält bewusst **keine** Kommentare (auf ausdrücklichen Kundenwunsch entfernt) – fachliche Hintergründe und Design-Entscheidungen werden stattdessen in diesem Handbuch und im Funktionsregister dokumentiert. Bei Änderungen bitte diesen Stil beibehalten und Kontext hier statt im Code ergänzen.
- Abgeschlossene, funktionale Änderungen werden als OpenSpec-Change dokumentiert (`openspec/changes/`, nach Fertigstellung archiviert unter `openspec/changes/archive/`) und als dauerhafte Spezifikation unter `openspec/specs/` abgelegt.
- Übersetzungen: `.g.xlf` wird durch den Compiler erzeugt und darf **nicht** manuell editiert werden; Pflege erfolgt ausschließlich in `Translations/SL Chronext Webshop.de-DE.xlf`.

## Bekannte Einschränkungen

- **Codeunit 51000 "SL Export Gateway Sales Price" existiert nicht mehr** – sie wurde bewusst entfernt, da nicht benötigt. Damit fehlt die Anbindung, die freigegebene Preise automatisch an ein externes System übergeben hätte.
- **Nach "Approve" werden Preise nicht automatisch in die Standardtabelle "Sales Price" oder in "SL Sales Price Archive" übernommen.** Die Aktion setzt nur die Freigabe-Kennzeichen auf Table 51001; eine Übernahme in die produktiven Verkaufspreise ist aktuell nicht implementiert.
- **`Reason Code` als Enum ohne echten Leerwert**: Das Enum hat immer einen Default-Wert (`CatMan`), es gibt keinen Zustand "kein Grund angegeben".
- **Dateibasierter Import (Codeunit 51001, Tables 51005–51006)** ist vollständig implementiert, aber an keiner Stelle produktiv verdrahtet oder terminiert (kein Job Queue Eintrag).
- **Keine automatisierten Tests** vorhanden.
- **Tabelle 51002 "SL Sales Price Archive"** führt weiterhin einen eigenen Ländercode statt eines Währungscodes (siehe Tabellenübersicht oben) – bei einer künftigen Aktivierung der automatischen Archivierung sollte geprüft werden, ob das Archivschema an das Currency-Modell von Table 51001 angeglichen werden soll.
