## ADDED Requirements

### Requirement: Einrichtbare Verzögerung für die Konsignations-EK-Faktura
Die Einkaufseinrichtung SHALL ein Feld `"CXW SW Consignment Invoice Delay (Days)"` (Integer, >= 0) bereitstellen, das global für alle Artikel und Kreditoren die Anzahl Tage zwischen VK-Rechnungsbuchung und automatischer EK-Fakturierung festlegt.

#### Scenario: Fälligkeitsdatum wird aus der Einrichtung berechnet
- **WHEN** ein `"CXW Consignment Posting Entry"` für eine gebuchte VK-Rechnung angelegt wird und in der Einkaufseinrichtung `"CXW SW Consignment Invoice Delay (Days)"` = N Tage hinterlegt ist
- **THEN** wird das `"Due Date"` des Eintrags auf das Buchungsdatum der VK-Rechnung plus N Tage gesetzt

### Requirement: Erkennung von Kommissionsverkäufen bei VK-Rechnungsbuchung
Beim Buchen einer Verkaufsrechnung (Verkaufsauftrag mit Liefern & Fakturieren oder separate Verkaufsrechnung) SHALL das System für jede gebuchte Rechnungszeile mit `Type = Item`, deren Artikel `"CXB Consignment Sales"` = true ist, einen `"CXW Consignment Posting Entry"` anlegen. Wird nur geliefert, ohne zu fakturieren, SHALL kein Eintrag angelegt werden.

#### Scenario: VK-Auftrag wird geliefert und fakturiert
- **WHEN** ein Verkaufsauftrag mit einer Zeile eines Artikels mit `"CXB Consignment Sales"` = true mit Liefern & Fakturieren gebucht wird
- **THEN** wird ein `"CXW Consignment Posting Entry"` mit `"Item No."`, `"Sales Invoice No."` und `"Sales Posting Date"` der gebuchten Rechnung angelegt

#### Scenario: Separate Verkaufsrechnung wird gebucht
- **WHEN** eine eigenständige Verkaufsrechnung mit einer Zeile eines Artikels mit `"CXB Consignment Sales"` = true gebucht wird
- **THEN** wird ein `"CXW Consignment Posting Entry"` für diese Zeile angelegt

#### Scenario: Reine Lieferung ohne Fakturierung
- **WHEN** ein Verkaufsauftrag mit einer Zeile eines Artikels mit `"CXB Consignment Sales"` = true nur geliefert wird, ohne zu fakturieren
- **THEN** wird kein `"CXW Consignment Posting Entry"` angelegt

#### Scenario: Verkaufszeile ohne Kommissionsware
- **WHEN** eine Verkaufsrechnung mit einer Zeile eines Artikels gebucht wird, dessen `"CXB Consignment Sales"` = false ist
- **THEN** wird für diese Zeile kein `"CXW Consignment Posting Entry"` angelegt

### Requirement: Automatische Ermittlung der zugehörigen Einkaufsbestellung
Beim Anlegen eines `"CXW Consignment Posting Entry"` SHALL das System die offene Einkaufsbestellung (`"Document Type" = Order`) ermitteln, deren Zeile denselben Artikel enthält, deren Wareneingang gebucht ist und die noch nicht (voll) fakturiert ist. Bei genau einem Treffer SHALL die Bestellnummer im Eintrag hinterlegt und der Status auf `Open` gesetzt werden. Bei keinem oder mehr als einem Treffer SHALL der Eintrag dennoch angelegt werden, mit Status `Error` und einem sprechenden Fehlertext.

#### Scenario: Eindeutige offene Bestellung gefunden
- **WHEN** genau eine offene, wareneingebuchte, nicht fakturierte Einkaufsbestellung mit einer Zeile desselben Artikels existiert
- **THEN** wird deren Bestellnummer in `"Purchase Order No."` des Eintrags eingetragen und der Status auf `Open` gesetzt

#### Scenario: Keine passende Bestellung gefunden
- **WHEN** keine offene, wareneingebuchte, nicht fakturierte Einkaufsbestellung mit einer Zeile desselben Artikels existiert
- **THEN** wird der Eintrag mit Status `Error` und einem Fehlertext angelegt, der auf die fehlende Bestellung hinweist, und `"Purchase Order No."` bleibt leer

