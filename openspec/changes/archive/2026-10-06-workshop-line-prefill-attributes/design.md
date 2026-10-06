## Context

- **Werkstattzeile entsteht** in PageExt 60328 `CreateWorkshopLine`; vor dem `Insert(true)` ruft sie `FillPurchaseData` in Codeunit 60335 "CXW Workshop Line Mgt." auf. Diese befüllt bereits alle Bestell- und Uhrendaten der API (Felder 30–47). Die Felder 11–20 bleiben leer.
- **Felder 11–20** (`"CXW Dial Color"`, `"CXW Case Diameter"`, `"CXW Bracelet Material"`, `"CXW Case Material"`, `"CXW Movement"`, `"CXW Gender"`, `"CXW Crystal"`, `"CXW Features"`, `"CXW Attribute 9"`, `"CXW Attribute 10"`, alle Text[250]) sind in der API-Page 60339 schreibbar (`dialColor` … `attribute10`).
- **Rückschreiben** in Codeunit 60331 "CXW Process Workshop Lines", `ProcessGenuineLine`: für Index 1–10 liest `GetWorkshopLineAttributeValue` das Feld, `GetAttributeMapping` liefert den Attributnamen ("Dial Color", "Case Diameter", "Bracelet Material", "Case Material", "Movement", "Gender", "Crystal", "Features", "Attribut 9", "Attribut 10"). Nicht leere Werte werden per `GetOrCreateAttributeId` (Suche über `Name`, sonst Neuanlage Typ Text) und `GetOrCreateAttributeValueId` (Suche über Attribut + Wert, sonst Neuanlage) am Artikel gesetzt. Leere Werte werden übersprungen.
- **Berechtigungen:** "CXW Workshop All" hat bereits Lesezugriff auf "Item Attribute", "Item Attribute Value" und "Item Attribute Value Mapping". Der Werkstatt-Benutzer braucht nichts Neues, weil er nur die Werkstattzeile liest.

## Goals / Non-Goals

**Goals:**
- Die Werkstatt findet beim Abruf die Attributfelder mit den bekannten Artikelwerten vorbefüllt und muss nur korrigieren.
- Lesen und Rückschreiben treffen garantiert dasselbe Artikelattribut.

**Non-Goals:**
- Keine neue Tabelle, keine neue API-Page, keine neuen API-Felder, keine Änderung an Feldnamen oder Schreibrechten der API.
- Keine Änderung der Zuordnung Feld ↔ Attributname für das Rückschreiben (der Fallback aus Entscheidung 1a gilt nur beim Lesen).
- Keine Änderung der Rückschreiblogik: Leere Werte löschen weiterhin kein Artikelattribut.
- Keine Übersetzung von Attributwerten; übernommen wird `"Item Attribute Value".Value`.

## Decisions

### 1. Gleiche Zuordnung wie beim Rückschreiben, Suche über den Attributnamen
Für jedes der zehn Felder wird das "Item Attribute" mit dem Namen aus der Zuordnung gesucht (`SetRange(Name, …)`, `FindFirst`, analog `GetOrCreateAttributeId`, aber **ohne** Neuanlage), dann "Item Attribute Value Mapping" (`Database::Item`, Artikelnr., Attribut-ID) und "Item Attribute Value" gelesen.
- *Warum:* Nur so landet ein korrigierter Wert in genau dem Attribut, aus dem er vorbefüllt wurde. Eine andere Quelle (z. B. die ChronextBC-Attribute per ID) würde beim Rückschreiben ein zweites, gleichbedeutendes Attribut erzeugen bzw. pflegen.
- *Keine Neuanlage beim Lesen:* Fehlt das Attribut, bleibt das Feld leer; Stammdaten entstehen erst beim Rückschreiben wie bisher.
- Gesperrte Attribute werden wie beim Rückschreiben nicht gesondert behandelt.

### 1a. Fallback auf die deutschen ChronextBC-Attribute (entschieden 2026-09-30)
Liefert das englisch benannte Attribut keinen Wert (Attribut fehlt oder am Artikel nicht gepflegt), wird das ChronextBC-Attribut per ID gelesen (ID = Feldnummer in "Item Attribute Collection", wie bei den Uhrenfeldern 40–47). Gibt es auch dort keinen Wert, bleibt das Feld leer.

