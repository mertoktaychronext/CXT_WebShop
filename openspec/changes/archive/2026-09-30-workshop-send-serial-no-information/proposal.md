## Why

Bei „Send to Workshop“ wird die Herstellernummer heute über einen eigenen Eingabedialog (Page 60340) erfasst und nur als Text an Einkaufszeile und Werkstattzeile gespeichert. Die BC-Seriennummer der Uhr und deren Seriennr.-Informationen (Herstellernummer, Box/Papiere aus CHX.Base) bleiben dabei unberührt – sie müssen separat gepflegt werden, und seriennummernpflichtige Artikel können beim späteren automatischen Wareneingang (Codeunit 60331) ohne Artikelverfolgung nicht gebucht werden.

## What Changes

- Statt des eigenen Dialogs öffnet „Send to Workshop“ je angekommener Zeile die Standard-**Seriennr.-Informationskarte (Page 6504)** für Artikel, Variante und Seriennummer der Einkaufszeile. Dort pflegt der Benutzer die Herstellernummer (`"CXB Manufacturer Serial No."` aus CHX.Base) sowie ggf. Box/Papiere.
- Hat die Einkaufszeile bereits eine Seriennummer in der Artikelverfolgung, wird diese verwendet.
- Hat sie noch keine, wird die **nächste Seriennummer aus der Seriennr.-Nummernserie des Artikels gezogen**, als Artikelverfolgung an die Einkaufszeile gehängt und der Datensatz „Serial No. Information“ dazu angelegt – die Karte öffnet sich mit dieser Nummer vorbelegt.
- Nach dem Schließen der Karte wird die Herstellernummer aus der Seriennr.-Information in Einkaufszeile und Werkstattzeile übernommen. Ist sie leer, wird die Zeile wie bisher nicht gesendet (Fehlerliste).
- Die von CHX.Base je Artikelverfolgungscode geforderten Pflichtangaben (Herstellernummer, Box, Papiere) werden vor dem Senden geprüft; fehlen sie, wird die Zeile nicht gesendet.
- Artikel ohne Seriennummernverfolgung bzw. ohne Seriennr.-Nummernserie sowie Zeilen mit einer Menge ungleich 1 werden nicht gesendet und mit Begründung in der Fehlerliste gemeldet.
- **BREAKING (UI):** Page 60340 „CXW Serial No. Input“ entfällt.

## Capabilities

### New Capabilities
- `workshop-send-serial-no-information`: Ermittlung bzw. Vergabe der Seriennummer je Einkaufszeile bei „Send to Workshop“, Erfassung der Herstellernummer über die Seriennr.-Informationskarte, Übernahme in Einkaufs- und Werkstattzeile, Fehlerfälle.

### Modified Capabilities
<!-- keine: der Workshop-Versand hat noch keine archivierte Haupt-Spec (siehe offene Workshop-Changes) -->

## Impact

- `src/PageExtensions/PagExt60328.CXWWorkshopPurchaseOrder.al` – `ProcessLine` neu (Seriennummer ermitteln/vergeben, Page 6504, Übernahme, Prüfungen), neue Labels
- neue Hilfslogik für Seriennummer/Artikelverfolgung (in `Codeunit 60335 "CXW Workshop Line Mgt."`)
- `src/Pages/Pag60340.CXWSerialNoInput.al` – entfernt
- `src/PermissionSets/CXWWorkshopAll.permissionset.al` – Page 60340 raus; `Reservation Entry`, `Serial No. Information` schreibend
- Abhängigkeit auf CHX.Base (`"CXB Manufacturer Serial No."`, `"CXB Serial No. Bin Enforcement".CheckPresenceMandatory`) – bereits vorhanden (27.0.3.5)
- `Translations/*.xlf`, `docs/` (Entwickler-, Key-User-, Benutzerhandbuch, Funktionsregister)
- Einrichtung: seriennummernpflichtige Watch-Artikel brauchen einen Artikelverfolgungscode mit SN-Verfolgung beim Einkauf und eine Seriennr.-Nummernserie am Artikel (bzw. über die SellWatch-Artikelvorlagen)
