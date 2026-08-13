## Why

Codeunit 60305 "CXW SellWatch Mgt" legt für jede eingehende SellWatch-Ankaufsanfrage per `CreateSellWatchItem` dynamisch einen neuen Artikel anhand einer Artikelvorlage an. Welche Artikelvorlage dabei verwendet wird, ist aktuell nicht konfigurierbar: der Code nimmt per `ItemTemplate.FindFirst()` einfach die erste beliebige Artikelvorlage aus der Tabelle "Item Templ." — mit einem offenen `// TODO: Item Template einrichtenbar, Wo?` im Quellcode. Das ist keine verlässliche Grundlage für den produktiven Ankaufsprozess: Bei mehreren angelegten Artikelvorlagen ist nicht vorhersehbar, welche verwendet wird, und eine gezielte fachliche Auswahl ist nicht möglich.

## What Changes

- Neues Feld auf der Standard-Tabelle "Purchases & Payables Setup" (Einkaufseinrichtung): `CXW SW Item Template Code`, TableRelation auf "Item Templ.", damit die für SellWatch-Artikelanlage zu verwendende Artikelvorlage explizit konfiguriert werden kann.
- Neue Seitenerweiterung auf der Einkaufseinrichtungs-Karte (Standard-Page "Purchases & Payables Setup") zur Anzeige/Pflege dieses Felds mit erklärendem ToolTip.
- Codeunit 60305 "CXW SellWatch Mgt", Prozedur `CreateSellWatchItem`: liest die Artikelvorlage jetzt aus dem neuen Einrichtungsfeld statt `ItemTemplate.FindFirst()`; klare, unterscheidbare Fehlermeldungen, falls das Feld nicht befüllt ist bzw. die referenzierte Artikelvorlage nicht (mehr) existiert. Der zugehörige `// TODO`-Kommentar wird entfernt.
- Permission Set "CXW SWChronWSAll" (60310) um Lesezugriff auf `Purchases & Payables Setup` ergänzt, damit die Job-Queue-Ausführung von Codeunit 60305 das neue Feld lesen kann, ohne von fehlenden Berechtigungen blockiert zu werden (in diesem Projekt bereits einmal als konkretes Problem bei Job-Queue-Berechtigungen aufgetreten).

## Capabilities

### New Capabilities
- `sellwatch-item-template-setup`: Konfigurierbare Auswahl der Artikelvorlage für die dynamische SellWatch-Artikelanlage über die Einkaufseinrichtung, inklusive Fehlerbehandlung bei fehlender/ungültiger Konfiguration.

### Modified Capabilities
(keine — die bisherige `FindFirst()`-Logik zur Artikelanlage ist in keiner bestehenden Spec dokumentiert; dies ist die erste spec-gestützte Erfassung dieses Verhaltens)

## Impact

- **Neue/geänderte Objekte** (Präfix `CXW`, ID-Bereich 60300–60349): TableExtension 60322 "CXW SW Purchases Setup" (auf "Purchases & Payables Setup", neues Feld ab Field-ID 60300 — erste CXW-Erweiterung dieser Basistabelle), PageExtension 60330 (auf Page "Purchases & Payables Setup"), Codeunit 60305 "CXW SellWatch Mgt" (geänderte Prozedur `CreateSellWatchItem`), Permission Set 60310 "CXW SWChronWSAll" (neuer Tabledata-Eintrag).
- **Keine Datenmigration**: Neues Feld ist zunächst leer; bis zur erstmaligen Konfiguration liefert `CreateSellWatchItem` eine klare Fehlermeldung statt eine zufällige Artikelvorlage zu verwenden — das ist eine bewusste Verhaltensänderung (kein "silent fallback" mehr).
- **Betroffen**: Deutsche/englische Captions und ToolTips (Übersetzungsdateien), Funktionsregister-Dokumentation, README-Hinweis zur Einrichtung.
- **Nicht Teil dieser Änderung**: Die im selben TODO erwähnte, separate Idee einer eigenen Nummernserie für SellWatch-Artikel (aktuell nutzt die Artikelanlage die Nummernserie der gewählten Artikelvorlage bzw. Standard-Artikeleinrichtung) — bleibt als offener Punkt bestehen.
