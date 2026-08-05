# Benutzerhandbuch – SL Chronext Webshop (Verkaufspreisverwaltung)

## Einleitung

Diese Erweiterung für Microsoft Dynamics 365 Business Central hilft dabei, neue Verkaufspreise für den Webshop einzulesen, zu prüfen und freizugeben, bevor sie verwendet werden. Sie importieren eine Preisliste (CSV-Datei), das System prüft automatisch Mindestmarge und ungewöhnliche Preisschwankungen, und ein Sachbearbeiter gibt die Preise anschließend frei.

## Voraussetzungen

- Zugang zu Business Central mit einer Rolle, die die Seite "Sales Price Checking List" bzw. "Verkaufspreisprüfungsliste" enthält.
- Die Grundeinstellungen (Mindestmarge, Schwellenwerte) müssen von einem Key User bereits hinterlegt sein (siehe Key-User-Handbuch).
- Eine vorbereitete CSV-Datei mit den neuen Preisen.

## Erste Schritte

### Die Preisprüfungsliste öffnen

Öffnen Sie in Business Central die Seite **"Sales Price Checking List"**. Beim Öffnen wird die Liste automatisch geleert – es werden immer nur die Preise angezeigt, die Sie im aktuellen Durchlauf importiert haben.

## Hauptfunktionen

### 1. CSV-Datei importieren

Klicken Sie auf **"Import CSV"**. Wählen Sie die vorbereitete Datei aus. Die erste Zeile der Datei (Spaltenüberschriften) wird automatisch übersprungen. Die Datei muss folgende Spalten in dieser Reihenfolge enthalten: Artikelnummer, Variantencode, Verkaufspreis, Streichpreis, empfohlener Verkaufspreis, Ländercode, Grundcode, Kommentar.

> Hinweis: Der Import ist nur möglich, wenn die Liste leer ist. Falls bereits Preiszeilen vorhanden sind, löschen Sie diese zunächst über einen neuen Aufruf der Seite (die Liste leert sich beim Öffnen automatisch).

### 2. Preise prüfen ("Validate")

Klicken Sie auf **"Validate"**, nachdem der Import abgeschlossen ist. Das System:
- rundet die importierten Preise kaufmännisch,
- ergänzt automatisch den passenden Währungscode zum jeweiligen Land,
- vergleicht jeden neuen Preis mit dem zuletzt aktiven Preis und markiert auffällige Preissprünge oder eine zu geringe Marge als Bemerkung.

Preiszeilen mit einer Bemerkung sollten Sie vor der Freigabe genauer prüfen.

### 3. Preise freigeben ("Approve")

Klicken Sie auf **"Approve"**, um die geprüften Preise freizugeben. Sie werden zur Bestätigung aufgefordert. Nach der Freigabe wird automatisch vermerkt, welcher Benutzer die Freigabe erteilt hat.

> Freigegebene Preise können nicht mehr nachträglich geändert werden.

### 4. Preise für alle Fremdwährungen anlegen ("Add all Currencies")

Wenn Sie einen deutschen Preis (Grundpreis) importiert, geprüft und freigegeben haben, können Sie mit **"Add all Currencies"** automatisch je genutzter Fremdwährung eine umgerechnete Preiszeile erzeugen lassen. Das System berücksichtigt dabei alle Länder, für die im System eine Verkaufspreis-Aktivierung hinterlegt ist, und legt **eine** Preiszeile je Währung an – auch wenn mehrere Länder dieselbe Währung nutzen.

Diese Aktion ist nur verfügbar, solange Sie sich im Modus "deutscher Preis" befinden (siehe Feld "Non DE Price" weiter unten).

### 5. Feld "Non DE Price"

Mit diesem Schalter legen Sie fest, ob Sie gerade mit deutschen oder mit internationalen (Nicht-DE-)Preisen arbeiten. Ein Umschalten ist nur möglich, wenn die Liste leer ist.

### 6. Archiv einsehen

Über die Seite **"Sales Price Archive"** können Sie bereits verarbeitete Preise nachträglich einsehen (nur lesend, keine Änderungen möglich).

## Häufige Fragen (FAQ)

**"Nothing to process" beim Klick auf Validate/Approve/Add all Currencies**
Es gibt keine passenden Preiszeilen für diesen Schritt – prüfen Sie, ob der vorherige Schritt (Import bzw. Validate) tatsächlich abgeschlossen wurde.

**"DE price not allowed" / "Non DE price not allowed"**
Sie versuchen, deutsche und internationale Preise gleichzeitig in der Liste zu haben. Leeren Sie die Liste (Seite neu öffnen) und starten Sie mit dem richtigen Modus ("Non DE Price"-Schalter) neu.

**"Please click Validate button"**
Sie haben versucht, eine Preiszeile direkt freizugeben, ohne vorher "Validate" auszuführen. Führen Sie zuerst "Validate" aus.

**Warum ist der Ländercode bei einigen Zeilen leer?**
Zeilen, die über "Add all Currencies" erzeugt wurden, gelten für **alle** Länder mit der jeweiligen Währung, nicht für ein einzelnes Land – daher bleibt der Ländercode dort bewusst leer.

## Hilfe & Support

[TODO: Kontaktdaten des internen Supports / Key Users ergänzen]