| Index | Feld | Primär (Name) | Fallback (ID) |
|---|---|---|---|
| 1 | Dial Color | "Dial Color" | 22 Zifferblatt Farbe 1 |
| 2 | Case Diameter | "Case Diameter" | 18 Gehäuse Größe |
| 3 | Bracelet Material | "Bracelet Material" | 23 Armband Material |
| 4 | Case Material | "Case Material" | 16 Gehäuse Material |
| 5 | Movement | "Movement" | 15 Werk |
| 6 | Gender | "Gender" | 24 Geschlecht |
| 7 | Crystal | "Crystal" | 20 Glas |
| 8 | Features | "Features" | – |
| 9/10 | Attribut 9/10 | "Attribut 9"/"Attribut 10" | – |

- Die Fallback-IDs liegen als `GetWorkshopAttributeFallbackId` (lokal) neben der zentralen Zuordnung in Codeunit 60335.
- *Nur für die Vorbefüllung:* Das Rückschreiben nutzt weiterhin den englischen Attributnamen. Ein per Fallback vorbefüllter und von der Werkstatt korrigierter Wert landet also im englischen Attribut, das deutsche ChronextBC-Attribut bleibt unverändert. Bewusst so, weil nur der Fallback beauftragt ist und die ChronextBC-Attribute von anderen Prozessen (Shop-Export) gepflegt werden.
- *Unveränderte Fallback-Werte werden nicht zurückgeschrieben (entschieden 2026-09-30, Variante B aus dem Dev-Abschluss):* `IsUnchangedFallbackValue(ItemNo, Index, Value)` in Codeunit 60335 liefert `true`, wenn das englische Attribut am Artikel keinen Wert hat und der Wert dem Fallback-Attribut entspricht; Codeunit 60331 überspringt dann das Feld. Sonst würde jede Bestätigung den deutschen Text ins englische Attribut kopieren und fehlende englische Attribute anlegen. Kein neues Feld nötig; der Vergleich erfolgt zum Zeitpunkt der Verarbeitung. *Grenzfall:* Wurde das Fallback-Attribut zwischen Vorbefüllung und Verarbeitung geändert, gilt der alte Wert als Korrektur und wird ins englische Attribut geschrieben – fachlich vertretbar.
- *Zifferblatt:* 22 "Zifferblatt Farbe 1" statt 21 "Zifferblatt Farbe HS DE", weil 21 nach Shop-Text aussieht; bei Bedarf ist die ID an einer Stelle austauschbar.

### 2. Zuordnung zentral in Codeunit 60335
Die Zuordnung wandert aus Codeunit 60331 nach Codeunit 60335:
- `WorkshopAttributeCount(): Integer` → 10
- `GetWorkshopAttributeName(AttributeIndex): Text[250]` (bisher `GetAttributeMapping`)
- `GetWorkshopAttributeValue(WorkshopLine; AttributeIndex): Text[250]` (bisher `GetWorkshopLineAttributeValue`)
- `SetWorkshopAttributeValue(var WorkshopLine; AttributeIndex; Value)` (neu, für die Vorbefüllung)

Codeunit 60331 nutzt diese Prozeduren; ihre lokalen Varianten entfallen. Das TODO zu Attribut 9/10 wandert mit.
- *Warum:* Eine einzige Stelle verhindert, dass Vorbefüllung und Rückschreiben auseinanderlaufen (Spec-Anforderung "same attribute mapping").

### 3. Vorbefüllung als eigener Aufruf in `CreateWorkshopLine`, immer nur leere Felder
Öffentliche Prozedur `PrefillEmptyWorkshopAttributes(var WorkshopLine)` in Codeunit 60335 (→ lokale `FillEmptyWorkshopAttributes`). PageExt 60328 `CreateWorkshopLine` ruft sie nach `FillPurchaseData` und vor `Insert(true)` auf.
- *Nicht in `FillPurchaseData`:* Diese Prozedur nutzt auch der ältere Upgrade-Tag für Zeilen mit Status `WS checked`. Liefe die Vorbefüllung dort mit, bekämen bereits gemeldete Zeilen ungeprüfte Artikelwerte.
- *Immer nur leere Felder:* Bei einer neuen Zeile sind alle leer; im Upgrade werden erfasste Werkstattwerte nie überschrieben. Ein Parameter "überschreiben" ist damit überflüssig.
- Das Attribut-Lesen nutzt die vorhandene `GetItemAttributeValue(ItemNo, AttributeId)`; neu ist nur `FindItemAttributeId(Name): Integer` (0 = nicht vorhanden).
- `SetLoadFields` auf "Item Attribute" (ID, Name).

