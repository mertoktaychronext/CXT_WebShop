## Context

Uhren werden im SellWatch/Workshop-Ankaufsprozess als eigene Artikel angelegt (ein Artikel = eine Uhr, Menge 1) und über eine Einkaufsbestellung mit genau einer Zeile eingekauft (siehe `Codeunit 60305 "CXW SellWatch Mgt"`, `Codeunit 60331 "CXW Process Workshop Lines"`). Der Wareneingang dieser Bestellung wird bereits im Workshop-Prozess gebucht (`ProcessGenuineLine`, Receive = true, Invoice = false). Für Kommissionsware (Item `"CXB Consignment Sales"` = true, Feld aus der Dependency `CHX.Base` 27.0.2.1) soll die EK-Faktura erst verzögert erfolgen, ausgelöst durch die VK-Rechnungsbuchung.

Die App-ID-Range ist `60300–60349`; die höchste bislang vergebene ID ist `60340`. Für diese Änderung stehen damit `60341–60349` (9 IDs) zur Verfügung — ausreichend, aber knapp, daher werden Objekte sparsam vergeben.

## Goals / Non-Goals

**Goals:**
- Bei Buchung einer VK-Rechnung mit einer Kommissionsware-Zeile automatisch einen nachvollziehbaren, editierbaren Warteschlangen-Eintrag erzeugen, ohne die VK-Buchung selbst jemals zu gefährden.
- Die zugehörige EK-Faktura erst nach einer konfigurierbaren Anzahl Tage automatisiert buchen, mit Fehlertoleranz pro Eintrag (ein fehlerhafter Eintrag blockiert nicht die anderen).
- Manuelle Nachbearbeitung fehlerhafter Fälle über eine List-Page ermöglichen.

**Non-Goals:**
- Keine Änderung am bestehenden Storno-/Workshop-Prozess (PO-Löschung bei nicht-echten Artikeln bleibt unverändert).
- Keine Unterstützung für Bestellungen mit mehreren Zeilen oder mehreren Uhren pro Bestellung (wie im gesamten SellWatch-Prozess: 1 Artikel = 1 PO = 1 PL, siehe bestehender Kommentar in `Codeunit 60331`).
- Keine Neuentwicklung des Consignment-Flags auf Item — `"CXB Consignment Sales"` aus `CHX.Base` wird 1:1 wiederverwendet, kein eigenes Feld in `CHX.Webshop`.
- Keine UI zur manuellen Ersterfassung von Warteschlangen-Einträgen — Einträge entstehen ausschließlich automatisch über den Subscriber.

## Decisions

### Wiederverwendung von `"CXB Consignment Sales"` statt eigenem Feld
Das Feld existiert bereits identisch (Boolean, Zweck "Konsignationsware") in der Dependency `CHX.Base`, inklusive Anzeige auf der Item Card. Ein zusätzliches, fast gleichnamiges Feld in `CHX.Webshop` (wie ursprünglich mit `CXB Consignment Sale` beauftragt) hätte zwei Wahrheiten für dieselbe fachliche Aussage erzeugt und wäre zudem inkonsistent mit dem in `CHX.Webshop` durchgängig verwendeten `CXW`-Präfix. **Alternative verworfen:** eigenes `CXW Consignment Sale`-Feld — hätte Pflege an zwei Stellen erfordert.

### Setup-Feld auf bestehender Table Extension statt neuer Setup-Tabelle
`"CXW SW Purchases Setup"` (Tabellenerweiterung 60322 auf `Purchases & Payables Setup`) existiert bereits für SellWatch-spezifische Einkaufs-Einrichtung (`"CXW SW Item Template Code"`). Das neue Feld `"CXW SW Consignment Invoice Delay (Days)"` (Integer, `MinValue = 0`) wird dort ergänzt, ebenso auf der zugehörigen Page Extension 60330. **Alternative verworfen:** neue eigenständige Setup-Tabelle (Singleton-Pattern) — hätte für ein einzelnes Integer-Feld unnötig ein neues Table+Page-Objektpaar verbraucht (ID-Range ist knapp) und die SellWatch-Einrichtung auf zwei Stellen verteilt.

### Getrennte Codeunits für Erkennung (Event-Subscriber) und Verarbeitung (Job Queue)
`"CXW Consignment Sale Detection"` (Subscriber auf `Sales-Post`) und `"CXW Post Consignment Purchases"` (Job-Queue-Codeunit) werden als zwei separate Codeunits umgesetzt statt einer kombinierten. **Warum:** unterschiedliche Fehler-Charakteristik — der Subscriber läuft synchron innerhalb einer fremden Buchungstransaktion und darf diese nie zum Abbruch bringen (jeder Fehler wird abgefangen und nur geloggt), während die Job-Queue-Codeunit eigenständig pro Eintrag committen und bei Bedarf regulär mit `Error()` fehlschlagen darf (Standard-Job-Queue-Retry-Verhalten). Das Vermischen beider Fehlermodelle in einer Codeunit erhöht das Risiko, versehentlich einen Fehler im Subscriber zu propagieren. Kostet 1 zusätzliche ID, bei 9 verfügbaren vertretbar.

