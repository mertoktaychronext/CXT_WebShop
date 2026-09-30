## Why

Anwender müssen einzelne Verkaufsaufträge als "angehalten" markieren können, damit sie im Tagesgeschäft sofort erkennen, dass ein Auftrag vorerst nicht weiterbearbeitet werden soll, und solche Aufträge in der Auftragsliste filtern können. Heute gibt es dafür im Verkaufskopf kein Feld (weder im Standard noch in CHX.Base oder ChronextBC).

## What Changes

- Der Verkaufskopf ("Sales Header") erhält ein neues Boolean-Feld **"Auftrag halten"** (Caption `Hold Order`, de-DE "Auftrag halten").
- Das Feld wird **nur manuell** vom Anwender gesetzt und entfernt, und zwar **nur solange der Auftrag offen ist**. Bei freigegebenen Aufträgen ist es schreibgeschützt; zum Ändern muss der Auftrag erneut geöffnet werden.
- Das Feld ist ein **reines Kennzeichen**: Freigabe, Buchung, Lager und Versand werden dadurch **nicht** gesperrt.
- Anzeige und Bearbeitung auf der Seite **Verkaufsauftrag** (Page 42), Anzeige und Filter in der **Verkaufsauftragsliste** (Page 9305).
- de-DE-Übersetzung und Handbücher werden ergänzt.

## Capabilities

### New Capabilities
- `sales-order-hold-flag`: Manuelles Kennzeichen "Auftrag halten" am Verkaufsauftrag, seine Anzeige, Filterbarkeit und die ausdrückliche Abgrenzung (keine Sperrwirkung).

### Modified Capabilities
- (keine)

## Impact

- Neu: Table Extension auf "Sales Header" (Feld "CXW Hold Order").
- `src/PageExtensions/PagExt60334.CXWSalesOrder.al`: Feld auf der Seite Verkaufsauftrag.
- Neu: Page Extension auf "Sales Order List".
- `Translations/CHX.Webshop.de-DE.xlf`, Handbücher unter `docs/`.
- Keine Schnittstellen, keine Datenmigration, keine Auswirkung auf bestehende Prozesse (nicht breaking).
