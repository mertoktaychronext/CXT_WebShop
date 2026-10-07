## 1. Gemeinsame Attribut-Logik (Codeunit 60335)

- [x] 1.1 `GetWorkshopAttributeName` durch `GetWorkshopAttributeId` ersetzen (22, 18, 23, 16, 15, 24, 20, 0, 0, 0) und alle Aufrufer umstellen
- [x] 1.2 `GetWorkshopAttributeFallbackId`, `IsUnchangedFallbackValue` und `FindItemAttributeId` entfernen; `FillEmptyWorkshopAttributes` liest nur noch per ID (bei ID 0 nichts)
- [x] 1.3 `SetItemAttributeValue(ItemNo; AttributeId; Value)` und `GetOrCreateAttributeValueId(AttributeId; Value)` aus Codeunit 60331 nach 60335 verschieben und auf ID umstellen; keine Attributanlage mehr, Fehler bei nicht existierender Attribut-ID

## 2. Werkstatt-Rückschreiben (Codeunit 60331)

- [x] 2.1 `ProcessGenuineLine` auf `GetWorkshopAttributeId` umstellen: nur ID <> 0 und Wert <> '' schreiben, Ersatzwert-Prüfung entfernen
- [x] 2.2 Lokale Prozeduren `SetItemAttributeValue`, `GetOrCreateAttributeId`, `GetOrCreateAttributeValueId` entfernen

## 3. SellWatch-Attributübernahme (Codeunit 60305)

- [x] 3.1 Lokale Prozedur `SetSellWatchItemAttributes(ItemNo)` anlegen und am Ende von `CreateSellWatchItem` aufrufen (1 Brand, 2 Model, 5 Reference, 8 Construction Year, 10 Watch Condition, 11 Box, 12 Taxation, 13 Paper, 24 Gender)
- [x] 3.2 Leere Werte überspringen, Box/Papiere als „ja“/„nein“, Baujahr nur bei gültiger Ganzzahl
- [x] 3.3 Permission Set 60310 „CXW SWChronWSAll“ um `Item Attribute` = R, `Item Attribute Value` = RI, `Item Attribute Value Mapping` = RIM ergänzen

## 3a. Seriennummernverfolgung (Codeunit 60305)

- [x] 3a.1 `GetSellWatchItemTemplateCode`: prüfen, dass die Vorlage einen Artikelverfolgungscode mit „SN Purchase Inbound Tracking“ hat, sonst Fehler mit Vorlagencode (neues Label)
- [x] 3a.2 Kompilieren und Übersetzung für das neue Label ergänzen
- [x] 3a.3 Test: Vorlage mit SN-Code → Artikel hat den Code; Vorlage ohne Code bzw. mit reinem Chargen-Code → Angebot bleibt mit Fehler offen, kein Artikel
- [x] 3a.4 Key-User-Handbuch (SellWatch-Artikelvorlagen, DE/EN) und Funktionsregister ergänzen

## 4. Oberfläche, Übersetzung, Build

- [x] 4.1 ToolTips der Prüfmerkmale auf Page 60338 an die ID-Zuordnung anpassen (Ersatz-Hinweise entfernen; Features/Attribut 9/10 als Platzhalter ohne Rückschreiben beschreiben)
- [x] 4.2 Kompilieren, `de-DE.xlf` für geänderte/neue Texte ergänzen und veraltete Einträge entfernen
- [x] 4.3 Build ohne Fehler und ohne neue CodeCop/UICop-Warnungen

## 5. Test

- [x] 5.1 SellWatch-Anfrage mit allen Feldern: Attribute 1, 2, 5, 8, 10, 11, 12, 13, 24 am neuen Artikel korrekt
- [x] 5.2 SellWatch-Anfrage mit leerer Referenz und Baujahr „ca. 2015“: Attribute 5/8 leer, Angebot ohne Fehler angelegt
- [x] 5.3 SellWatch-Anfrage mit unbekanntem Modell: neuer Wert für Attribut 2 angelegt, kein neues Attribut
- [x] 5.4 Send to Workshop für SellWatch-Artikel: Stammdaten (Marke, Modell, Referenz, Jahr, Zustand, Box, Zertifikat) und Gender = Geschlecht auf der Werkstattzeile; Features/Attribut 9/10 leer
- [x] 5.5 Werkstatt korrigiert Dial Color und meldet Case Diameter „41“ → Attribute 22 und 18 geändert; Features/Attribut 9 gefüllt → nicht zurückgeschrieben, Zeile „Verarbeitet“
- [x] 5.6 Werkstatt meldet Case Diameter „41 mm“ → Zeile auf „Fehler“ mit Fehlertext; Dezimalwert „41,5“/„41.5“ prüfen
- [x] 5.7 Nach allen Tests existiert kein englisches Attribut („Dial Color“, „Gender“ …)

## 6. Dokumentation

- [x] 6.1 Benutzer- und Key-User-Handbuch (DE/EN): SellWatch-Attributübernahme und Werkstatt-Zuordnung beschreiben
- [x] 6.2 Funktionsregister (Codeunit 60305, 60331, 60335) nachziehen
