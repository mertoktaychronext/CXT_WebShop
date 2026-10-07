## 1. FlowField auf dem Einkaufskopf

- [x] 1.1 Prüfen (Symbole CHX.Base / ChronextBC), dass Feld-ID 60301 auf „Purchase Header“ nicht bereits belegt ist; sonst nächste freie ID im Bereich 60300–60359 wählen
- [x] 1.2 In `src/TableExtensions/TabExt60304.CXWSWPurchaseHeader.al` FlowField `"CXW No. of Workshop Lines"` (Integer, `FieldClass = FlowField`, `CalcFormula = count("CXW Workshop Line" where(...))` auf Belegart + Nummer, `Editable = false`, `BlankZero = true`, Caption 'No. of Workshop Lines') anlegen

## 2. Anzeige und DrillDown auf der Einkaufsbestellung

- [x] 2.1 In `src/PageExtensions/PagExt60328.CXWWorkshopPurchaseOrder.al` `layout`-Abschnitt mit `addlast(General)` und Feld `"CXW No. of Workshop Lines"` inkl. ToolTip ergänzen
- [x] 2.2 `OnDrillDown`-Trigger implementieren: „CXW Workshop Line“ auf Belegart/Nummer der Bestellung filtern und Page „CXW Workshop Lines“ mit `Page.Run` öffnen

## 3. Hinweis bei erneutem „Send to Workshop“

- [x] 3.1 In `SendLinesToWorkshop` die Anzahl vorhandener Werkstattzeilen der Bestellung per `Count()` ermitteln
- [x] 3.2 Nach dem Sammeln der offenen Zeilennummern: bei vorhandenen Werkstattzeilen und leerer Liste `Message(AllLinesAlreadySentMsg)` + `exit`; bei vorhandenen Werkstattzeilen und offenen Zeilen `Confirm(WorkshopLinesExistQst, false, Anzahl)`, bei Nein `exit`
- [x] 3.3 Labels `WorkshopLinesExistQst` (mit `Comment` für %1) und `AllLinesAlreadySentMsg` in der PageExt anlegen

## 4. Übersetzung und Build

- [x] 4.1 Kompilieren, damit `CHX.Webshop.g.xlf` die neuen Trans-Units enthält
- [x] 4.2 Deutsche Übersetzungen in `Translations/CHX.Webshop.de-DE.xlf` ergänzen (Caption „Anzahl Werkstattzeilen“, ToolTip, beide Meldungen gemäß design.md)
- [x] 4.3 Build ohne Fehler/Warnungen (CodeCop/UICop) sicherstellen

## 5. Test

- [x] 5.1 Bestellung ohne Werkstattzeilen: Feld leer, DrillDown öffnet leere Liste, „Send to Workshop“ startet ohne zusätzliche Meldung
- [x] 5.2 Bestellung mit Werkstattzeilen: Feld zeigt korrekte Anzahl (nur eigene Bestellung), DrillDown öffnet gefilterte Liste
- [x] 5.3 Erneutes „Send to Workshop“, alle Zeilen gesendet: Meldung erscheint, keine Ankunftsabfrage
- [x] 5.4 Erneutes „Send to Workshop“ mit offener Zeile: Rückfrage mit Anzahl; „Nein“ bricht ab, „Ja“ verarbeitet nur die offene Zeile; Feld zeigt danach die neue Anzahl
- [x] 5.5 Bestellung mit einem Einkaufsbenutzer ohne „CXW Workshop All“ öffnen und prüfen, dass kein Berechtigungsfehler auftritt (sonst Leserecht ergänzen)

## 6. Dokumentation

- [x] 6.1 Werkstatt-Abschnitt in `docs/` um Feld „Anzahl Werkstattzeilen“ und den Hinweis bei erneutem Senden ergänzen
