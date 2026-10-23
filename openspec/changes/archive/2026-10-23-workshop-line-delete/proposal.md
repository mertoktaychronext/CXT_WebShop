## Why

Werkstattzeilen (Tab 60318 „CXW Workshop Line“) können heute weder auf der Seite „Workshop Lines“ noch über das API gelöscht werden. Eine versehentlich oder mit falschen Daten an die Werkstatt gesendete Zeile (falsche Uhr, falsche Herstellernummer, Ankunft irrtümlich bestätigt) lässt sich dadurch nicht mehr zurücknehmen: Die Werkstattzeile bleibt in der Werkstatt-Liste, und die zugehörige Einkaufszeile bleibt dauerhaft als „Sent to Workshop“ markiert und gesperrt.

Ein reines Freischalten von `DeleteAllowed` reicht nicht: Die Einkaufszeile trägt den Zustand „an die Werkstatt gesendet“ selbst (Feld „Sent to Workshop“, Herstellernummer). Bleibt dieser Zustand nach dem Löschen stehen, ist die Einkaufszeile weiter gesperrt und kann nie wieder gesendet werden. Zeilen, die die Werkstatt bereits geprüft hat oder die verarbeitet sind, tragen Prüfergebnisse bzw. sind der Prüfnachweis und dürfen nicht verloren gehen. Das Löschen soll außerdem nur ausgewählten Benutzern erlaubt sein.

## What Changes

- Die Seite „Workshop Lines“ (Page 60338) erlaubt das Löschen von Werkstattzeilen.
- Nur Werkstattzeilen in den Status **„New“** und **„Error“** dürfen gelöscht werden.
- Werkstattzeilen in den Status **„WS checked“** und **„Processed“** dürfen nicht gelöscht werden (Prüfergebnis der Werkstatt bzw. Prüfnachweis). Das Löschen wird mit einer Fehlermeldung abgelehnt.
- Beim Löschen einer Werkstattzeile wird die zugehörige Einkaufszeile zurückgesetzt: „Sent to Workshop“ = Nein, „Manufacturer Serial No.“ leer. Die Zeile ist danach wieder bearbeitbar und kann erneut mit „Send to Workshop“ gesendet werden.
- **Nicht** mitgelöscht werden: die Seriennummer in der Artikelverfolgung der Einkaufszeile und die Seriennr.-Information (inkl. Herstellernummer). Beides wird bei einem erneuten „Send to Workshop“ wiederverwendet – genau wie bei einem abgebrochenen Versuch.
- Neuer Berechtigungssatz **„CXW Workshop Delete“** (60303): Nur Benutzer mit diesem Satz dürfen Werkstattzeilen löschen. Er enthält „CXW Workshop All“ und ergänzt das direkte Löschrecht auf die Werkstattzeile.
- **„CXW Workshop All“** verliert das direkte Löschrecht auf die Werkstattzeile und erhält stattdessen ein indirektes (`d`). Das automatische Mitlöschen offener Werkstattzeilen beim Löschen einer Einkaufszeile/Bestellung funktioniert damit weiterhin für alle Workshop-Benutzer und die Job Queue.
- Das Werkstatt-API `workshopLines` (Page 60339) erlaubt weiterhin **kein** Löschen; die Werkstatt wird über gelöschte Zeilen nicht informiert.

## Capabilities

### New Capabilities
- `workshop-line-delete`: Löschen von Werkstattzeilen auf der Seite „Workshop Lines“ – nur Status „New“/„Error“, Sperre für „WS checked“/„Processed“, Zurücksetzen der Einkaufszeile, Erhalt von Artikelverfolgung und Seriennr.-Information, eigener Berechtigungssatz, kein Löschen über das Werkstatt-API.

### Modified Capabilities
<!-- keine: workshop-lines-purchase-order-drilldown bleibt in den Anforderungen unverändert – nach dem Löschen zählt die Einkaufszeile wieder als „noch nicht gesendet“, das ergibt sich aus der bestehenden Anforderung -->

## Impact

- `app/src/Tables/Tab60318.CXWWorkshopLine.al` – neuer `OnDelete`-Trigger (Status-Sperre, Zurücksetzen der Einkaufszeile)
- `app/src/Codeunits/Codeunit60335.CXWWorkshopLineMgt.al` – Prozedur zum Zurücksetzen der Einkaufszeile; Prozedur für das Mitlöschen beim Löschen der Einkaufszeile mit `Permissions = tabledata "CXW Workshop Line" = d`
- `app/src/TableExtensions/TabExt60321.CXWWorkshopPurchaseLine.al` – `OnDelete` ruft das Mitlöschen über Codeunit 60335 auf
- `app/src/Pages/Pag60338.CXWWorkshopLines.al` – `DeleteAllowed = true`
- `app/src/Pages/Pag60339.CXWWorkshopLineAPI.al` – unverändert (`DeleteAllowed = false`)
- `app/src/PermissionSets/` – neu `CXWWorkshopDelete.permissionset.al` (60303); „CXW Workshop All“: `RIMD` → `RIMd` auf „CXW Workshop Line“; „CXW Workshop API“ bleibt `RM`
- **Benutzereinrichtung:** Benutzer, die löschen sollen, brauchen den neuen Satz zugewiesen. Bisher hatten alle Benutzer mit „CXW Workshop All“ das Löschrecht in der Tabelle (ohne Löschmöglichkeit auf der Seite).
- `test/src/Permissions/CXWTestPermissions.Codeunit.al` – neuen Satz in die Rollenliste aufnehmen
- `Translations/*.xlf`, `docs/` (Benutzer-, Key-User-, Entwicklerhandbuch, Funktionsregister), Tests in `test/`
