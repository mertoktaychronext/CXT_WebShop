# Benutzerhandbuch – CHX.Webshop

## Einleitung

Diese Erweiterung für Microsoft Dynamics 365 Business Central deckt vier weitgehend unabhängige Abläufe ab:

1. **Verkaufspreisverwaltung** (dieses Kapitel): Sie importieren eine Preisliste (CSV-Datei), das System prüft automatisch Mindestmarge und ungewöhnliche Preisschwankungen, und ein Sachbearbeiter gibt die Preise anschließend frei, bevor sie an den Webshop übertragen werden.
2. **SellWatch-Ankaufsanfragen** (siehe [entsprechendes Kapitel](#sellwatch-ankaufsanfragen-einsehen) unten): Eine schreibgeschützte Übersicht über Ankaufsanfragen für gebrauchte Uhren, die über den Partner SellWatch eingehen.
3. **Workshop-Ankaufsprüfung** (siehe [entsprechendes Kapitel](#uhren-zur-echtheitsprüfung-an-die-werkstatt-senden) unten): Angekommene, angekaufte Uhren werden vor der Einlagerung von einer externen Werkstatt auf Echtheit geprüft. Sie erfassen dafür pro Bestellzeile die Herstellerseriennummer; die Prüfung selbst läuft automatisiert.
4. **Kommissionsverkauf** (siehe [entsprechendes Kapitel](#kommissionsverkauf-verzögerte-einkaufsrechnung) unten): Für auf Kommission angekaufte Uhren wird die Einkaufsrechnung nach dem Verkauf zeitverzögert und vollautomatisch gebucht. Als Endnutzer ist hier keine Aktion nötig.

## Voraussetzungen

- Zugang zu Business Central mit einer Rolle, die die Seite "Sales Price Checking List" bzw. "Verkaufspreisprüfungsliste" enthält (Berechtigungssatz `SLChronWSAll`) bzw. die Seite "SellWatch-Overview" (Berechtigungssatz `CXW SWChronWSAll`).
- Die Grundeinstellungen (Mindestmarge, Schwellenwerte) müssen von einem Key User bereits hinterlegt sein (siehe Key-User-Handbuch).
- Für "Release Sales Prices" muss der Preisexport von einem Key User aktiviert, eine API-Schnittstelle und das Archivland hinterlegt sowie der Verkaufspreisexport-Job in der Aufgabenwarteschlange eingerichtet sein (siehe Key-User-Handbuch).
- Eine vorbereitete CSV-Datei mit den neuen Preisen.

## Erste Schritte

### Die Preisprüfungsliste öffnen

Öffnen Sie in Business Central die Seite **"Sales Price Checking List"**. Beim Öffnen wird die Liste automatisch geleert – es werden immer nur die Preise angezeigt, die Sie im aktuellen Durchlauf importiert haben.

Über die Navigations-Schaltflächen am oberen Seitenrand erreichen Sie außerdem direkt:
- **"General Sales Price Setup"** – die Grundeinstellungen (siehe Key-User-Handbuch)
- **"Sales Price Archive"** – das Archiv der freigegebenen DE-Preise
- **"Sales Price Export Entries"** – die freigegebenen Preise aller Länder und der Stand ihrer Übertragung

## Hauptfunktionen

### 1. CSV-Datei importieren

Klicken Sie auf **"Import CSV"**. Wählen Sie die vorbereitete Datei aus. Die erste Zeile der Datei (Spaltenüberschriften) wird automatisch übersprungen. Die Datei muss folgende Spalten in dieser Reihenfolge enthalten: Artikelnummer, Verkaufspreis, Streichpreis, empfohlener Verkaufspreis, **Währungscode**, Grundcode, Kommentar.

> Hinweis: Es werden keine Artikelvarianten mehr unterstützt – ein Preis gilt immer für den gesamten Artikel. Die frühere Variantencode-Spalte entfällt.

> Hinweis: Der Import ist nur möglich, wenn die Liste leer ist. Falls bereits Preiszeilen vorhanden sind, löschen Sie diese zunächst über einen neuen Aufruf der Seite (die Liste leert sich beim Öffnen automatisch).

### 2. Preise prüfen ("Validate")

Klicken Sie auf **"Validate"**, nachdem der Import abgeschlossen ist. Das System:
- rundet die importierten Preise kaufmännisch,
- vergleicht jeden neuen Preis mit dem zuletzt aktiven Preis und markiert auffällige Preissprünge oder eine zu geringe Marge als Bemerkung.

Preiszeilen mit einer Bemerkung sollten Sie vor der Freigabe genauer prüfen.

### 3. Preise freigeben ("Approve")

Klicken Sie auf **"Approve"**, um die geprüften Preise freizugeben. Sie werden zur Bestätigung aufgefordert. Nach der Freigabe wird automatisch vermerkt, welcher Benutzer die Freigabe erteilt hat.

> Freigegebene Preise können nicht mehr nachträglich geändert werden.

### 4. Preise für alle Länder anlegen ("Add all Countries")

Wenn Sie einen Basispreis importiert, geprüft und freigegeben haben, können Sie mit **"Add all Countries"** automatisch je aktiviertem Land eine Preiszeile erzeugen lassen. Das System berücksichtigt dabei alle Länder, die von einem Key User dafür freigeschaltet wurden (siehe Key-User-Handbuch), und legt **eine** Preiszeile je Land an – in der für das Land hinterlegten Währung. Hat das Land dieselbe Währung wie der Basispreis, wird der Preis unverändert übernommen, sonst mit dem aktuellen Wechselkurs umgerechnet. Die Spalte **"Country Code"** zeigt, für welches Land eine Zeile gilt; die importierte Basiszeile hat kein Land.

### 5. Preise freigeben und zur Übertragung einplanen ("Release Sales Prices")

Klicken Sie auf **"Release Sales Prices"**, um alle freigegebenen **Länderzeilen** zur Übertragung an das externe System (z. B. den Webshop) einzuplanen. Dabei passiert automatisch Folgendes für jede Zeile:

1. Der Preis wird in die produktive Verkaufspreis-Tabelle übernommen (neu angelegt oder aktualisiert) – gültig für **alle Kunden**.
2. Nur für das Archivland (standardmäßig **DE**) wird zusätzlich eine Kopie im **Preisarchiv** abgelegt, mit einer fortlaufenden Versionsnummer.
3. Der Preis des Landes wird als **Verkaufspreisexport-Posten** gespeichert und zur Übertragung eingeplant. Die Zeile erhält "Export Status" = "Queued".

Die eigentliche Übertragung erfolgt **zeitversetzt im Hintergrund** durch einen Job in der Aufgabenwarteschlange. Sie müssen dafür nichts weiter tun.

> Die importierte Basiszeile ohne Land wird **nicht** freigegeben und nicht übertragen. Führen Sie deshalb vor der Freigabe immer "Add all Countries" aus. Sind nur Basiszeilen freigegeben, bricht die Aktion mit einem entsprechenden Hinweis ab.

Am Ende erhalten Sie eine Meldung, wie viele Preise zur Übertragung eingeplant wurden. Zeilen, die bereits eingeplant wurden ("Export Status" = "Queued"), werden beim erneuten Klicken **nicht** automatisch nochmals freigegeben – Sie werden vorher gefragt, ob dies wirklich geschehen soll.

> Schlägt die Freigabe für eine einzelne Zeile fehl (z. B. wegen eines ungültigen Werts), wird nur diese Zeile mit "Export Status" = "Error" markiert und nicht eingeplant; alle anderen Zeilen werden trotzdem weiterverarbeitet.

### 6. Übertragung und Archiv einsehen

Über die Seite **"Sales Price Export Entries"** sehen Sie jeden freigegebenen Preis je Land, wer ihn wann freigegeben hat und in der Spalte **"Export Status"**, ob er bereits übertragen wurde ("Processed"), noch aussteht ("Pending (Sales Price)") oder fehlgeschlagen ist ("Error"). Fehlgeschlagene Übertragungen werden automatisch erneut versucht; bleibt ein Eintrag dauerhaft auf "Error", wenden Sie sich an einen Key User.

Über die Seite **"Sales Price Archive"** können Sie die freigegebenen DE-Preise nachträglich einsehen (nur lesend). Jede Version ist hier als eigener, fortlaufend nummerierter Eintrag zu finden. Preise anderer Länder finden Sie nur in den "Sales Price Export Entries".

## SellWatch-Ankaufsanfragen einsehen

Die Seite **"SellWatch-Overview"** zeigt alle über den Partner SellWatch eingegangenen Ankaufsanfragen für gebrauchte Uhren – schreibgeschützt, mit Verkäufer-, Uhren- und Angebotsdaten sowie, sobald vorhanden, der zugehörigen Bestellnummer und Sendungsnummer (Tracking-Nummer).

Über die Aktion **"Show Document"** öffnen Sie die zur Anfrage gehörende Einkaufsbestellung.

> Neue Ankaufsanfragen sowie die Anlage von Lieferant und Bestellung erfolgen automatisiert im Hintergrund; diese Seite dient ausschließlich der Ansicht. Fehlt zu einer Anfrage die Bestellnummer, wurde die Bestellung für diese Anfrage noch nicht automatisiert angelegt.

## Uhren zur Echtheitsprüfung an die Werkstatt senden

Für angekaufte Uhren, die vor der Einlagerung von einer externen Werkstatt auf Echtheit geprüft werden müssen, erfassen Sie auf der Einkaufsbestellung, welche Zeilen angekommen sind.

### Die Aktion "Send to Workshop" ausführen

Öffnen Sie die betreffende **Einkaufsbestellung** und klicken Sie auf **"Send to Workshop"**. Das System fragt Sie für jede noch nicht übertragene Zeile (Typ Artikel, Menge ungleich 0) einzeln:

1. **"Ist Artikel {Artikelnummer} {Beschreibung} wirklich angekommen?"** – Bestätigen Sie mit "Ja", wenn der Artikel physisch eingetroffen ist. Bei "Nein" wird die Zeile als "Nicht angekommen" markiert und übersprungen; Sie können die Aktion später erneut ausführen, sobald der Artikel angekommen ist.
2. Bei "Ja" öffnet sich die **Seriennr.-Informationskarte** der Uhr. Hat die Bestellzeile noch keine Seriennummer, vergibt das System automatisch die nächste freie Nummer und zeigt sie auf der Karte an. Tragen Sie dort die **Herstellerseriennummer** ein und – falls für den Artikel verlangt – die Angaben zu **Box** und **Papieren**, und schließen Sie die Karte.
3. Fehlt danach die Herstellerseriennummer oder eine verlangte Angabe, wird die Zeile übersprungen und am Ende der Aktion in einer Sammelmeldung mit Grund aufgeführt, während die übrigen Zeilen normal weiterverarbeitet werden. Beim nächsten Ausführen erscheint wieder dieselbe Seriennummer.

> Zeilen mit einer Menge größer 1 oder Artikel ohne Seriennummernverfolgung können nicht an die Werkstatt gesendet werden; sie erscheinen ebenfalls in der Sammelmeldung. Wenden Sie sich in diesem Fall an einen Key User.

Nach erfolgreicher Eingabe wird die Zeile als "An Werkstatt gesendet" markiert und ist auf der Bestellzeile **nicht mehr editierbar** (Artikel, Menge etc.) – so wird verhindert, dass eine bereits an die Werkstatt übergebene Zeile nachträglich verändert wird, während die Prüfung noch läuft. Nur der **EK-Preis** bleibt jederzeit änderbar; eine spätere Preisänderung wird allerdings nicht an die Werkstatt übermittelt.

> Eine bereits gesendete Zeile lässt sich über diese Aktion kein zweites Mal übertragen.

Gibt es für die Bestellung bereits Werkstattzeilen, weist das System Sie beim erneuten Ausführen von "Send to Workshop" darauf hin:

- Sind alle Zeilen bereits gesendet, erscheint die Meldung, dass keine weiteren Zeilen an die Werkstatt zu senden sind – es wird nichts verarbeitet.
- Gibt es noch offene Zeilen (z. B. zuvor als "Nicht angekommen" markiert), fragt das System mit Angabe der Anzahl vorhandener Werkstattzeilen, ob die übrigen Zeilen gesendet werden sollen. Bei "Nein" wird abgebrochen.

### Was danach automatisch passiert

Die eigentliche Prüfung durch die Werkstatt sowie die Weiterverarbeitung nach dem Prüfergebnis laufen vollautomatisiert im Hintergrund – dafür ist keine weitere Aktion Ihrerseits nötig:

- Bestätigt die Werkstatt die Echtheit, wird für die Bestellzeile automatisch **nur der Wareneingang** gebucht (keine Rechnung), und die von der Werkstatt gemeldeten Artikelmerkmale (z. B. Zifferblattfarbe, Gehäusedurchmesser, Armbandmaterial) werden als Artikelattribute auf den Artikel übernommen.
- Widerlegt die Werkstatt die Echtheit, wird die zugehörige Einkaufsbestellung automatisch storniert.

## Workshop-Zeilen einsehen

Über die Seite **"CXW Workshop Lines"** sehen Sie alle an die Werkstatt übergebenen Zeilen mit ihrem aktuellen Prüfstatus (Neu / WS geprüft / Verarbeitet / Fehler), den von der Werkstatt gemeldeten Artikelmerkmalen sowie – falls die automatische Verarbeitung fehlgeschlagen ist – dem zuletzt aufgetretenen Fehlertext. Status und Merkmale können Sie dort korrigieren; Bestellbezug und Artikelnummer sind gesperrt, Zeilen lassen sich weder anlegen noch löschen.

Direkt aus der **Einkaufsbestellung** zeigt das Feld **"Anzahl Werkstattzeilen"** (Inforegister "Allgemein"), wie viele Werkstattzeilen es für diese Bestellung gibt; leer bedeutet keine. Ein Klick auf den Wert öffnet die Workshop-Zeilen gefiltert auf diese Bestellung.

> Steht eine Zeile auf Status "Fehler", ist bei der letzten automatischen Verarbeitung ein Problem aufgetreten (z. B. eine gesperrte Buchungsperiode). Wenden Sie sich in diesem Fall an einen Key User bzw. das Entwicklungsteam (siehe Key-User-Handbuch).

## Kommissionsverkauf: Verzögerte Einkaufsrechnung

Für Uhren, die auf Kommission angekauft wurden (Artikel-Kennzeichen "Kommissionsverkauf"), wird die zugehörige **Einkaufsrechnung nicht sofort** beim Verkauf gebucht, sondern zeitverzögert und automatisch – eine festgelegte Anzahl Tage nach der Buchung der Verkaufsrechnung.

Dieser Ablauf ist **vollständig automatisiert**: Sobald Sie eine Verkaufsrechnung für eine Kommissionsuhr buchen, entsteht im Hintergrund ein Kommissions-Buchungseintrag; eine Hintergrundverarbeitung bucht die Einkaufsrechnung anschließend zum Fälligkeitsdatum. Als Endnutzer müssen Sie hierfür nichts tun.

> Die Einrichtung der Verzögerung, die Überwachung der Einträge und die Nachbearbeitung fehlgeschlagener Fälle (Seite "CXW Cons. Posting Entries", Aktion "Retry") übernimmt ein Key User – siehe Key-User-Handbuch.

## Häufige Fragen (FAQ)

**"Nothing to process" beim Klick auf Validate/Approve/Add all Countries**
Es gibt keine passenden Preiszeilen für diesen Schritt – prüfen Sie, ob der vorherige Schritt (Import bzw. Validate) tatsächlich abgeschlossen wurde.

**"Please click Validate button"**
Sie haben versucht, eine Preiszeile direkt freizugeben, ohne vorher "Validate" auszuführen. Führen Sie zuerst "Validate" aus.

**"not possible" beim Ändern einer Preiszeile**
Eine bereits akzeptierte/freigegebene Preiszeile kann nicht mehr nachträglich geändert werden.

**"Nothing to process" beim Klick auf "Release Sales Prices"**
Es gibt keine freigegebenen (akzeptierten) Preiszeilen. Führen Sie zuerst "Approve" aus.

**"Only source lines without a country are approved" beim Klick auf "Release Sales Prices"**
Es sind nur Basiszeilen ohne Land freigegeben. Führen Sie zuerst "Add all Countries" aus.

**Ein Preis steht in "Sales Price Export Entries" lange auf "Pending (Sales Price)"**
Die Übertragung läuft über einen Job in der Aufgabenwarteschlange. Steht der Eintrag länger als üblich auf ausstehend, ist der Job möglicherweise nicht eingerichtet oder angehalten – wenden Sie sich an einen Key User.

**Meldung, dass die Schnittstelle nicht aktiv ist oder keine API-Schnittstelle hinterlegt ist**
Der Preisexport ist nicht eingerichtet oder deaktiviert. Wenden Sie sich an einen Key User (siehe Key-User-Handbuch).

**Eine SellWatch-Anfrage zeigt keine Bestellnummer.**
Die Bestellung wurde für diese Anfrage noch nicht automatisiert angelegt.

**"Send to Workshop" öffnet die Seriennr.-Informationskarte, obwohl ich abbrechen wollte.**
Die Karte ist für angekommene Artikel verpflichtend. Schließen Sie sie ohne Herstellerseriennummer, wird die Zeile übersprungen (die vergebene Seriennummer bleibt für den nächsten Versuch erhalten). Wählen Sie im vorherigen Bestätigungsdialog "Nein", wenn der Artikel tatsächlich noch nicht angekommen ist – die Zeile wird dann übersprungen, ohne die restliche Aktion abzubrechen.

**Eine Workshop-Zeile bleibt dauerhaft auf Status "Fehler" stehen.**
Die automatische Verarbeitung ist bei dieser Zeile fehlgeschlagen. Das ist keine Aktion, die Sie als Endnutzer selbst beheben können – wenden Sie sich an einen Key User (siehe Key-User-Handbuch).