## Why

Uhren, die auf Kommission angekauft wurden (Item mit `"CXB Consignment Sales"` = true, Feld aus `CHX.Base`), lösen aktuell keine automatische EK-Faktura aus, wenn die zugehörige VK-Rechnung gebucht wird. Der Wareneingang der Einkaufsbestellung ist zu diesem Zeitpunkt bereits erfolgt (Workshop-Prozess), die Faktura an den Kommissionsgeber muss aber erst nach einer vertraglich vereinbarten, einrichtbaren Anzahl Tage nach dem Verkauf erfolgen — nicht sofort und nicht manuell.

## What Changes

- Neue Setup-Option `"CXW SW Consignment Invoice Delay (Days)"` (Integer, >= 0) auf der bestehenden Table Extension "CXW SW Purchases Setup" (extends "Purchases & Payables Setup"), sichtbar auf der zugehörigen Page Extension "CXW SW Purchases Setup". Gilt global für alle Artikel/Kreditoren.
- Neue Tabelle `"CXW Consignment Posting Entry"` samt List-Page: ein Eintrag pro gebuchter VK-Rechnungszeile eines Kommissionsartikels, mit Status (`Open` / `Posted` / `Error`), ermittelter Einkaufsbestellung, Fälligkeitsdatum und Fehlertext. Die List-Page erlaubt die manuelle Rücksetzung fehlerhafter Einträge auf `Open` sowie eine Aktion "Erneut versuchen".
- Neuer Event-Subscriber auf die VK-Rechnungsbuchung (`OnAfterPostSalesDoc` der Codeunit "Sales-Post"), der bei jeder gebuchten Rechnung (nicht bei reiner Lieferung) pro Zeile mit `Type = Item` und `"CXB Consignment Sales"` = true einen `"CXW Consignment Posting Entry"` anlegt. Die zugehörige offene, bereits wareneingebuchte, aber noch nicht fakturierte Einkaufsbestellung wird automatisch ermittelt (genau 1 Treffer → Status `Open`; 0 oder >1 Treffer → Eintrag mit Status `Error` und sprechendem Fehlertext, VK-Buchung wird dadurch nicht blockiert).
- Neue Job-Queue-fähige Codeunit `"CXW Post Consignment Purchases"`, die fällige Einträge (`Status = Open`, `"Due Date" <= Today`) verarbeitet: `"Vendor Invoice No."` auf der Einkaufsbestellung setzen (falls leer), `"Qty. to Invoice"` auf die noch nicht fakturierte, bereits erhaltene Menge setzen, mit Codeunit "Purch.-Post" fakturieren (Receive = false, Invoice = true). Jeder Eintrag wird einzeln fehlerbehandelt und committet; bei Fehlern bleibt der Eintrag mit Status `Error` zur manuellen Nachbearbeitung stehen.
- Permission-Set-Erweiterung für die neuen Objekte, deutsche/englische Captions und Translations, Labels statt hartkodierter Strings — entsprechend bestehender Projektkonventionen.
- **Kein** neues Item-Feld: Die bereits über die Dependency `CHX.Base` (Version 27.0.2.1) vorhandene Tabellenerweiterung liefert `"CXB Consignment Sales"` (Boolean) auf `Item` bereits inklusive Anzeige auf der Item Card — dieses Feld wird wiederverwendet statt dupliziert.

## Capabilities

### New Capabilities
- `sellwatch-consignment-delayed-purchase-invoice`: Verzögerte, einrichtbare automatische EK-Faktura von Einkaufsbestellungen zu auf Kommission verkauften Artikeln, ausgelöst durch die VK-Rechnungsbuchung und verarbeitet über eine Job-Queue-fähige Warteschlange mit Fehlerbehandlung und manueller Nachbearbeitung.

### Modified Capabilities
(keine — keine bestehende Spec ändert ihr Verhalten; die Erweiterung von "CXW SW Purchases Setup" fügt nur ein zusätzliches, unabhängiges Feld hinzu und berührt nicht die in `sellwatch-item-template-setup` beschriebenen Requirements)

## Impact

- **Neue Objekte** (ID-Bereich 60300–60349, aktuell höchste vergebene ID 60340 → 9 freie IDs): 1 Tabelle, 1 List-Page, 1 Enum (Status), 1 Codeunit (Subscriber + Job-Queue-Verarbeitung, ggf. 2 Codeunits je nach Trennung in design.md).
- **Geänderte Objekte**: Tabellenerweiterung "CXW SW Purchases Setup" (60322) und Page-Erweiterung "CXW SW Purchases Setup" (60330) — je ein neues Feld; Permission Set "CXW Workshop All" (60301) um die neuen Objekte erweitert (deckt bereits Purchase Header/Line und Item für denselben SellWatch/Workshop-Einkaufsprozess ab).
- **Abhängigkeit**: Setzt `"CXB Consignment Sales"` aus `CHX.Base` (bereits als Dependency in `app.json` auf 27.0.2.1 gepflegt) voraus — keine weitere Dependency-Änderung nötig.
- **Betroffene Prozesse**: VK-Rechnungsbuchung (zusätzlicher, fehlertoleranter Subscriber, darf die Buchung nie zum Abbruch bringen), Job-Queue-Einrichtung (neuer, empfohlen täglich laufender Eintrag), Einkaufsbestellungs-Fakturierung (automatisiert statt manuell für Kommissionsware).
- **Kein Einfluss** auf den bestehenden Storno-/Workshop-Prozess: Für stornierte SellWatch-Anfragen (PO bereits gelöscht) entsteht beim Verkauf ohnehin kein Eintrag mit Status `Open` (0-Treffer-Fall greift als `Error`) — das ist erwartetes, akzeptiertes Verhalten.