### PO-Ermittlung über `Purchase Line` statt über gespeicherte Referenz
Da SellWatch die PO-Nummer nicht auf dem Item oder der Sales Line hinterlegt, wird die offene, wareneingebuchte, aber nicht (voll) fakturierte Einkaufsbestellung zum Zeitpunkt der VK-Buchung ermittelt: `Purchase Line.SetRange(Type, Type::Item); SetRange("No.", ItemNo); SetFilter("Quantity Received", '>0'); SetFilter("Qty. to Invoice", '>0')`, verknüpft über `Purchase Header."Document Type" = Order`. Da laut Annahme 1 Artikel genau 1 PO/PL zugeordnet ist, liefert dies im Normalfall genau 1 Treffer. 0 Treffer (z. B. PO storniert/bereits fakturiert) oder >1 Treffer (Dateninkonsistenz) führen zu einem Eintrag mit Status `Error` statt einem harten Fehler — die VK-Buchung bleibt davon unberührt (siehe Non-Goal "Storno-Prozess unverändert").

### Enum-Werte auf Englisch, Captions/Translations wie gehabt
`"CXW Consignment Posting Status"` erhält die Werte `Open` / `Posted` / `Error` (analog zu `"CXW Workshop Line Status"`), mit DE/EN-Captions über die bestehenden Translation-Dateien statt hartkodierter Strings.

### Objekt-ID-Zuordnung (Bereich 60341–60349)
| ID | Objekt |
|---|---|
| 60341 | Table "CXW Consignment Posting Entry" |
| 60342 | Page "CXW Consignment Posting Entries" (List) |
| 60343 | Enum "CXW Consignment Posting Status" |
| 60344 | Codeunit "CXW Consignment Sale Detection" |
| 60345 | Codeunit "CXW Post Consignment Purchases" |

Felder auf bestehenden Objekten: `"CXW SW Purchases Setup"` (Table Ext. 60322) Feld 60301, Page Ext. 60330 entsprechend erweitert. 4 IDs (60346–60349) bleiben nach dieser Änderung frei.

### Fehlerbehandlungs-Pattern für die Job-Queue-Codeunit
Wiederverwendung des in `Codeunit 60331 "CXW Process Workshop Lines"` etablierten Musters: `[TryFunction]`-gekapselte Verarbeitung pro Eintrag, `Commit()` nach Erfolg, bei Fehler `GetLastErrorText()` in `"Error Text"` schreiben, Status auf `Error` setzen, `Commit()`. So bleibt ein Fehler in einem Eintrag ohne Auswirkung auf die übrigen fälligen Einträge desselben Laufs.

### `"Vendor Invoice No."` aus der VK-Rechnungsnummer ableiten
Ist `"Vendor Invoice No."` auf der Einkaufsbestellung beim automatischen Fakturieren leer, wird sie auf die auslösende VK-Rechnungsnummer (`"CXW Sales Invoice No."` des Eintrags) plus Suffix `-CONS` gesetzt, z. B. `VR012345-CONS`. **Warum:** Die VK-Rechnung ist der fachliche Auslöser der verzögerten EK-Faktura und im Eintrag bereits vorhanden (keine zusätzliche Lookup nötig); die Referenz ist für den Kreditoren-Kontext nachvollziehbarer als eine reine PO-Nummer. **Alternative verworfen:** PO-Nr. + `-CONS` — weniger aussagekräftig, da die PO-Nummer intern ist und keinen Bezug zum auslösenden Verkaufsvorgang herstellt.

## Risks / Trade-offs

- **[Risk]** Zwischen VK-Rechnungsbuchung (Entry-Erzeugung) und dem täglichen Job-Queue-Lauf (Verarbeitung) kann sich der Bestand der offenen PO ändern (z. B. manuelle Stornierung) → **Mitigation:** die Job-Queue-Codeunit liest die PO zum Verarbeitungszeitpunkt erneut und behandelt einen inzwischen ungültigen/fehlenden PO-Bezug als regulären Fehlerfall (Status `Error`, Eintrag bleibt zur manuellen Prüfung stehen), statt den Lauf abzubrechen.
- **[Risk]** `"Vendor Invoice No."` wird beim automatischen Fakturieren mit `"CXW Sales Invoice No." + "-CONS"` belegt, falls leer — keine Auswirkung auf Buchungskorrektheit, nur auf die Nachvollziehbarkeit der Lieferantenreferenz.
- **[Risk]** Enge ID-Range (nur 4 IDs Headroom nach dieser Änderung) → **Mitigation:** keine im Rahmen dieser Änderung, aber als Hinweis für künftige Erweiterungen der Range im `idRanges`-Abschnitt von `app.json` festgehalten.
- **[Trade-off]** Die PO-Ermittlung verlässt sich vollständig auf die Annahme "1 Artikel = 1 offene PO/PL". Bricht diese Annahme (z. B. künftig mehrere Bestellungen pro Artikel), liefert die Filterung stumpf einen `Error`-Eintrag statt einer präziseren Auflösung — bewusst in Kauf genommen, da identisch zur bestehenden Prämisse in `Codeunit 60331`.

## Migration Plan

Keine Datenmigration nötig — rein additive neue Objekte und Felder, keine bestehenden Daten werden umstrukturiert. Rollout-Reihenfolge: (1) Objekte deployen, (2) Setup-Feld `"CXW SW Consignment Invoice Delay (Days)"` befüllen, (3) Job-Queue-Eintrag für `"CXW Post Consignment Purchases"` einrichten (empfohlen täglich), (4) danach greift der Subscriber automatisch bei der nächsten VK-Rechnungsbuchung. Rollback: Job-Queue-Eintrag deaktivieren und Extension-Version zurückstufen; bereits erzeugte, aber noch offene `"CXW Consignment Posting Entry"`-Einträge bleiben als reine Log-Daten ohne Fremdschlüssel-Constraints unschädlich liegen.

## Open Questions

- Empfohlenes Job-Queue-Intervall "täglich" ist ein Vorschlag aus der Anweisung — endgültige Kadenz mit Fachbereich abstimmen.
