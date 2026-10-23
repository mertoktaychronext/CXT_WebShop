## Why

Seit „Send to Workshop“ die BC-Seriennummer der Uhr aus der Artikelverfolgung verwendet bzw. aus der Nummernserie zieht (Change `workshop-send-serial-no-information`), ist jede Werkstattzeile genau einer Seriennummer zugeordnet. Diese Nummer steht aber weder auf der Werkstattzeile noch im Werkstatt-API, sondern nur die Herstellernummer. Anwender und Werkstatt können eine Werkstattzeile dadurch nicht direkt der Uhr im Lager (Seriennr.-Information, Artikelposten) zuordnen. Die Ausgabe der BC-Seriennummer war damals bewusst ein Non-Goal und wird jetzt angefordert.

## What Changes

- Die Werkstattzeile (Tab 60318 „CXW Workshop Line“) erhält ein neues, nicht editierbares Feld **„Serial No.“** (BC-Seriennummer der Uhr).
- „Send to Workshop“ übernimmt beim Anlegen der Werkstattzeile die Seriennummer, die für die Einkaufszeile ermittelt bzw. gezogen wurde (Momentaufnahme wie die übrigen Bestelldaten).
- Die Seite „CXW Workshop Lines“ (Page 60338) zeigt die Seriennummer schreibgeschützt neben der Herstellernummer an.
- Das Werkstatt-API `workshopLines` (Page 60339) liefert das neue Feld `serialNo` schreibgeschützt; ein PATCH, das den Wert ändert, wird abgelehnt.
- Beim Upgrade werden offene Werkstattzeilen (Status `New`/`WS checked`) einmalig aus der Artikelverfolgung ihrer Einkaufszeile befüllt.

## Capabilities

### New Capabilities
- `workshop-line-serial-no`: BC-Seriennummer auf der Werkstattzeile – Übernahme bei „Send to Workshop“, Anzeige auf „CXW Workshop Lines“, Ausgabe im API `workshopLines` (schreibgeschützt), Nachbefüllung offener Zeilen beim Upgrade.

### Modified Capabilities
<!-- keine: workshop-send-serial-no-information und workshop-line-api-purchase-data bleiben in ihren Anforderungen unverändert; die Seriennummer kommt als eigene Capability hinzu -->

## Impact

- `app/src/Tables/Tab60318.CXWWorkshopLine.al` – neues Feld 39 `"CXW Serial No."` (Code[50])
- `app/src/PageExtensions/PagExt60328.CXWWorkshopPurchaseOrder.al` – `CreateWorkshopLine` übernimmt die Seriennummer
- `app/src/Pages/Pag60338.CXWWorkshopLines.al` – Feld anzeigen (ToolTip)
- `app/src/Pages/Pag60339.CXWWorkshopLineAPI.al` – API-Feld `serialNo`, Schreibschutz in `OnModifyRecord`
- `app/src/Codeunits/Codeunit60336.CXWWorkshopUpgrade.al` – neuer Upgrade-Tag, Nachbefüllung offener Zeilen
- `app/app.json` – Versionserhöhung (Upgrade)
- Berechtigungen: keine Änderung („CXW Workshop API“ liest nur die Werkstattzeile; „CXW Workshop All“ hat `Reservation Entry` bereits)
- Werkstatt-API: neues Feld in der Antwort (additiv, nicht breaking)
- `Translations/*.xlf`, `docs/` (Entwickler-, Key-User-Handbuch, Funktionsregister), Tests in `test/`