#### Scenario: Mehrere passende Bestellungen gefunden
- **WHEN** mehr als eine offene, wareneingebuchte, nicht fakturierte Einkaufsbestellung mit einer Zeile desselben Artikels existiert
- **THEN** wird der Eintrag mit Status `Error` und einem Fehlertext angelegt, der auf die mehrdeutige Zuordnung hinweist, und `"Purchase Order No."` bleibt leer

### Requirement: VK-Buchung wird durch die Erkennung nie blockiert
Tritt bei der Erzeugung eines `"CXW Consignment Posting Entry"` oder bei der PO-Ermittlung ein unerwarteter Fehler auf, SHALL dieser abgefangen werden und die auslösende VK-Rechnungsbuchung SHALL trotzdem erfolgreich abgeschlossen werden.

#### Scenario: Unerwarteter Fehler bei der Entry-Erzeugung
- **WHEN** beim Anlegen eines `"CXW Consignment Posting Entry"` während einer VK-Rechnungsbuchung ein unerwarteter Fehler auftritt
- **THEN** wird die VK-Rechnungsbuchung dennoch vollständig gebucht

### Requirement: Automatische verzögerte EK-Fakturierung fälliger Einträge
Eine Job-Queue-fähige Verarbeitung SHALL alle `"CXW Consignment Posting Entry"`-Datensätze mit Status `Open` und `"Due Date" <= heute` verarbeiten: die zugehörige Einkaufsbestellung SHALL mit der noch nicht fakturierten, bereits erhaltenen Menge fakturiert werden (ohne erneuten Wareneingang), und der Eintrag SHALL danach auf Status `Posted` gesetzt werden.

#### Scenario: Fälliger Eintrag wird erfolgreich fakturiert
- **WHEN** ein `"CXW Consignment Posting Entry"` mit Status `Open` ein `"Due Date"` in der Vergangenheit oder heute hat und die Verarbeitung läuft
- **THEN** wird die referenzierte Einkaufsbestellung mit der offenen Menge fakturiert (Receive = false, Invoice = true) und der Eintrag erhält Status `Posted`

#### Scenario: Noch nicht fälliger Eintrag wird nicht verarbeitet
- **WHEN** ein `"CXW Consignment Posting Entry"` mit Status `Open` ein `"Due Date"` in der Zukunft hat und die Verarbeitung läuft
- **THEN** bleibt der Eintrag unverändert mit Status `Open`

#### Scenario: Fakturierung eines Eintrags schlägt fehl
- **WHEN** die Fakturierung der referenzierten Einkaufsbestellung für einen fälligen Eintrag fehlschlägt
- **THEN** erhält der Eintrag Status `Error` mit dem Fehlertext, und die Verarbeitung der übrigen fälligen Einträge desselben Laufs wird fortgesetzt

#### Scenario: Fehlende Kreditorenrechnungsnummer wird ergänzt
- **WHEN** die referenzierte Einkaufsbestellung eines fälligen Eintrags kein `"Vendor Invoice No."` hinterlegt hat
- **THEN** wird vor dem Fakturieren `"Vendor Invoice No."` auf die auslösende VK-Rechnungsnummer (`"CXW Sales Invoice No."` des Eintrags) plus Suffix `-CONS` gesetzt

### Requirement: Manuelle Nachbearbeitung fehlerhafter Einträge
Es SHALL eine Übersicht aller `"CXW Consignment Posting Entry"`-Datensätze geben, über die ein Eintrag mit Status `Error` nach manueller Korrektur wieder auf Status `Open` zurückgesetzt und erneut zur Verarbeitung angestoßen werden kann.

#### Scenario: Fehlerhaften Eintrag zurücksetzen und erneut versuchen
- **WHEN** ein Benutzer auf der Übersichtsseite einen Eintrag mit Status `Error` auswählt und die Aktion "Erneut versuchen" ausführt
- **THEN** wird der Status des Eintrags auf `Open` gesetzt, sodass er beim nächsten Job-Queue-Lauf erneut verarbeitet wird
