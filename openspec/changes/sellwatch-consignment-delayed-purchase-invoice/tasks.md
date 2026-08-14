## 1. Setup-Erweiterung: Verzögerungs-Tage

- [x] 1.1 In `src/TableExtensions/TabExt60322.CXWSWPurchasesSetup.al` Feld `field(60301; "CXW SW Consignment Invoice Delay (Days)"; Integer)` mit `MinValue = 0` und passender Caption ergänzen.
- [x] 1.2 In `src/PageExtensions/PagExt60330.CXWSWPurchasesSetup.al` das neue Feld in derselben Gruppe wie `"CXW SW Item Template Code"` sichtbar machen.

## 2. Warteschlangen-Datenmodell

- [x] 2.1 Neues Enum `enum 60343 "CXW Consignment Posting Status"` (`src/Enums/Enum60343.CXWConsignmentPostingStatus.al`) mit Werten `Open` (0), `Posted` (1), `Error` (2) anlegen, `Extensible = true`.
- [x] 2.2 Neue Tabelle `table 60341 "CXW Consignment Posting Entry"` (`src/Tables/Tab60341.CXWConsignmentPostingEntry.al`) mit Feldern: `"CXW Entry No"` (Integer, AutoIncrement, PK), `"CXW Item No."` (Code[20], TableRelation Item), `"CXW Purchase Order No."` (Code[20], TableRelation "Purchase Header"."No." where "Document Type" = const(Order)), `"CXW Sales Invoice No."` (Code[20], TableRelation "Sales Invoice Header"), `"CXW Sales Posting Date"` (Date), `"CXW Due Date"` (Date), `"CXW Status"` (Enum "CXW Consignment Posting Status"), `"CXW Error Text"` (Text[250]) anlegen.
- [x] 2.3 Neue List-Page `page 60342 "CXW Consignment Posting Entries"` (`src/Pages/Pag60342.CXWConsignmentPostingEntries.al`) über die Tabelle anlegen: alle Felder als Spalten, Aktion "Erneut versuchen" (setzt `"CXW Status"` von `Error` auf `Open` für die markierten Zeilen, nur wenn aktueller Status `Error` ist).

## 3. Erkennung bei VK-Rechnungsbuchung

- [x] 3.1 Neue Codeunit `codeunit 60344 "CXW Consignment Sale Detection"` (`src/Codeunits/Codeunit60344.CXWConsignmentSaleDetection.al`) mit `[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]` anlegen.
- [x] 3.2 Im Subscriber: frühzeitig abbrechen, wenn `SalesInvoiceHdrNo = ''` (keine Rechnung gebucht, nur Lieferung) oder `PreviewMode = true`.
- [x] 3.3 Gebuchte `Sales Invoice Line`-Zeilen der Rechnung mit `Type = Item` durchlaufen; je Zeile Artikel lesen und nur bei `"CXB Consignment Sales"` = true weiterverarbeiten.
- [x] 3.4 Passende offene Einkaufsbestellung ermitteln (`Purchase Line` gefiltert auf `Type = Item`, `"No." = Item No.`, `"Quantity Received" > 0`, `"Qty. to Invoice" > 0`, verknüpft über `Purchase Header."Document Type" = Order`); bei genau 1 Treffer PO-Nr. übernehmen und Status `Open`, bei 0 oder >1 Treffer Status `Error` mit sprechendem Fehlertext setzen (Referenz Item-Nr. im Text).
- [x] 3.5 `"CXW Due Date"` aus `"CXW Sales Posting Date"` (= Buchungsdatum der Rechnung) plus `"CXW SW Consignment Invoice Delay (Days)"` aus der Einkaufseinrichtung berechnen.
- [x] 3.6 Die komplette Verarbeitung je Rechnungszeile in eine `[TryFunction]` kapseln und im Subscriber abfangen (kein `Error()` darf aus dem Subscriber nach außen dringen) — analog zum Muster in `Codeunit 60331 "CXW Process Workshop Lines"`.

## 4. Verzögerte EK-Fakturierung (Job Queue)

