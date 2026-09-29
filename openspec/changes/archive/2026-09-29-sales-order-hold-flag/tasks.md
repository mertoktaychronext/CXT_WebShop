## 1. Datenmodell

- [x] 1.1 Neue Table Extension 60300 "CXW Sales Header" auf "Sales Header" mit Feld 60300 "CXW Hold Order" (Boolean, Caption `Hold Order`, `DataClassification = ToBeClassified`)
- [x] 1.2 `OnValidate` von "CXW Hold Order": `TestField(Status, Status::Open)`

## 2. Oberfläche

- [x] 2.1 PageExt 60334 "CXW Sales Order": Feld "CXW Hold Order" per `addlast(General)`, `Editable = Rec.Status = Rec.Status::Open`, ToolTip mit Hinweis auf reines Kennzeichen ohne Sperrwirkung, änderbar nur bei offenen Aufträgen
- [x] 2.2 Neue Page Extension 60337 "CXW Sales Order List" auf "Sales Order List": Feld "CXW Hold Order" als letzte Spalte des Repeaters, gleicher ToolTip

## 3. Übersetzungen und Doku

- [x] 3.1 Vollständig kompilieren, `CHX.Webshop.g.xlf` neu erzeugen, neue Einträge in `CHX.Webshop.de-DE.xlf` übersetzen (Caption "Auftrag halten")
- [x] 3.2 Handbücher unter `docs/` ergänzen (Key User und Anwender, de/en): Zweck, Bedienung, ausdrücklich keine Sperrwirkung

## 4. Prüfung

- [x] 4.1 Neuer Auftrag hat "Auftrag halten" = Nein; Setzen und Entfernen wird gespeichert
- [x] 4.2 Bei freigegebenem Auftrag ist das Feld auf der Seite ausgegraut; eine Änderung per Code bricht mit dem Status-Fehler ab und der Wert bleibt erhalten; nach "Erneut öffnen" ist es wieder änderbar
- [x] 4.3 Verkaufsauftragsliste lässt sich auf "Auftrag halten" = Ja filtern
- [x] 4.4 Angehaltener Auftrag lässt sich ohne Fehler freigeben, liefern und fakturieren
