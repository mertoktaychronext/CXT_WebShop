## 0. Klärung

- [x] 0.1 Entscheidung eingeholt (2026-09-30): Fallback auf die deutschen ChronextBC-Attribute, sonst leer (design.md, Entscheidung 1a)
- [ ] 0.2 Vor Go-live im Mandanten prüfen, dass die IDs 15, 16, 18, 20, 22, 23, 24 den ChronextBC-Attributen Werk, Gehäuse Material, Gehäuse Größe, Glas, Zifferblatt Farbe 1, Armband Material, Geschlecht entsprechen

## 1. Zentrale Zuordnung

- [x] 1.1 Codeunit 60335: `WorkshopAttributeCount`, `GetWorkshopAttributeName`, `GetWorkshopAttributeValue`, `SetWorkshopAttributeValue` laut design.md, Entscheidung 2 (inkl. TODO zu Attribut 9/10)
- [x] 1.2 Codeunit 60331: `ProcessGenuineLine` auf die Prozeduren aus 1.1 umstellen, lokale `GetAttributeMapping` und `GetWorkshopLineAttributeValue` entfernen

## 2. Vorbefüllung

- [x] 2.1 Codeunit 60335: `FindItemAttributeId(Name)` (ohne Neuanlage, `SetLoadFields`) und `FillEmptyWorkshopAttributes(var WorkshopLine; ItemNo)` über die vorhandene `GetItemAttributeValue`
- [x] 2.2 PageExt 60328 `CreateWorkshopLine`: nach `FillPurchaseData` und vor `Insert(true)` `PrefillEmptyWorkshopAttributes` aufrufen (nicht in `FillPurchaseData`, design.md Entscheidung 3)
- [x] 2.3 Codeunit 60335: öffentliche `PrefillEmptyWorkshopAttributes(var WorkshopLine)`
- [x] 2.4 Codeunit 60336: Upgrade-Tag `CXW-WORKSHOPLINE-ATTRIBUTEPREFILL-20260930`, Prozedur für Zeilen mit Status `New` (`PrefillEmptyWorkshopAttributes`, `Modify(false)`), Tag in `OnGetPerCompanyUpgradeTags` registrieren
- [x] 2.5 `app.json`-Version erhöhen
- [x] 2.6 Codeunit 60335: `GetWorkshopAttributeFallbackId` und Fallback in `FillEmptyWorkshopAttributes` (englisches Attribut leer/fehlt → ChronextBC-ID, sonst leer)

- [x] 2.7 Codeunit 60335: `IsUnchangedFallbackValue`; Codeunit 60331 überspringt unverändert bestätigte Fallback-Werte beim Rückschreiben (design.md, Entscheidung 1a)

## 3. Oberfläche und Übersetzungen

- [x] 3.1 Page 60338: ToolTips der Felder 11–20 anpassen (design.md, Entscheidung 5)
- [x] 3.1a Page 60338: ToolTips der Felder 1–7 um das Fallback-Attribut und das Nicht-Zurückschreiben unveränderter Fallback-Werte ergänzen (Code, g.xlf, de-DE.xlf)
- [x] 3.2 Kompilieren, geänderte ToolTips in `CHX.Webshop.g.xlf` nachziehen (alc-CLI schreibt die Datei nicht, daher manuell) und in `CHX.Webshop.de-DE.xlf` übersetzen

## 4. Prüfung

- [x] 4.1 Kompilieren ohne neue Fehler oder Warnungen
- [ ] 4.2 Test: "Send to Workshop" für Artikel mit gepflegten Attributen "Dial Color", "Case Diameter", "Case Material" → Felder vorbefüllt, API liefert die Werte
- [ ] 4.2a Test: Artikel ohne "Dial Color", aber mit Attribut 22 "Zifferblatt Farbe 1" → Feld aus dem Fallback; Artikel mit beiden → englischer Wert
- [ ] 4.3 Test: Artikel ohne diese Attribute bzw. nicht vorhandenes Attribut "Attribut 9" → Zeile angelegt, Felder leer, kein neues "Item Attribute" angelegt
- [ ] 4.4 Test: Werkstatt korrigiert `dialColor` per PATCH, Zeile `WS checked` + echt, Verarbeitung → Artikelattribut hat den korrigierten Wert
- [ ] 4.5 Test: Werkstatt bestätigt unverändert → keine neuen "Item Attribute"/"Item Attribute Value"-Datensätze; auch bei Fallback-Wert (z. B. aus 22) wird "Dial Color" weder angelegt noch befüllt
- [ ] 4.5a Test: Werkstatt korrigiert einen Fallback-Wert → Korrektur landet in "Dial Color", Attribut 22 unverändert
- [ ] 4.6 Test: Upgrade befüllt nur leere Felder von `New`-Zeilen, `WS checked`/`Processed`/`Error` unverändert, läuft nur einmal

## 5. Dokumentation

- [x] 5.1 `docs/developer-manual-de.md`/`-en.md`: Vorbefüllung, zentrale Zuordnung in Codeunit 60335, Upgrade-Tag
- [x] 5.2 `docs/key-user-manual-de.md`/`-en.md`: Attributfelder werden aus den Artikelattributen vorbefüllt und von der Werkstatt ggf. korrigiert; Attribute vor "Send to Workshop" pflegen
- [ ] 5.3 Info an die Werkstatt: Felder vorbefüllt, bitte prüfen/korrigieren; ein geleertes Feld entfernt keinen Wert am Artikel
