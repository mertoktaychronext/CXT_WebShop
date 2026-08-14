## Context

`workshop-attribute-names` hat die Captions der Felder `"CXW Attribute 1"`–`"CXW Attribute 8"` auf Tabelle 60318 "CXW Workshop Line" auf die fachlichen Bezeichnungen (Dial Color, Case Diameter, Bracelet Material, Case Material, Movement, Gender, Crystal, Features) umgestellt. Der AL-Feldbezeichner (der Symbolname im Quellcode, z. B. `"CXW Attribute 1"` in `WorkshopLine."CXW Attribute 1"`) blieb dabei unverändert generisch. Diese Änderung zieht die Umbenennung auf den Feldbezeichner selbst nach.

Referenzen auf die betroffenen Felder wurden vollständig ermittelt (Suche nach `CXW Attribute [1-8]"` im gesamten `src`-Verzeichnis): genau vier Dateien.

- `src/Tables/Tab60318.CXWWorkshopLine.al` — die Felddeklarationen selbst.
- `src/Codeunits/Codeunit60331.CXWProcessWorkshopLines.al` — `GetWorkshopLineAttributeValue`, liest je Index das passende Feld aus.
- `src/Pages/Pag60338.CXWWorkshopLines.al` — Anzeige-Steuerelemente der internen Übersichtsseite.
- `src/Pages/Pag60339.CXWWorkshopLineAPI.al` — die Custom-API-Page; **wichtig**: dort sind die OData-Eigenschaftsnamen (`attribute1`–`attribute10`) vom AL-Feldbezeichner (`Rec."CXW Attribute 1"` etc.) technisch entkoppelt — `field(attribute1; Rec."CXW Attribute 1")` bindet einen stabilen externen Namen an ein internes Feld. Nur die `Rec`-Referenz ändert sich, die Eigenschaft `attribute1` bleibt exakt so bestehen.

## Goals / Non-Goals

**Goals:**
- Die AL-Feldbezeichner der Attributfelder 1–8 sind im Code selbst aussagekräftig, ohne die Caption nachschlagen zu müssen.
- Alle vier betroffenen Dateien werden konsistent aktualisiert; keine verwaisten Referenzen auf die alten Bezeichner.
- Der externe API-Vertrag mit dem Workshop (OData-Eigenschaftsnamen `attribute1`–`attribute10`) bleibt unverändert und vollständig kompatibel.

**Non-Goals:**
- Keine Änderung an Captions, ToolTips oder Übersetzungen — diese sind bereits korrekt (aus `workshop-attribute-names`) und bleiben unverändert. Da Trans-Unit-IDs im `.g.xlf`/`de-DE.xlf` auf der Feld-ID basieren (nicht auf dem AL-Namen), ist durch diese Änderung keine Übersetzungsarbeit nötig — bei der Kompilierung ist trotzdem zu verifizieren, dass sich die IDs tatsächlich nicht ändern.
- Keine Umbenennung der Felder 9/10 (`"CXW Attribute 9"`/`"CXW Attribute 10"`) — weiterhin Platzhalter ohne fachlichen Namen.
- Keine Änderung an `GetAttributeMapping` (Codeunit 60331) — diese Prozedur liefert bereits die fachlichen Namen als Text für die Standard-Artikelattribute und referenziert keine AL-Feldbezeichner.

## Decisions

### Neue Feldbezeichner exakt aus den fachlichen Namen abgeleitet

`"CXW Attribute 1"` → `"CXW Dial Color"`, `"CXW Attribute 2"` → `"CXW Case Diameter"`, `"CXW Attribute 3"` → `"CXW Bracelet Material"`, `"CXW Attribute 4"` → `"CXW Case Material"`, `"CXW Attribute 5"` → `"CXW Movement"`, `"CXW Attribute 6"` → `"CXW Gender"`, `"CXW Attribute 7"` → `"CXW Crystal"`, `"CXW Attribute 8"` → `"CXW Features"`. Identisch zu den bereits gesetzten Captions, nur als Feldbezeichner statt als Caption — konsistent mit dem Namensschema des restlichen Projekts (Feldbezeichner ≈ Caption ohne Sonderzeichen, z. B. `"CXW Last Error"` mit Caption 'Last Error').

**Alternative verworfen**: Abweichende, kürzere interne Bezeichner (z. B. `"CXW DialColor"` ohne Leerzeichen) — verworfen, da AL-Feldbezeichner mit Leerzeichen (in Anführungszeichen) im gesamten Projekt der Standard sind und keine Notwendigkeit für eine Abweichung besteht.

### Feld-ID bleibt unverändert, nur der Bezeichner ändert sich

Die Feld-IDs (11–18) bleiben unverändert — nur der AL-Name (der Bezeichner in Anführungszeichen nach der ID) wird geändert. Das ist eine reine Bezeichner-Umbenennung, keine Struktur- oder Typänderung.

### Risiko: Rename vs. Datenverlust bei bereits vorhandenen Daten

Wie bei der Umbenennung von `"CXW Processing Error"` zu `"CXW Last Error"` in einer früheren Änderung gilt: In AL wird der SQL-Spaltenname standardmäßig aus dem AL-Feldbezeichner abgeleitet (sofern kein `ExternalName` gesetzt ist). Eine reine Umbenennung im Code führt bei einer bereits mit Daten befüllten Umgebung zu einer *neuen* Spalte statt eines Renames, wenn nicht über eine Upgrade-Prozedur (`RenameField`) migriert wird. Da die Tabelle laut bisherigem Kenntnisstand noch nicht in einer produktiven Umgebung mit Bestandsdaten läuft, wird hier direkt umbenannt, ohne Upgrade-Prozedur.

**Alternative verworfen**: Vorsorglicher `RenameField`-Upgrade-Schritt — verworfen als unnötiger Mehraufwand, solange keine Bestandsdaten betroffen sind; sollte sich das zwischenzeitlich geändert haben, ist das vor dem Deployment zu prüfen (siehe Risks).

## Risks / Trade-offs

- **[Risiko]** Falls die Tabelle "CXW Workshop Line" zwischenzeitlich doch bereits mit Bestandsdaten in einer geteilten Umgebung läuft, verursacht die direkte Umbenennung Datenverlust in den betroffenen Spalten (siehe Decisions). → **Mitigation**: Vor dem Deployment `git log`/Deployment-Historie prüfen; falls bereits produktiv, `RenameField`-Upgrade-Schritt statt direkter Umbenennung ergänzen.
- **[Trade-off]** Diese Änderung hat keinen für Endanwender sichtbaren Effekt (Captions/UI/API bleiben identisch) — reiner Code-Qualitäts-/Wartbarkeits-Nutzen. Der Aufwand (Kompilierung, Verifikation aller vier Referenzstellen) ist dafür bewusst gering gehalten.

## Migration Plan

Reine Code-Änderung ohne Datenmigration (unter der Annahme aus Risks, dass noch keine Bestandsdaten betroffen sind). Deployment über den normalen App-Publish-Zyklus.

## Open Questions

- Ist die Tabelle "CXW Workshop Line" zwischenzeitlich bereits mit Bestandsdaten in einer geteilten Umgebung im Einsatz? Falls ja, vor der Umsetzung klären, ob ein Rename-Upgrade-Schritt statt direkter Umbenennung nötig ist.
