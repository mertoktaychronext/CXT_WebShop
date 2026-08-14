## Why

Die Änderung `workshop-attribute-names` hat die fachlichen Bezeichnungen (Dial Color, Case Diameter, Bracelet Material, Case Material, Movement, Gender, Crystal, Features) bisher nur als **Caption** der Felder `"CXW Attribute 1"`–`"CXW Attribute 8"` auf Tabelle "CXW Workshop Line" hinterlegt. Der AL-Feldbezeichner selbst (der interne Symbolname im Code) heißt weiterhin generisch `"CXW Attribute 1"` usw. Für Entwickler, die den Code lesen (z. B. in Codeunit 60331 oder den Page-Definitionen), ist dadurch nicht auf den ersten Blick ersichtlich, welches Attribut ein Feld tatsächlich repräsentiert — nur über die Caption sichtbar, nicht im Code selbst.

## What Changes

- Tabelle 60318 "CXW Workshop Line": AL-Feldbezeichner der Felder 11–18 werden von `"CXW Attribute 1"`–`"CXW Attribute 8"` auf die fachlichen Namen umbenannt: `"CXW Dial Color"`, `"CXW Case Diameter"`, `"CXW Bracelet Material"`, `"CXW Case Material"`, `"CXW Movement"`, `"CXW Gender"`, `"CXW Crystal"`, `"CXW Features"`. Feld-ID und Caption bleiben unverändert (Caption ist bereits seit `workshop-attribute-names` korrekt gesetzt). Felder 19/20 (`"CXW Attribute 9"`/`"CXW Attribute 10"`) bleiben unverändert, da für sie noch kein fachlicher Name vorliegt.
- Alle Code-Referenzen auf die umbenannten Felder werden entsprechend angepasst: Codeunit 60331 "CXW Process Workshop Lines" (`GetWorkshopLineAttributeValue`), Page 60338 "CXW Workshop Lines" (Feld-Steuerelemente), Page 60339 "CXW Workshop Line API" (interne `Rec`-Referenzen).
- **Unverändert bleibt die externe API-Vertragsfläche**: Die OData-Eigenschaftsnamen `attribute1`–`attribute10` auf Page 60339 (das, was der externe Workshop tatsächlich sieht/sendet) werden **nicht** umbenannt — nur die dahinterliegende interne `Rec."CXW ..."`-Feldreferenz ändert sich. Der externe Vertrag mit dem Workshop bleibt vollständig kompatibel.

## Capabilities

### New Capabilities
(keine)

### Modified Capabilities
(keine — reine Umbenennung von AL-Feldbezeichnern ohne Auswirkung auf fachliches Verhalten, UI-Captions, Übersetzungen oder den externen API-Vertrag; die bereits in `workshop-attribute-names` dokumentierte Anforderung zur Namenszuordnung bleibt inhaltlich unverändert gültig)

## Impact

- **Geänderte Objekte**: Table 60318 "CXW Workshop Line" (8 Feldbezeichner), Codeunit 60331, Page 60338, Page 60339 (nur interne Feldreferenzen, keine API-Vertragsänderung).
- **Keine Caption-/Übersetzungsänderung**: Captions und Übersetzungen bleiben exakt wie in `workshop-attribute-names` — eine reine Feldbezeichner-Umbenennung ändert an der `.g.xlf`/`de-DE.xlf` nichts, da Trans-Unit-IDs auf der Feld-ID (nicht dem AL-Namen) basieren.
- **Risiko Feldumbenennung**: Wie bei der Umbenennung von `"CXW Processing Error"` zu `"CXW Last Error"` in einer früheren Änderung gilt: Eine reine AL-Bezeichner-Umbenennung ist nur unproblematisch, solange die Tabelle noch nicht mit Bestandsdaten in einer geteilten Umgebung läuft. Vor dem Deployment ist zu prüfen, ob diese Voraussetzung noch zutrifft (siehe design.md).
