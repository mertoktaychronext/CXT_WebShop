## Why

Die Job-Queue-Verarbeitung geprüfter Workshop Lines (Codeunit 60331 "CXW Process Workshop Lines") fängt Fehler zwar pro Zeile ab und schreibt den Fehlertext in `"CXW Processing Error"`, lässt den Status der fehlgeschlagenen Zeile aber unverändert auf `WS checked`. Dadurch ist eine dauerhaft fehlgeschlagene Zeile (z. B. gesperrte Buchungsperiode, fehlende Lagerortangabe) optisch nicht von einer noch unbearbeiteten Zeile zu unterscheiden — jeder folgende Job-Queue-Lauf versucht sie erneut, ohne dass ersichtlich ist, dass bereits ein Fehler vorlag.

## What Changes

- Enum "CXW Workshop Line Status" (60337) erhält einen neuen Wert `Error`.
- Tabelle "CXW Workshop Line" (60318): Feld `"CXW Processing Error"` wird zu `"CXW Last Error"` umbenannt (gleiche Feld-ID 23, gleicher Zweck — ein Feld für den zuletzt aufgetretenen Fehlertext statt zweier Felder mit überlappendem Zweck).
- Codeunit "CXW Process Workshop Lines" (60331): Schlägt die Verarbeitung einer Zeile fehl, wird zusätzlich zum Fehlertext in `"CXW Last Error"` auch der Status der Zeile auf `Error` gesetzt. Bei erfolgreicher (Re-)Verarbeitung wird `"CXW Last Error"` geleert.
- Tabelle "CXW Workshop Line": neue Statusregel im `OnModify`-Trigger — der Status darf nur aus `WS checked` heraus auf `Error` wechseln (verhindert, dass die externe Workshop-API oder eine manuelle Änderung den Status direkt auf `Error` setzt, ohne dass eine echte Verarbeitung stattgefunden hat).
- Deutsche und englische Captions/Translations für den neuen Enum-Wert und das umbenannte Feld.

## Capabilities

### New Capabilities
(keine)

### Modified Capabilities
- `workshop-line-processing`: Verarbeitungsfehler werden nicht mehr nur im Fehlertext-Feld protokolliert, sondern setzen die Workshop Line zusätzlich auf einen eigenen Status `Error`; erfolgreiche (Re-)Verarbeitung setzt das Fehlerfeld zurück. Diese Capability wurde im noch nicht archivierten Change `purchase-workshop-integration` eingeführt (`specs/workshop-line-processing/spec.md` dort); diese Änderung liefert die Delta-Requirements dazu.

## Impact

- **Geänderte Objekte**: Enum 60337 "CXW Workshop Line Status", Table 60318 "CXW Workshop Line" (Feldumbenennung + OnModify-Regel), Codeunit 60331 "CXW Process Workshop Lines" (Statussetzung im Fehlerfall + Reset im Erfolgsfall).
- **Keine neuen Objekte, keine API-Vertragsänderung** an Endpunkt-URLs oder Entity-Struktur der Page 60339 "CXW Workshop Line API" — das Feld `status` bleibt vorhanden, akzeptiert nur einen zusätzlichen Wert; `"CXW Last Error"` war und bleibt nicht über die API exponiert.
- **Betroffen**: Alle Stellen, die `"CXW Processing Error"` referenzieren (aktuell nur Codeunit 60331), sowie Übersetzungsdateien (`Translations/CHX.Webshop.g.xlf`, `Translations/CHX.Webshop.de-DE.xlf`).
- **Risiko Feldumbenennung**: Da die Tabelle erst kürzlich eingeführt wurde und laut Tasks von `purchase-workshop-integration` noch nicht kompiliert/manuell getestet wurde (siehe dortige Tasks 7.1/7.2 als "ausstehend"), ist von keiner produktiven Datenmigration betroffen; falls die App in einer Zwischenzeit doch bereits veröffentlicht wurde, ist vor dem Deployment zu prüfen, ob eine Upgrade-Prozedur (Feld-Rename mit `RenameField`/`ObsoleteState`) nötig ist.
