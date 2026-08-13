## Context

Tabelle 60318 "CXW Workshop Line" hat zehn generische Textfelder `CXW Attribute 1`–`CXW Attribute 10`, deren Werte vom externen Workshop über die API befüllt werden. Codeunit 60331 "CXW Process Workshop Lines" überträgt bei bestätigter Echtheit jeden befüllten Wert über `GetAttributeMapping(AttributeIndex)` in ein BC-Standard-Artikelattribut (`Item Attribute` / `Item Attribute Value` / `Item Attribute Value Mapping`); `GetAttributeMapping` liefert bisher für jeden Index den Platzhaltertext "Attribut N". Beide Stellen — Feld-Caption auf der Tabelle und Rückgabewert von `GetAttributeMapping` — sind bislang identisch und als `// TODO:` markiert.

Für acht der zehn Attribute liegen jetzt reale fachliche Bezeichnungen vor: `dial_color`, `case_diameter`, `bracelet_material`, `case_material`, `movement`, `gender`, `crystal`, `features` (in dieser Reihenfolge Attribut 1–8).

## Goals / Non-Goals

**Goals:**
- Die ersten acht Attributfelder sind in der BC-Oberfläche (Workshop-Lines-Liste, ggf. künftige Detailseiten) mit einer verständlichen, fachlichen Bezeichnung versehen statt "Attribut N".
- Die daraus bei der Verarbeitung erzeugten/aktualisierten Standard-Artikelattribute tragen denselben Namen wie die Feld-Caption, damit auf der Workshop Line und auf dem Artikel dieselbe Bezeichnung erscheint.
- Attribut 9 und 10 bleiben bewusst Platzhalter, bis auch für sie eine fachliche Bezeichnung vorliegt.

**Non-Goals:**
- Keine Umbenennung des AL-Feldbezeichners (`"CXW Attribute 1"` etc.) — nur Caption und Mapping-Rückgabewert ändern sich, das Datenmodell/die Feld-ID bleibt unverändert.
- Keine Migration bereits angelegter "Item Attribute"-Datensätze mit dem alten Namen "Attribut 1"–"Attribut 8" aus vorherigen Testläufen (siehe Risks).
- Keine Änderung an der externen API (Page 60339) — die Feldnamen `attribute1`–`attribute10` bleiben dort unverändert generisch; nur die interne Bedeutung/Zuordnung wird jetzt dokumentiert.

## Decisions

### Title-Case-Captions statt der gegebenen snake_case-Bezeichner

Die vom Fachbereich gelieferten Bezeichner (`dial_color`, `case_diameter`, …) sind snake_case-Identifier. Alle übrigen Captions auf Tabelle 60318 folgen dem BC-üblichen Title-Case-Stil mit Leerzeichen (`Manufacturer Serial No.`, `Last Error`, `Item No.`). Für Konsistenz mit dieser bestehenden Konvention werden die Captions und der `GetAttributeMapping`-Rückgabewert als Title Case mit Leerzeichen geschrieben (`dial_color` → `Dial Color`, `case_diameter` → `Case Diameter`, `bracelet_material` → `Bracelet Material`, `case_material` → `Case Material`, `movement` → `Movement`, `gender` → `Gender`, `crystal` → `Crystal`, `features` → `Features`). Dieselbe Bezeichnung wird als Name des erzeugten Standard-Artikelattributs verwendet, damit Feld-Caption auf der Workshop Line und Attributname auf dem Artikel identisch sind.

**Alternative verworfen**: Die gelieferten snake_case-Strings unverändert als Caption/Attributname übernehmen — verworfen, da dies auf der Artikelkarte und in der Workshop-Lines-Liste als technischer Bezeichner statt als lesbarer Attributname erscheinen würde und vom sonstigen Caption-Stil des Projekts abweicht. Falls ein nachgelagertes System exakt die snake_case-Schreibweise als Artikelattribut-Namen benötigt, ist das ein separater, hier nicht bekannter Anforderung und müsste explizit nachgezogen werden.

### Zuordnung Reihenfolge → Attributindex

Die acht gelieferten Bezeichner werden in der gegebenen Reihenfolge den Indizes 1–8 zugeordnet (keine andere Reihenfolge wurde vorgegeben):

| Index | Feld | Bisherige Caption | Neue Caption / Artikelattribut-Name |
|---|---|---|---|
| 1 | `CXW Attribute 1` | Attribut 1 | Dial Color |
| 2 | `CXW Attribute 2` | Attribut 2 | Case Diameter |
| 3 | `CXW Attribute 3` | Attribut 3 | Bracelet Material |
| 4 | `CXW Attribute 4` | Attribut 4 | Case Material |
| 5 | `CXW Attribute 5` | Attribut 5 | Movement |
| 6 | `CXW Attribute 6` | Attribut 6 | Gender |
| 7 | `CXW Attribute 7` | Attribut 7 | Crystal |
| 8 | `CXW Attribute 8` | Attribut 8 | Features |
| 9 | `CXW Attribute 9` | Attribut 9 | *(unverändert, weiterhin Platzhalter)* |
| 10 | `CXW Attribute 10` | Attribut 10 | *(unverändert, weiterhin Platzhalter)* |

### Keine Migration bestehender "Item Attribute"-Datensätze

`GetOrCreateAttributeId` (Codeunit 60331) sucht ein "Item Attribute" per `SetRange(Name, AttributeName)` und legt es nur an, wenn keins mit exakt diesem Namen existiert. Ein zuvor unter dem Namen "Attribut 1" angelegtes Artikelattribut aus einem früheren Testlauf bleibt bestehen und wird beim nächsten Lauf **nicht** automatisch umbenannt — stattdessen entsteht ein neues Artikelattribut "Dial Color", und künftige Werte landen dort. Da dieses Feature laut Tasks-Stand von `purchase-workshop-integration` noch nicht produktiv gelaufen ist (Kompilierung/manueller Test dort erst kürzlich nachgezogen), ist das Risiko in der Praxis gering; falls doch bereits Testdaten mit dem alten Platzhalternamen erzeugt wurden, sind diese manuell zu bereinigen (siehe Risks).

## Risks / Trade-offs

- **[Risiko]** Falls in einer Testumgebung bereits "Item Attribute"-Datensätze mit dem Namen "Attribut 1"–"Attribut 8" angelegt wurden, bleiben diese als Karteileichen bestehen, da diese Änderung sie nicht umbenennt oder löscht. → **Mitigation**: Vor dem Deployment in einer bereits genutzten Umgebung prüfen, ob solche Datensätze existieren, und sie bei Bedarf manuell umbenennen oder löschen.
- **[Trade-off]** Die Umwandlung snake_case → Title Case ist eine Format-Entscheidung dieser Änderung, keine Vorgabe des Fachbereichs. Falls ein nachgelagertes System exakt die snake_case-Schreibweise erwartet, muss das nachträglich angepasst werden.

## Migration Plan

Reine Code-/Metadatenänderung ohne Pflicht-Datenmigration (siehe Risks für den Sonderfall bereits existierender Testdaten). Deployment über den normalen App-Publish-Zyklus.

## Open Questions

- Fachliche Bezeichnung für Attribut 9 und Attribut 10 steht noch aus.
- Sollen bereits vorhandene "Item Attribute"-Datensätze mit den alten Platzhalternamen "Attribut 1"–"Attribut 8" bereinigt werden? (Nur relevant, falls bereits Testläufe stattgefunden haben.)