- [x] 4.1 Neue Codeunit `codeunit 60345 "CXW Post Consignment Purchases"` (`src/Codeunits/Codeunit60345.CXWPostConsignmentPurchases.al`) mit `trigger OnRun()` anlegen, das alle Einträge mit `"CXW Status" = Open` und `"CXW Due Date" <= Today` verarbeitet.
- [x] 4.2 Je fälligem Eintrag: zugehörige `Purchase Header` lesen; falls `"Vendor Invoice No."` leer, mit `"CXW Sales Invoice No." + "-CONS"` aus dem Eintrag befüllen.
- [x] 4.3 `"Qty. to Invoice"` auf der zugehörigen `Purchase Line` auf die noch nicht fakturierte, bereits erhaltene Menge setzen.
- [x] 4.4 Mit `Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader)` fakturieren (`Receive = false`, `Invoice = true`).
- [x] 4.5 Bei Erfolg Status auf `Posted` setzen und committen; bei Fehler `"CXW Error Text"` mit `GetLastErrorText()` befüllen, Status auf `Error` setzen und committen — Verarbeitung pro Eintrag in `[TryFunction]` kapseln, analog `Codeunit 60331`, damit ein fehlerhafter Eintrag die übrigen fälligen Einträge nicht blockiert.

## 5. Berechtigungen, Captions, Übersetzungen

- [x] 5.1 Die neuen Objekte (Table 60341, Page 60342, Codeunit 60344, Codeunit 60345, plus Sales Invoice Header/Line- und Purchases & Payables Setup-Lesezugriff) in `CXW Workshop All` (60301) ergänzt — passt am besten, da dieses Permission Set bereits Purchase Header/Line/Item für denselben SellWatch/Workshop-Einkaufsprozess abdeckt.
- [x] 5.2 Alle neuen Captions (Feld-, Tabellen-, Seiten-, Enum-Captions sowie Fehlertexte als Labels statt hartkodierter Strings) mit `Translations/CHX.Webshop.g.xlf` synchronisieren und in `Translations/CHX.Webshop.de-DE.xlf` übersetzen. Nutzer hat zwischenzeitlich in VS Code kompiliert (g.xlf enthält jetzt reale, compiler-generierte trans-unit-IDs für alle neuen Objekte; das Page-Objekt wurde dabei zu `"CXW Cons. Posting Entries"` umbenannt). Alle 27 neuen/geänderten Trans-Units in `CHX.Webshop.de-DE.xlf` übersetzt (u. a. "Consignment" → "Kommission", passend zur offiziellen `CHX.Base`-Übersetzung von `"CXB Consignment Sales"` = "Kommissionsverkauf"), NAB-AL-Tool-Artefakte (`[NAB: SUGGESTION]`/`[NAB: NOT TRANSLATED]`-Präfixe, doppelte `<target>`-Elemente, `"NAB AL Tool Refresh Xlf"`-Notizen) bereinigt. XML-Validität und 1:1-Trans-Unit-Anzahl (467/467) gegen `g.xlf` geprüft.

## 6. Verifikation

- [ ] 6.1 Extension in VS Code kompilieren, Compiler-Fehler/-Warnungen beheben.
- [ ] 6.2 Manueller Testlauf: Kommissionsartikel verkaufen und per Rechnung buchen (Verkaufsauftrag Liefern & Fakturieren) → prüfen, dass genau ein `"CXW Consignment Posting Entry"` mit Status `Open` und korrektem `"CXW Due Date"` entsteht.
- [ ] 6.3 Manueller Testlauf: separate Verkaufsrechnung für Kommissionsartikel buchen → Eintrag entsteht ebenfalls.
- [ ] 6.4 Manueller Testlauf: reine Lieferung ohne Fakturierung → kein Eintrag entsteht.
- [ ] 6.5 Manueller Testlauf: Verkauf eines Artikels ohne `"CXB Consignment Sales"` → kein Eintrag entsteht.
- [ ] 6.6 Manueller Testlauf: PO vor Fälligkeit bereits storniert/gelöscht → Job-Queue-Lauf setzt betroffenen Eintrag auf `Error`, andere fällige Einträge werden trotzdem verarbeitet.
- [ ] 6.7 Manueller Testlauf: `"CXW Post Consignment Purchases"` als Job-Queue-Eintrag einrichten und einen fälligen `Open`-Eintrag verarbeiten lassen → EK-Rechnung wird gebucht, Status wechselt auf `Posted`.
- [ ] 6.8 Manueller Testlauf: Eintrag mit Status `Error` über die Liste per "Erneut versuchen" auf `Open` zurücksetzen und erneuten Verarbeitungslauf bestätigen.
- [ ] 6.9 README/Setup-Hinweis ergänzen, dass `"CXW Post Consignment Purchases"` als täglicher Job-Queue-Eintrag eingerichtet werden sollte (Empfehlung, keine harte Vorgabe).