### 4. Upgrade nur für Status `New`, nur leere Felder
Neuer Upgrade-Tag `CXW-WORKSHOPLINE-ATTRIBUTEPREFILL-20260930` in Codeunit 60336 mit eigener Prozedur; ruft `PrefillEmptyWorkshopAttributes(var WorkshopLine)` und `Modify(false)`. Der bestehende Upgrade-Tag läuft unverändert davor.
- *Nicht `FillPurchaseData` erneut:* Der bestehende Upgrade-Tag hat die Bestelldaten bereits geschrieben; ein erneutes Befüllen ist nicht Teil dieses Change.
- *Nur `New`:* Bei `WS checked` hat die Werkstatt ihr Ergebnis bereits gemeldet; nachträglich eingesetzte Werte würden ungeprüft zurückgeschrieben.
- *Nur leere Felder:* Schon erfasste Werkstattwerte werden nie überschrieben.
- `app.json`-Version wird erhöht.

### 5. ToolTips
Page 60338: ToolTips der Felder 11–20 von "as reported by the workshop" auf "prefilled from the item attribute when the line is sent to the workshop; the workshop may correct it" umstellen; Übersetzung nachziehen.

## Risks / Trade-offs

- [Die Attribute "Dial Color", "Case Diameter" usw. existieren im Mandanten nicht oder sind leer] → abgefangen durch den Fallback auf die ChronextBC-Attribute (Entscheidung 1a).
- [ChronextBC-Attribut-IDs sind im Mandanten anders vergeben] → falsche Werte in falschen Feldern. Mitigation: IDs 15, 16, 18, 20, 22, 23, 24 vor Go-live in "Item Attributes" prüfen (Task 0.1).
- [Korrektur eines Fallback-Werts landet im englischen, nicht im deutschen Attribut] → bewusst (Entscheidung 1a); beim nächsten "Send to Workshop" desselben Artikels gewinnt dann der englische Wert. Unverändert bestätigte Fallback-Werte werden nicht zurückgeschrieben.
- [Gehäuse Größe ist in ChronextBC ein Dezimalwert] → Der Attributwert wird als Text übernommen (z. B. "41"), ohne Einheit, sofern nicht mitgepflegt.
- [Werkstatt bestätigt vorbefüllte Werte ungeprüft] → fachlich gewollt: Die Werkstatt ist für die Korrektur verantwortlich. Hinweis in der Info an die Werkstatt.
- [Werkstatt leert ein Feld, um einen falschen Wert zu entfernen] → Das Artikelattribut bleibt unverändert, weil leere Werte nicht zurückgeschrieben werden (bestehendes Verhalten). Hinweis in der Info an die Werkstatt.
- [Unveränderte Werte werden bei `Processed` erneut geschrieben] → unkritisch: `GetOrCreateAttributeValueId` findet den vorhandenen Wert, es entstehen keine neuen Datensätze.

## Migration Plan

1. Deploy mit erhöhter Version; kein Schema-Change.
2. Upgrade-Tag befüllt leere Attributfelder offener `New`-Zeilen einmalig.
3. Werkstatt informieren: Felder sind vorbefüllt, bitte prüfen/korrigieren; Leeren entfernt keinen Wert am Artikel.
4. Rollback: Vorversion deployen; bereits vorbefüllte Werte bleiben auf den Zeilen.

## Open Questions

- Gibt es ein ChronextBC-Attribut, das fachlich "Features" entspricht? Bis dahin ohne Fallback.
- Ist für Dial Color 22 "Zifferblatt Farbe 1" oder 21 "Zifferblatt Farbe HS DE" die richtige Quelle? Umgesetzt: 22.
- Fachliche Namen für Attribut 9/10 stehen weiterhin aus (bestehendes TODO).
