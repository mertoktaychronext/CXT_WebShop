## Why

Der Verfügbarkeitsexport (Codeunit 60347 "CXW Export Availability Changes") protokolliert jeden erfolgreich gesendeten Payload bereits in der ChronextBC-Tabelle **"Data Export Entry"** (50103). Der SalesPrice-Export (Codeunit 60329 "CXW Export Gateway Sales Price") nutzt dafür dagegen eine eigene Tabelle "CXW Sales Price Outbound File" (60314). Damit gibt es für ausgehende Webshop-Payloads zwei getrennte Protokolle mit unterschiedlicher Oberfläche. Der SalesPrice-Export soll dieselbe Protokollstelle verwenden wie der Verfügbarkeitsexport, damit Key User alle ausgehenden Payloads an einer Stelle ("Data Export Entries", Page 50108) sehen — inklusive JSON-Payload-FactBox und Filteransichten.

Die Endpunkt-Konfiguration ("CXW API Interface Setup" inkl. AWS SigV4 und SOAPAction) bleibt bewusst unverändert, weil "Data Export API Setup" AWS SigV4 nicht abbilden kann.

## What Changes

- Der SalesPrice-Export schreibt pro gesendeter Prüfzeile einen Eintrag in **"Data Export Entry"** statt in "CXW Sales Price Outbound File": JSON-Payload, Dateiname (`SalesPrice_<Artikel>_<Währung>_<Land>.json`), Destination Code `SALESPRICE`, Source Record ID, Status `Processed` bzw. `Error`, Fehlermeldung, Versuchszähler und Zeitstempel.
- Einträge des SalesPrice-Exports verbleiben **nie** im Status `Waiting to Process`, damit der ChronextBC-Job "Data Export Mgt." (50102) sie nicht zusätzlich über "Data Export API Sender" versendet.
- Die HTTP-Protokollierung ("CXW Http Call Log") verweist künftig auf den "Data Export Entry" (Source Table No. = 50103, Source Entry No. = dessen Entry No.). Die Tabellenrelation wird um diesen Fall erweitert; alte Protokolleinträge mit Verweis auf 60314 bleiben lesbar.
- **BREAKING** Tabelle 60314 "CXW Sales Price Outbound File" wird nicht mehr beschrieben und als `ObsoleteState = Pending` markiert (Daten bleiben erhalten; Entfernung in einer späteren Version).
- Permission Set `CXWChronWSAll` erhält Rechte auf "Data Export Entry".
- Unverändert: "CXW API Interface Setup", "CXW General Sales Price Setup", Authentifizierung (ApiKeyHeader/BasicAuth/AWS SigV4), SOAPAction, JSON-Inhalt, Export-Status pro Prüfzeile, Rückschreiben und Archivierung.

## Capabilities

### New Capabilities
<!-- keine -->

### Modified Capabilities
- `sales-price-api-export`: Ergebnis einer Übertragung wird als "Data Export Entry" statt als "CXW Sales Price Outbound File" festgehalten; neue Anforderung, dass diese Einträge nicht vom ChronextBC-Exportjob erneut versendet werden.
- `sales-price-http-call-logging`: Log-Einträge verweisen auf den "Data Export Entry" statt auf "CXW Sales Price Outbound File".

## Impact

- **Codeunit 60329** "CXW Export Gateway Sales Price" (`src/Codeunits/Codeunit60329.CXWExportGatewaySalesPrice.al`): `CreateExternalInterfaceFile`, `SendToApiInterface`, `LogHttpCall`.
- **Table 60314** "CXW Sales Price Outbound File": Obsolete Pending.
- **Table 60302** "CXW Http Call Log": Tabellenrelation von `"CXW Source Entry No"` um "Data Export Entry" erweitert.
- **Permission Set** `CXWChronWSAll`.
- **Abhängigkeit ChronextBC**: wird zusätzlich für den SalesPrice-Export benötigt (Tabelle "Data Export Entry", Enums "Data Export Statuses"/"Data Export Format"). Die Abhängigkeit besteht bereits in `app.json`.
- **Doku**: `docs/developer-manual-de.md`/`-en.md`, Key-User-Handbücher, Funktionsregister (Hinweis auf neue Protokollstelle), anschließend Confluence-Sync.
- Kein Einfluss auf das externe Zielsystem: Request, Payload und Authentifizierung bleiben identisch.
