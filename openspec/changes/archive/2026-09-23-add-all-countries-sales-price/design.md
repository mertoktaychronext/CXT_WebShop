## Context

Heutiger Stand (verifiziert am Code):

- Page 60322 "CXW Sales Price Checking List", Aktion "Add all Currencies" (`Pag60322.CXWSalesPriceCheckingList.al`, Zeilen 251–333): iteriert alle Prüfzeilen mit `"CXW Currencies Processed" = false`, darin alle `Currency`-Datensätze mit `"CXW Sales Price Activated" = true` (plus ein Überbleibsel-Filter `Code <> 'DE'` auf der Währungstabelle) und legt pro Währung eine Zeile an. Umrechnung: `Preis * (1 / Wechselkurs)` via `GetLastestExchangeRate`, d. h. die Quellzeile wird implizit als Mandantenwährung angenommen.
- Table 60312 "CXW Sales Price Checking": PK `("CXW Item No.", "CXW Currency Code")`, kein Länderfeld. Page `OnOpenPage` führt `Rec.DeleteAll()` aus — die Tabelle ist ein Arbeitsblatt, Daten sind flüchtig.
- Table 60313 "CXW Sales Price Archive": PK `("CXW Item No.", "CXW Currency Code", "CXW Version No.")`, dauerhafte Daten. Wird per `TransferFields` aus der Prüfzeile befüllt (gleiche Feld-IDs).
- Codeunit 60329: `WriteBackAndArchive` schreibt `"Sales Price"` (Schlüssel ohne Land) pro Währung; `CreateExternalInterfaceFile(SalesPrice)` serialisiert alle Felder des `"Sales Price"`-Datensatzes per RecordRef ins JSON.
- `Country/Region` wird von CHX.Base (60203 "CXB Country Region Ext.") nur um eine Kreditoren-Vorlage erweitert — keine Verkaufspreisfelder. Eine frühere "SL Country Region"-Erweiterung existiert im Code nicht mehr.
- Freie Objekt-IDs im Bereich 60300–60349: 60310, 60346–60349.

Entscheidungen der Anwenderin (Rückfrage bei der Proposal-Erstellung): Pflege auf `Country/Region`, Currency-Aktivierung entfällt; auch Länder in Quellwährung erhalten eine Zeile; Land wird ins JSON und Archiv übernommen, `"Sales Price"` bleibt pro Währung.

## Goals / Non-Goals

**Goals:**
- "Add all Currencies" durch "Add all Countries" ersetzen: eine Zeile pro aktiviertem Land mit dessen Verkaufspreiswährung.
- Länderzuordnung durchgängig: Einrichtung (Country/Region) → Prüfzeile → Archiv → JSON-Export.
- Bestehende Schutzmechanismen (Setup-Prüfung, "Nothing to process", Idempotenz) und Feldübernahme unverändert beibehalten.

**Non-Goals:**
- Kein Land in der Standardtabelle `"Sales Price"` (PK nicht erweiterbar; Werte je Währung sind für alle Länder identisch).
- Keine Umrechnung von Fremdwährungs-Quellzeilen über die MW hinweg (siehe Risiken) — bisheriges Umrechnungsverhalten bleibt.
- Kein Land im CSV-Import; importierte Zeilen sind immer Quellzeilen ohne Land.
- Keine Datenmigration der Currency-Aktivierung auf Länder (Einrichtung erfolgt manuell).
- `fnValidate` (Marge/Schwellwert/Altpreis) bleibt unverändert; die Validierung läuft ohnehin vor der Expansion.

## Decisions

### 1. Neue Objekte auf `Country/Region` statt Wiederverwendung von Currency-IDs
Table Extension **60346 "CXW Country/Region"** (extends `Country/Region`) mit Feldern 60300 `"CXW Sales Price Activated"` (Boolean) und 60301 `"CXW Sales Price Currency Code"` (Code[10], `TableRelation = Currency`). Page Extension **60347 "CXW Countries/Regions"** (extends `Countries/Regions`) zeigt beide Felder mit ToolTips.
Table Extension 60320 und Page Extension 60327 (Currency) werden gelöscht, nicht obsolet markiert — PTE, keine Abhängigen, gleiche Policy wie `remove-country-code`.
*Alternative*: IDs 60320/60327 für die neuen Erweiterungen umwidmen. Verworfen — eine Objekt-ID mit wechselndem Zielobjekt erschwert Schema-Sync und Nachvollziehbarkeit.

### 2. `"CXW Country Code"` als Feld 27 in Checking und Archiv, Teil des PK
Feld-ID 27 auf beiden Tabellen (Checking nutzt bis 26; Archiv hat 24–26 nicht, 27 ist dort frei) — damit bleibt `TransferFields` ohne Zusatzcode korrekt. Keine Wiederverwendung von Feld 2 (früher belegt, anderer Typ möglich).
- Checking-PK: `("CXW Item No.", "CXW Currency Code", "CXW Country Code")`
- Archiv-PK: `("CXW Item No.", "CXW Currency Code", "CXW Country Code", "CXW Version No.")`
Das Land wird hinten angehängt, damit bestehende Filter/Sortierungen auf Artikel+Währung ein Schlüsselpräfix bleiben. `TableRelation = "Country/Region"`, kein `NotBlank` (leer = Quellzeile).

