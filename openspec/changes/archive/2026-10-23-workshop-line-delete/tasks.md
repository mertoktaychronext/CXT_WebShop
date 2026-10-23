## 1. Tabelle und Logik

- [x] 1.1 Codeunit 60335 „CXW Workshop Line Mgt.“: Prozedur zum Zurücksetzen der Einkaufszeile anlegen („Sent to Workshop“ := false, „Manufacturer Serial No.“ := '', `Modify`; fehlt die Einkaufszeile, nichts tun)
- [x] 1.2 Codeunit 60335: Prozedur für das Mitlöschen beim Löschen der Einkaufszeile anlegen (Logik aus TabExt 60321 übernehmen: `Get`, nur wenn nicht „Processed“, `Delete()` ohne Trigger) und `Permissions = tabledata "CXW Workshop Line" = d` setzen
- [x] 1.3 TabExt 60321 `OnDelete`: neue Prozedur aus 1.2 aufrufen statt selbst zu löschen
- [x] 1.4 Tab 60318 „CXW Workshop Line“: `trigger OnDelete()` – nur Status „New“/„Error“ zulassen (Positivliste), sonst `Error` mit eigenem Label; danach Prozedur aus 1.1 aufrufen; Kommentar, dass die Kaskade bewusst ohne Trigger löscht

## 2. Seiten und Berechtigungen

- [x] 2.1 Page 60338 „CXW Workshop Lines“: `DeleteAllowed = true`
- [x] 2.2 Page 60339 „CXW Workshop Line API“: unverändert `DeleteAllowed = false` lassen (prüfen)
- [x] 2.3 Neuer Berechtigungssatz `app/src/PermissionSets/CXWWorkshopDelete.permissionset.al`: `permissionset 60303 "CXW Workshop Delete"`, `Assignable = true`, Caption, `IncludedPermissionSets = "CXW Workshop All"`, `tabledata "CXW Workshop Line" = RIMD`
- [x] 2.4 „CXW Workshop All“: `tabledata "CXW Workshop Line" = RIMD` → `RIMd`
- [x] 2.5 „CXW Workshop API“ bleibt `RM` (prüfen)

## 3. Übersetzung

- [x] 3.1 Neues Fehler-Label und Caption des Berechtigungssatzes in `Translations/CHX.Webshop.g.xlf` übernehmen und in `CHX.Webshop.de-DE.xlf` übersetzen

## 4. Tests (test/, ID-Block 50400)

- [x] 4.1 `CXWTestPermissions`: Token für „CXW WORKSHOP DELETE“ ergänzen, in `GetRoleIds` und im Filter von `FilterPermissions` aufnehmen
- [x] 4.2 Löschen einer Zeile im Status „New“ setzt „Sent to Workshop“ und „Manufacturer Serial No.“ der Einkaufszeile zurück
- [x] 4.3 Löschen einer Zeile im Status „Error“ ist erlaubt
- [x] 4.4 Löschen einer Zeile im Status „WS checked“ und „Processed“ schlägt mit Fehler fehl, Zeile bleibt bestehen
- [x] 4.5 Löschen bei nicht mehr existierender Einkaufszeile läuft ohne Fehler
- [x] 4.6 Reservierungsposten (Seriennummer) und Seriennr.-Information bleiben nach dem Löschen unverändert
- [x] 4.7 Löschen der Einkaufszeile löscht eine offene Werkstattzeile weiterhin (auch „WS checked“), verarbeitete bleibt stehen (Regression)
- [x] 4.8 Berechtigungen: mit nur „CXW Workshop All“ schlägt direktes Löschen fehl, das Mitlöschen über die Einkaufszeile gelingt; mit „CXW Workshop Delete“ gelingt direktes Löschen – umgesetzt als Metadaten-Prüfung in `CXWTestPermissions` (direktes/indirektes Löschrecht, eingeschlossener Satz), da die Test-App keine Permissions-Mock-Bibliothek hat; das Mitlöschen selbst prüft `CXW Test Workshop Line Delete`
- [x] 4.9 Kompilieren und alle Tests ausführen (App und Test-App fehlerfrei kompiliert; Tests manuell in ChronextTest erfolgreich)

## 5. Dokumentation

- [x] 5.1 Benutzer- und Key-User-Handbuch (DE/EN): Löschen von Werkstattzeilen, nur „New“/„Error“, neuer Berechtigungssatz „CXW Workshop Delete“ und dessen Zuweisung
- [x] 5.2 Entwicklerhandbuch (DE/EN) und Funktionsregister: `OnDelete`-Trigger, neue Prozeduren, indirektes Löschrecht nachziehen
