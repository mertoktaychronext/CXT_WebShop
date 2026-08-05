# Benutzerhandbuch – SL Chronext Webshop (Verkaufspreisverwaltung)

## Einleitung

Diese Erweiterung für Microsoft Dynamics 365 Business Central hilft dabei, neue Verkaufspreise für den Webshop einzulesen, zu prüfen und freizugeben, bevor sie verwendet werden. Sie importieren eine Preisliste (CSV-Datei), das System prüft automatisch Mindestmarge und ungewöhnliche Preisschwankungen, und ein Sachbearbeiter gibt die Preise anschließend frei.

## Voraussetzungen

- Zugang zu Business Central mit einer Rolle, die die Seite "Sales Price Checking List" bzw. "Verkaufspreisprüfungsliste" enthält.
- Die Grundeinstellungen (Mindestmarge, Schwellenwerte) müssen von einem Key User bereits hinterlegt sein (siehe Key-User-Handbuch).
- Für "Upload Sales Price" muss der Preisexport von einem Key User aktiviert und eine API-Schnittstelle hinterlegt sein (siehe Key-User-Handbuch).
- Eine vorbereitete CSV-Datei mit den neuen Preisen.

## Erste Schritte

### Die Preisprüfungsliste öffnen

Öffnen Sie in Business Central die Seite **"Sales Price Checking List"**. Beim Öffnen wird die Liste automatisch geleert – es werden immer nur die Preise angezeigt, die Sie im aktuellen Durchlauf importiert haben.

Über die Navigations-Schaltflächen am oberen Seitenrand erreichen Sie außerdem direkt:
- **"General Sales Price Setup"** – die Grundeinstellungen (siehe Key-User-Handbuch)
- **"Sales Price Archive"** – das Archiv bereits verarbeiteter Preise

## Hauptfunktionen

### 1. CSV-Datei importieren

Klicken Sie auf **"Import CSV"**. Wählen Sie die vorbereitete Datei aus. Die erste Zeile der Datei (Spaltenüberschriften) wird automatisch übersprungen. Die Datei muss folgende Spalten in dieser Reihenfolge enthalten: Artikelnummer, Variantencode, Verkaufspreis, Streichpreis, empfohlener Verkaufspreis, **Währungscode**, Grundcode, Kommentar.

> Hinweis: Der Import ist nur möglich, wenn die Liste leer ist. Falls bereits Preiszeilen vorhanden sind, löschen Sie diese zunächst über einen neuen Aufruf der Seite (die Liste leert sich beim Öffnen automatisch).

### 2. Preise prüfen ("Validate")

Klicken Sie auf **"Validate"**, nachdem der Import abgeschlossen ist. Das System:
- rundet die importierten Preise kaufmännisch,
- vergleicht jeden neuen Preis mit dem zuletzt aktiven Preis und markiert auffällige Preissprünge oder eine zu geringe Marge als Bemerkung.

Preiszeilen mit einer Bemerkung sollten Sie vor der Freigabe genauer prüfen.

### 3. Preise freigeben ("Approve")

Klicken Sie auf **"Approve"**, um die geprüften Preise freizugeben. Sie werden zur Bestätigung aufgefordert. Nach der Freigabe wird automatisch vermerkt, welcher Benutzer die Freigabe erteilt hat.

> Freigegebene Preise können nicht mehr nachträglich geändert werden.

### 4. Preise für alle Fremdwährungen anlegen ("Add all Currencies")

Wenn Sie einen Basispreis importiert, geprüft und freigegeben haben, können Sie mit **"Add all Currencies"** automatisch je aktivierter Fremdwährung eine umgerechnete Preiszeile erzeugen lassen. Das System berücksichtigt dabei alle Währungen, die von einem Key User dafür freigeschaltet wurden (siehe Key-User-Handbuch), und legt **eine** Preiszeile je Währung an.

### 5. Preise hochladen ("Upload Sales Price")

Klicken Sie auf **"Upload Sales Price"**, um alle freigegebenen Preiszeilen an das externe System (z. B. den Webshop) zu übertragen. Dabei passiert automatisch Folgendes für jede Zeile:

1. Der Preis wird in die produktive Verkaufspreis-Tabelle übernommen (neu angelegt oder aktualisiert) – gültig für **alle Kunden**.
2. Eine Kopie des Preises wird zusätzlich im **Preisarchiv** abgelegt, mit einer fortlaufenden Versionsnummer je Artikel/Variante/Währung.
3. Der Preis wird über die konfigurierte Schnittstelle an das externe System gesendet.

Am Ende erhalten Sie eine Meldung, wie viele der freigegebenen Zeilen erfolgreich übertragen wurden. Zeilen, die bereits einmal erfolgreich übertragen wurden ("Export Status" = "Sent"), werden beim erneuten Klicken **nicht** automatisch nochmals gesendet – Sie werden vorher gefragt, ob diese wirklich erneut übertragen werden sollen.

> Schlägt die Übertragung für eine einzelne Zeile fehl (z. B. wegen eines ungültigen Werts), wird nur diese Zeile mit "Export Status" = "Error" markiert; alle anderen Zeilen werden trotzdem weiterverarbeitet.

### 6. Archiv einsehen

Über die Seite **"Sales Price Archive"** können Sie bereits hochgeladene Preise nachträglich einsehen (nur lesend, keine Änderungen möglich). Jede Version einer hochgeladenen Preiszeile ist hier als eigener, fortlaufend nummerierter Eintrag zu finden.

## Häufige Fragen (FAQ)

**"Nothing to process" beim Klick auf Validate/Approve/Add all Currencies**
Es gibt keine passenden Preiszeilen für diesen Schritt – prüfen Sie, ob der vorherige Schritt (Import bzw. Validate) tatsächlich abgeschlossen wurde.

**"Please click Validate button"**
Sie haben versucht, eine Preiszeile direkt freizugeben, ohne vorher "Validate" auszuführen. Führen Sie zuerst "Validate" aus.

**"not possible" beim Ändern einer Preiszeile**
Eine bereits akzeptierte/freigegebene Preiszeile kann nicht mehr nachträglich geändert werden.

**"Nothing to process" beim Klick auf "Upload Sales Price"**
Es gibt keine freigegebenen (akzeptierten) Preiszeilen. Führen Sie zuerst "Approve" aus.

**Meldung, dass die Schnittstelle nicht aktiv ist oder keine API-Schnittstelle hinterlegt ist**
Der Preisexport ist nicht eingerichtet oder deaktiviert. Wenden Sie sich an einen Key User (siehe Key-User-Handbuch).

## Hilfe & Support

[TODO: Kontaktdaten des internen Supports / Key Users ergänzen]