### 3. Quellzeile = Zeile mit leerem Land
Die Expansion filtert `"CXW Country Code" = ''` und `"CXW Countries Processed" = false`. Generierte Zeilen tragen immer ein Land und werden damit nie Quellzeile — das behebt nebenbei, dass die heutige Schleife frisch eingefügte Zeilen (mit `Processed = false`) während desselben `FindSet` erneut erwischen kann.
Die Quellzeile selbst bleibt als Basiszeile bestehen und wird wie bisher exportiert (JSON mit leerem Land).

### 4. Zeilenerzeugung und Umrechnung
Schleife über `Country/Region` mit `SetRange("CXW Sales Price Activated", true)`. Pro Land:
- `ZielWährung := Country."CXW Sales Price Currency Code"`
- Existenzprüfung per `Get(Item, ZielWährung, Country.Code)` → überspringen, falls vorhanden.
- `ZielWährung = Quellzeile."CXW Currency Code"` → Preise und Wechselkursfelder 1:1 kopieren.
- sonst → bestehende Umrechnung (`GetLastestExchangeRate`, `Preis * (1 / Kurs)`, `"CXW Exchange Rate Amount" := 1 / Kurs`, `"CXW Exchange Rate Date"`) unverändert übernehmen. Ist kein Wechselkurs vorhanden, wird die Zeile wie heute ohne Preise angelegt.
- Feldübernahme-Block (Datum/Zeit, Reason Code, Comment, Approved By, Accept New Setup, Validated := true) unverändert.
Die Logik wandert aus dem `OnAction`-Trigger in eine lokale Prozedur `fnAddAllCountries()` (+ Hilfsprozedur `CreateCountryLine(Quelle, Land)`), um den Trigger lesbar zu halten; Stil (Präfixe `g_rec…`/`l_rec…`, Labels) bleibt wie in der Page.

### 5. Umbenennung `"CXW Currencies Processed"` → `"CXW Countries Processed"`
Gleiche Feld-ID 24, gleiche Semantik, neue Caption "Countries Processed". Feldumbenennung ist in AL bei gleicher ID schemakompatibel.

### 6. Export: Land als Parameter, nicht aus `"Sales Price"`
`CreateExternalInterfaceFile(SalesPrice; CountryCode: Code[10])` fügt nach der RecordRef-Serialisierung `JsonObj.Add('CXW Country Code', CountryCode)` hinzu; Dateiname `SalesPrice_<Item>_<Currency>_<Country>.json`. Die Upload-Aktion übergibt `l_recSalesPriceCheck."CXW Country Code"`. `WriteBackAndArchive` schreibt `"Sales Price"` unverändert pro Währung — mehrere Länder derselben Währung überschreiben denselben Datensatz mit identischen Werten (generierte Zeilen sind nach Genehmigung nicht mehr änderbar, `OnModifyRecord`).
`ArchiveCheckingLine` ergänzt `SetRange("CXW Country Code", …)` für die Versionsermittlung.

### 7. XmlPort 60328
`SourceTableView = sorting("CXW Item No.", "CXW Currency Code", "CXW Country Code")`; kein neues fieldelement.

## Risks / Trade-offs

- **[Risiko] PK-Änderung am Archiv (Table 60313) mit Bestandsdaten** → Das neue Feld ist bei Bestandsdaten leer; der erweiterte Schlüssel ist eine Obermenge des alten, daher keine Kollisionen. Schema-Sync im Modus "ForceSync" kann trotzdem nötig sein. *Mitigation*: vor Publish in Sandbox testen; bei Ablehnung Upgrade-Codeunit nachziehen.
- **[Risiko] Entfernen von `Currency."CXW Sales Price Activated"` verwirft gepflegte Aktivierungen** → *Mitigation*: vor Deployment die aktivierten Währungen notieren und die Länder entsprechend einrichten (Hinweis im Key-User-Handbuch).
- **[Risiko] Zielsystem der Preis-API** erhält ein neues JSON-Feld und mehr Datensätze pro Artikel → *Mitigation*: Abstimmung mit dem Empfänger vor Go-Live (in tasks.md als Aufgabe).
- **[Risiko] Fremdwährungs-Quellzeilen**: Die Umrechnung setzt wie bisher eine MW-Quellzeile voraus; eine CHF-Quellzeile würde für EUR-Länder falsch umgerechnet → unverändertes Altverhalten, im Entwicklerhandbuch als bekannte Einschränkung dokumentiert.
- **[Trade-off] Mehr Zeilen in der Prüfliste** (Länder statt Währungen) → gewollt; die neue Spalte "Country Code" macht die Zeilen unterscheidbar.
- **[Trade-off] `"Sales Price"` wird bei n Ländern gleicher Währung n-mal mit identischen Werten geschrieben** → akzeptiert, vermeidet Sonderlogik.

## Migration Plan

1. Deployment mit Schema-Sync (Checking-Tabelle ist flüchtig; Archiv erhält leeres Land für Altdaten).
2. Key User richtet auf "Countries/Regions" die Verkaufspreis-Länder samt Währung ein.
3. Rollback: Revert der Dateien; die Currency-Aktivierung muss dann neu gepflegt werden, Archivzeilen mit Land kollidieren nach Rückbau ggf. im alten PK → Rollback nur vor erstem produktivem Export ohne Aufwand.

## Open Questions

- Erwartet das Zielsystem den Ländercode im ISO-Format (`ISO Code` aus `Country/Region`) statt des BC-Codes? Annahme: BC-Code; bei Bedarf Folge-Change.
