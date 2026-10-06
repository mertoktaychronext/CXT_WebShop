## Why

Beim Anlegen einer Werkstattzeile ("Send to Workshop") bleiben die Attributfelder, die die Werkstatt zurückschreibt (`dialColor`, `caseDiameter`, `braceletMaterial`, `caseMaterial`, `movement`, `gender`, `crystal`, `features`, `attribute9`, `attribute10`), heute leer. Die Werkstatt muss sie komplett neu erfassen, obwohl die Werte am Artikel oft schon gepflegt sind. Die Werkstattzeile soll so viele Informationen wie möglich aus dem Artikel mitbringen; die Werkstatt prüft und korrigiert sie nur noch.

## What Changes

- Bei "Send to Workshop" werden die Felder 11–20 der Tabelle 60318 "CXW Workshop Line" (Dial Color … Attribute 10) mit den aktuellen Werten der zugehörigen Artikelattribute vorbefüllt. Zuordnung Feld ↔ Artikelattribut ist dieselbe, über die Codeunit 60331 die Werte bei der Verarbeitung zurückschreibt (Attributname "Dial Color", "Case Diameter", …).
- Die Zuordnung Feld ↔ Attributname wird an einer Stelle zusammengeführt, damit Vorbefüllung und Rückschreiben nicht auseinanderlaufen können.
- Die Werkstatt kann die vorbefüllten Werte über die API wie bisher ändern; bei der Verarbeitung werden die (ggf. korrigierten) Werte wie bisher in die Artikelattribute geschrieben.
- Offene Werkstattzeilen mit Status `New` werden einmalig per Upgrade vorbefüllt (nur leere Felder).
- ToolTips der Felder auf der Seite "CXW Workshop Lines" werden angepasst ("vorbefüllt aus dem Artikelattribut, ggf. von der Werkstatt korrigiert").
- **Keine** neue Tabelle, **keine** neue API-Page, **keine** neuen API-Felder. Die übrigen Felder der API-Page 60339 werden bereits vollständig befüllt (Change `workshop-line-api-purchase-data`).

## Capabilities

### New Capabilities
- `workshop-line-attribute-prefill`: Vorbefüllung der von der Werkstatt zurückgeschriebenen Attributfelder aus den Artikelattributen beim Anlegen der Werkstattzeile.

### Modified Capabilities
- (keine) – Das Rückschreiben (Codeunit 60331) bleibt fachlich unverändert; die Basis-Specs liegen nicht unter `openspec/specs/`.

## Impact

- `src/Codeunits/Codeunit60335.CXWWorkshopLineMgt.al`: Vorbefüllung der Felder 11–20, zentrale Zuordnung Feld ↔ Attributname.
- `src/Codeunits/Codeunit60331.CXWProcessWorkshopLines.al`: nutzt die zentrale Zuordnung statt eigener `GetAttributeMapping`/`GetWorkshopLineAttributeValue`.
- `src/Codeunits/Codeunit60336.CXWWorkshopUpgrade.al`: zweiter Upgrade-Tag.
- `src/Pages/Pag60338.CXWWorkshopLines.al`: ToolTips.
- `app.json`-Version, Übersetzungen, Handbücher.
- Externe Werkstatt: gleiche API, gleiche Felder – die Attributfelder sind jetzt beim Abruf bereits gefüllt. Nicht breaking.
