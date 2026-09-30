## ADDED Requirements

### Requirement: Einzelverarbeitung jedes SellWatch-Angebots in eigener Transaktion
Die SellWatch-Verarbeitung SHALL jedes offene Angebot (`"CXW Created" = false`) in einer eigenen Transaktion verarbeiten (Kreditor suchen/anlegen, Einkaufsbestellung und Artikel anlegen, Bestellung freigeben). Scheitert die Verarbeitung eines Angebots, SHALL ausschließlich die in dieser Verarbeitung vorgenommenen Änderungen zurückgerollt werden, und die Verarbeitung SHALL mit dem nächsten offenen Angebot fortfahren. Bereits erfolgreich verarbeitete Angebote desselben Laufs SHALL NOT zurückgerollt werden.

#### Scenario: Ein Angebot scheitert, die anderen werden verarbeitet
- **WHEN** ein Lauf drei offene Angebote A, B und C verarbeitet und die Verarbeitung von B mit einem Fehler abbricht
- **THEN** sind A und C verarbeitet (Kreditor, freigegebene Bestellung, Artikel vorhanden, `"CXW Created" = true`) und B ist weiterhin offen

#### Scenario: Gescheitertes Angebot hinterlässt keine Teildaten
- **WHEN** die Verarbeitung eines Angebots scheitert, nachdem bereits ein neuer Kreditor oder ein Bestellkopf angelegt wurde
- **THEN** existieren weder der neu angelegte Kreditor samt Bankverbindung noch der Bestellkopf noch ein neuer Artikel aus dieser Verarbeitung, und am Angebot sind `"CXW PO Number"` und `"CXW VendorNo"` unverändert

#### Scenario: Job-Queue-Lauf endet erfolgreich trotz einzelner Fehler
- **WHEN** die Verarbeitung als Aufgabenwarteschlangenposten läuft und mindestens ein Angebot scheitert
- **THEN** endet der Aufgabenwarteschlangenposten ohne Fehler

### Requirement: Fehlerprotokollierung am Angebot
Scheitert die Verarbeitung eines Angebots, SHALL das System am Angebot den Fehlertext (gekürzt auf die Feldlänge) und Datum/Uhrzeit des Fehlers speichern. Wird ein Angebot erfolgreich verarbeitet, SHALL das System Fehlertext und Fehlerzeitpunkt leeren. Die SellWatch-Übersicht SHALL Fehlertext und Fehlerzeitpunkt anzeigen und Angebote mit Fehlertext optisch hervorheben.

#### Scenario: Fehlertext wird gespeichert
- **WHEN** die Verarbeitung eines Angebots scheitert, weil in der Einkaufseinrichtung keine Standard-Artikelvorlage hinterlegt ist
- **THEN** enthält das Angebot als letzten Fehler die Fehlermeldung zur fehlenden Standard-Artikelvorlage sowie Datum und Uhrzeit des Laufs

#### Scenario: Fehler wird nach erfolgreicher Wiederholung geleert
- **WHEN** ein Angebot mit gespeichertem Fehler in einem späteren Lauf erfolgreich verarbeitet wird
- **THEN** sind Fehlertext und Fehlerzeitpunkt am Angebot leer und `"CXW Created" = true`

#### Scenario: Fehlerhafte Angebote sind in der Übersicht erkennbar
- **WHEN** ein Benutzer die SellWatch-Übersicht öffnet und ein Angebot einen gespeicherten Fehler hat
- **THEN** sieht er den Fehlertext und Fehlerzeitpunkt in der Zeile, und die Zeile ist als fehlerhaft hervorgehoben

### Requirement: Automatische Wiederholung fehlgeschlagener Angebote
Ein gescheitertes Angebot SHALL offen bleiben (`"CXW Created" = false`) und beim nächsten Lauf erneut verarbeitet werden, ohne dass ein Benutzer das Angebot zurücksetzen muss.

#### Scenario: Wiederholung nach Korrektur der Einrichtung
- **WHEN** ein Angebot wegen fehlender Kommissions-Artikelvorlage gescheitert ist, die Vorlage danach eingerichtet wird und die Verarbeitung erneut läuft
- **THEN** wird das Angebot verarbeitet und erhält Kreditor, Bestellung und Artikel

### Requirement: Fehlerfelder sind systemverwaltet
Fehlertext und Fehlerzeitpunkt SHALL ausschließlich von der SellWatch-Verarbeitung gesetzt werden. Sie SHALL NOT über die SellWatch-Inbound-API gelesen oder geschrieben werden können und SHALL in der SellWatch-Übersicht nicht bearbeitbar sein.

#### Scenario: API kann Fehlerfelder nicht setzen
- **WHEN** ein externes System per API ein Angebot anlegt oder ändert und dabei Werte für Fehlertext oder Fehlerzeitpunkt mitsendet
- **THEN** werden diese Werte nicht übernommen
