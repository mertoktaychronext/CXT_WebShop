# Key-User-Handbuch – SL Chronext Webshop (Verkaufspreisverwaltung, SellWatch, Workshop-Ankaufsprüfung & Kommissionsverkauf)

## Über dieses Dokument

Dieses Handbuch richtet sich an Key User, die die Grundeinstellungen der Verkaufspreisverwaltung pflegen, Länder und Währungen für die Preiserzeugung freischalten, die externe Schnittstelle für den SellWatch-Online-Check konfigurieren, die Werkstatt-Anbindung für die Echtheitsprüfung einrichten, die verzögerte EK-Faktura für Kommissionsverkäufe einrichten und bei Problemen die erste Anlaufstelle für die Fachabteilung sind. Das Handbuch deckt vier fachlich unabhängige Teile der Erweiterung ab: die Verkaufspreisverwaltung, SellWatch (Ankaufsanfragen für gebrauchte Uhren), die Workshop-Ankaufsprüfung (externe Echtheitsprüfung angekaufter Uhren) und den Kommissionsverkauf (verzögerte, automatische EK-Faktura für auf Kommission verkaufte Uhren).

## Grundeinstellungen (General Sales Price Setup)

Über die Seite **"General Sales Price Setup"** werden die Regeln hinterlegt, gegen die jeder importierte Preis geprüft wird:

| Einstellung | Bedeutung |
|---|---|
| Mindestmarge % | Preise mit einer geringeren Marge werden bei "Validate" mit einer Bemerkung markiert (Achtung: In der Webshop-Anzeige selbst wird ein Artikel bei Unterschreitung der Marge deaktiviert – siehe ToolTip auf dem Feld). |
| Schwellenwert Lagerpreis % | Ab welcher prozentualen Preiserhöhung gegenüber dem letzten Preis eine Bemerkung erzeugt wird. |
| Schwellenwert Nicht-Lagerpreis % | Analog für Nicht-Lagerartikel (aktuell nicht aktiv genutzt, siehe Entwicklerhandbuch). |
| Kat. 1–3 Nicht-Lager % / Lagerpreis von/bis | Vorbereitet für eine automatische Berechnung des Nicht-Lagerpreises je Preiskategorie. Diese Berechnung ist im laufenden Freigabe-Ablauf aktuell nicht automatisch eingebunden. |
| Preisexport aktiv | Muss aktiviert sein, damit die Aktion "Upload Sales Price" (Benutzerhandbuch) Preise an ein externes System senden kann. |
| API-Schnittstellencode | Legt fest, welche der unter "API Interface Setup" hinterlegten Schnittstellen für den Preisexport verwendet wird. |

Diese Einstellungen **müssen** befüllt sein (Mindestmarge %, Schwellenwert Lagerpreis %), sonst lassen sich Import, Prüfung und Freigabe nicht ausführen. Für "Upload Sales Price" müssen zusätzlich "Preisexport aktiv" und "API-Schnittstellencode" gesetzt sein.

## Externe Schnittstelle einrichten (API Interface Setup)

Über die Navigation-Schaltfläche **"API Interface Setup"** auf der Seite "General Sales Price Setup" gelangen Sie zur Verwaltung der externen Schnittstellen, an die Preise gesendet werden können:

| Feld | Bedeutung |
|---|---|
| Code | Eindeutiger Code der Schnittstelle – wird im Feld "API-Schnittstellencode" der Grundeinstellungen ausgewählt. |
| Description | Freitext-Beschreibung der Schnittstelle. |
| Endpoint URL | Die Ziel-URL, an die die Preisdaten per HTTP gesendet werden. Pflichtfeld, sobald die Schnittstelle aktiviert wird. |
| HTTP Method | HTTP-Methode für den Aufruf: POST, PATCH, PUT, GET oder DELETE. Bei GET/DELETE wird kein Anfragekörper gesendet. |
| SOAP Action | Wert für den `SOAPAction`-Header. Leer lassen, um den Header wegzulassen. |
| Auth Type | Art der Authentifizierung: **Keine**, **API-Schlüssel (Header)**, **Basisauthentifizierung** oder **AWS Signature V4**. Je nach Auswahl blendet die Detailkarte die passenden Eingabefelder ein. |
| API Key | Der API-Schlüssel bzw. das Token für die Authentifizierung (bei "API-Schlüssel (Header)" / "Basisauthentifizierung"; bei "AWS Signature V4" optional als zusätzlicher `X-API-Key`-Header). Wird verschlüsselt im Isolated Storage gespeichert und nach dem Speichern nicht mehr im Klartext angezeigt. Pflichtfeld bei "API-Schlüssel (Header)" und "Basisauthentifizierung". |
| AWS Access Key ID / AWS Region / AWS Service | Nur bei Auth Type = "AWS Signature V4": Klartext-Angaben für die Anfragesignierung (Service typischerweise `execute-api` für API Gateway). |
| AWS Secret Access Key / AWS Session Token | Nur bei Auth Type = "AWS Signature V4": verschlüsselt im Isolated Storage gespeichert. Secret Access Key ist Pflicht, Session Token nur bei temporären/STS-Zugangsdaten. |
| Source Table No. | Die Tabelle, für die diese Schnittstelle Daten überträgt (für den Preisexport: die Tabellennummer von "Sales Price"). |
| Active | Muss gesetzt sein, damit die Schnittstelle in den Grundeinstellungen auswählbar ist. Beim Aktivieren prüft das System automatisch, dass Endpoint URL und – je nach Auth Type – API Key bzw. die AWS-Felder vollständig hinterlegt sind. |

> Ohne eine aktive, vollständig konfigurierte Schnittstelle schlägt "Upload Sales Price" fehl bzw. markiert betroffene Preiszeilen mit "Export Status" = "Error".

## Länder für "Add all Countries" freischalten

In den Stammdaten von **Land/Region** (Seite "Countries/Regions") wurden folgende Felder ergänzt:

| Feld | Bedeutung |
|---|---|
| Verkaufspreis aktiviert | Muss gesetzt sein, damit für dieses Land automatisch eine Preiszeile erzeugt wird, wenn "Add all Countries" ausgeführt wird. |
| Verkaufspreis-Währungscode | Währung, in der die Preiszeile für dieses Land erzeugt wird. Leer = Mandantenwährung (z. B. EUR). |

> Ohne "Verkaufspreis aktiviert" wird ein Land bei "Add all Countries" nicht berücksichtigt. Jedes aktivierte Land erhält eine eigene Zeile – auch wenn mehrere Länder dieselbe Währung nutzen (z. B. DE, AT, FR in EUR).

> **Umstellung von Währungs- auf Länderfreischaltung:** Bis zur Einführung von "Add all Countries" erfolgte die Freischaltung über das Feld "Verkaufspreis aktiviert" auf der **Währung** (Aktion "Add all Currencies"). Dieses Feld wurde entfernt. Notieren Sie vor dem Update die bisher aktivierten Währungen und richten Sie danach die entsprechenden Länder mit Verkaufspreis-Währungscode ein.
## Grundcode (Reason Code)

Jeder Preisänderung kann ein Grund zugeordnet werden: **CatMan**, **Einkauf** oder **Marketing**. Dies dient der Nachvollziehbarkeit, warum ein Preis geändert wurde, wird aber aktuell nicht weiter ausgewertet. Ohne explizite Auswahl wird "CatMan" als Standardwert verwendet.

## Workflows und Prozesse

Der reguläre Ablauf für die Fachabteilung ist: **Import → Validate → Approve → (optional) Add all Countries → Upload Sales Price**. Als Key User sind Sie zuständig für die Rahmenbedingungen (Grundeinstellungen, Länderfreischaltung, API-Schnittstelle), nicht für den täglichen Ablauf selbst (siehe Benutzerhandbuch).

Für SellWatch gibt es keinen von der Fachabteilung manuell ausgelösten Ablauf: Neue Ankaufsanfragen (Verkäufer-, Uhren- und Angebotsdaten) treffen automatisiert ein und werden automatisiert zu Lieferant und Einkaufsbestellung verarbeitet; die Fachabteilung sieht das Ergebnis nur lesend auf der Seite "SellWatch-Overview" (Benutzerhandbuch). Als Key User sind Sie hier zuständig für die Konfiguration der Online-Check-Schnittstelle (siehe unten) und für die Berechtigungsvergabe.

Bei der Workshop-Ankaufsprüfung löst die Fachabteilung selbst nur den ersten Schritt aus (Aktion "Send to Workshop" auf der Einkaufsbestellung, siehe Benutzerhandbuch); die eigentliche Prüfung durch die Werkstatt und die anschließende Wareneingangsbuchung bzw. Stornierung laufen automatisiert über die externe Workshop-API und einen Job-Queue-Eintrag. Als Key User richten Sie die OAuth2-Anbindung für die Werkstatt, den Job-Queue-Eintrag und die Artikelattribut-Zuordnung ein (siehe unten) und sind erste Anlaufstelle, wenn eine Workshop-Zeile dauerhaft im Status "Fehler" hängen bleibt.

Beim Kommissionsverkauf gibt es ebenfalls keinen von der Fachabteilung manuell ausgelösten Ablauf: Sobald eine VK-Rechnung für einen Kommissionsartikel gebucht wird, entsteht automatisch ein Kommissions-Buchungseintrag, und ein Job-Queue-Eintrag bucht die zugehörige EK-Faktura nach Ablauf der eingerichteten Verzögerung automatisch. Als Key User richten Sie die Verzögerung in Tagen und den Job-Queue-Eintrag ein (siehe unten) und sind erste Anlaufstelle, wenn ein Kommissions-Buchungseintrag dauerhaft im Status "Fehler" hängen bleibt.

## SellWatch – Online-Check-Schnittstelle einrichten (API Interface Setup)

Der SellWatch-Online-Check (prüft, ob eine Uhr im SellWatch-Onlineshop sichtbar sein sollte) nutzt dieselbe Seite **"API Interface Setup"** wie der Preisexport der Verkaufspreisverwaltung (siehe oben) – jedoch immer den festen Schnittstellen-Code **`WOA`**. Legen Sie dort einen Eintrag mit Code `WOA` an bzw. pflegen Sie ihn:

| Feld | Bedeutung für SellWatch |
|---|---|
| Code | Muss exakt `WOA` lauten – dieser Code ist im SellWatch-Code fest hinterlegt und nicht änderbar. |
| Endpoint URL | Basis-URL des SellWatch-Online-Check-Endpunkts. Die tatsächliche Anfrage wird an `<Endpoint URL>/<Artikelnummer>/<Variantencode>/check` gesendet. |
| API Key | Wird als HTTP-Header `X-API-KEY` mitgesendet, verschlüsselt gespeichert. |
| Active | Muss gesetzt sein, sonst führt der Online-Check keinen Aufruf durch. |

> Anders als beim Preisexport der Verkaufspreisverwaltung gibt es für den Online-Check kein Auswahlfeld für den Schnittstellencode in den Grundeinstellungen – der Code `WOA` ist im Code fest verdrahtet.

> Fehlgeschlagene Aufrufe können Sie über die Seite **"Http Call Log"** nachvollziehen: Sie zeigt zu jedem Aufruf Erfolg/Fehlschlag, HTTP-Statuscode und Fehlermeldung, und erlaubt den Download des gesendeten Requests sowie der empfangenen Antwort als Textdatei (der API-Schlüssel wird im gespeicherten Request nicht im Klartext angezeigt). Seit dem HTTP-Logging-Update vom 2026-08-10 protokolliert diese Seite auch die Aufrufe des Verkaufspreis-Exports (siehe unten) – die Spalte "Quelltabellennr." zeigt, welcher Bereich den Eintrag erzeugt hat.

> Seit Version 27.0.0.3 finden Sie jede übertragene Verkaufspreiszeile zusätzlich auf der Seite **"Data Export Entries"** (dieselbe Seite wie beim Verfügbarkeitsexport) – erkennbar am Zielcode `SALESPRICE`. Dort sehen Sie Status (Verarbeitet/Fehler), Dateiname, Fehlermeldung und im Infobereich die gesendeten JSON-Daten. **Wichtig:** Fehlgeschlagene Preisübertragungen wiederholen Sie ausschließlich über "Upload Sales Price" auf der Preisprüfliste, **nicht** über die Aktion "Export Data" auf "Data Export Entries" – diese kann Preiseinträge nicht senden und erzeugt nur einen Fehlerprotokolleintrag.

## Workshop-Ankaufsprüfung einrichten

Die Werkstatt prüft angekaufte Uhren extern auf Echtheit und liefert das Ergebnis über eine eigene, bidirektionale API zurück. Nach der Erstinstallation der Erweiterung sind drei Schritte einmalig einzurichten:

### 1. OAuth2 S2S (Entra) für die Workshop-API

Die Custom API (Endpunkt-Muster `.../api/saliniLife/workshop/v1.0/companies({companyId})/workshopLines`) verwendet die Standard-BC-API-Authentifizierung, keine eigene Auth-Logik:

1. In Microsoft Entra ID eine App-Registrierung für den Workshop-Dienst anlegen (Client Credentials Flow, kein interaktiver Login).
2. Der App-Registrierung Zugriff auf die Business-Central-API erteilen (Business Central Admin Center → API-Zugriff, bzw. Azure-AD-App-Berechtigung "Dynamics 365 Business Central").
3. In Business Central einen dedizierten Benutzer für den Workshop-Dienst anlegen und ihm **ausschließlich** das Permission Set **"CXW Workshop API"** zuweisen (kein Zugriff auf Purchase Line, Item oder andere Tabellen).
4. Client-ID, Client-Secret und Tenant-ID an den Workshop-Dienstbetreiber übergeben.

### 2. Job-Queue-Eintrag für die Verarbeitung anlegen

Codeunit **"CXW Process Workshop Lines"** verarbeitet alle Workshop-Zeilen im Status "WS geprüft" (Wareneingang buchen bzw. Bestellung stornieren):

1. Job-Queue-Einträge → Neu.
2. Objekttyp: Codeunit, Objekt: "CXW Process Workshop Lines".
3. Empfohlene Wiederholung: alle 5 Minuten.
4. Der ausführende Benutzer benötigt das Permission Set **"CXW Workshop All"** sowie die Standard-Einkaufs-/Lager-Berechtigungen für die Wareneingangsbuchung und Item-Attribute-Pflege.

### 3. Artikelattribute – fachliche Bedeutung der Attributfelder

Die Werkstatt meldet je Uhr bis zu zehn Attribute zurück. Acht davon sind fachlich benannt und werden bei bestätigter Echtheit automatisch als Standard-Artikelattribut auf den Artikel übernommen:

| Attribut-Nr. | Bedeutung |
|---|---|
| 1 | Zifferblattfarbe (Dial Color) |
| 2 | Gehäusedurchmesser (Case Diameter) |
| 3 | Armbandmaterial (Bracelet Material) |
| 4 | Gehäusematerial (Case Material) |
| 5 | Werk (Movement) |
| 6 | Geschlecht (Gender) |
| 7 | Glas (Crystal) |
| 8 | Ausstattung (Features) |
| 9–10 | Noch ohne fachliche Bezeichnung (Platzhalter) |

> Fehlende Standard-Artikelattribute legt das System bei Bedarf automatisch an (Typ Text) – keine manuelle Voreinrichtung nötig.

## Status und Fehlerbehandlung der Workshop-Zeilen

Eine Workshop-Zeile durchläuft die Status **Neu → WS geprüft → Verarbeitet**. Schlägt die automatische Verarbeitung fehl (z. B. gesperrte Buchungsperiode, fehlende Lagerortangabe), wechselt die Zeile stattdessen auf Status **Fehler**, und der Fehlertext wird im Feld "Last Error" auf der Zeile vermerkt (sichtbar auf Seite "CXW Workshop Lines").

**Eine fehlerhafte Zeile manuell erneut anstoßen:** Setzen Sie den Status der betroffenen Zeile manuell zurück auf "WS geprüft" (z. B. über das Table-Testfenster oder eine geeignete Seite mit Bearbeitungsrecht), nachdem die Ursache behoben ist (z. B. Buchungsperiode geöffnet). Beim nächsten Job-Queue-Lauf wird die Zeile automatisch erneut verarbeitet; bei Erfolg wird "Last Error" automatisch geleert.

> Ein direkter Wechsel auf Status "Fehler" von einem anderen Status als "WS geprüft" aus (z. B. versehentlich über die API) wird vom System mit einer Fehlermeldung abgelehnt – dieser Status wird ausschließlich von der automatischen Verarbeitung selbst gesetzt.

## Kommissionsverkauf einrichten

Wird ein als Kommissionsware markierter Artikel per Verkaufsrechnung verkauft, soll die zugehörige Einkaufsrechnung nicht sofort, sondern erst nach einer festgelegten Anzahl Tage automatisch gebucht werden. Nach der Erstinstallation der Erweiterung sind zwei Schritte einmalig einzurichten:

### 1. Verzögerung in Tagen festlegen

Auf der Seite **"Purchases & Payables Setup"** (Einkaufseinrichtung) finden Sie im Bereich "SellWatch" das Feld:

| Feld | Bedeutung |
|---|---|
| Consignment Invoice Delay (Days) | Anzahl Tage zwischen der Buchung der Verkaufsrechnung und der automatischen Buchung der zugehörigen Einkaufsrechnung. 0 bedeutet: am nächsten Lauf der Hintergrundverarbeitung, ohne zusätzliche Wartezeit. |

> Ist das Feld leer (0), wird die EK-Faktura beim nächsten Lauf der Hintergrundverarbeitung ohne Verzögerung gebucht.

### 2. Job-Queue-Eintrag für die Verarbeitung anlegen

Codeunit **"CXW Post Consignment Purchases"** bucht alle fälligen Kommissions-Buchungseinträge (Status "Offen", Fälligkeitsdatum erreicht) automatisch als Einkaufsrechnung:

1. Job-Queue-Einträge → Neu.
2. Objekttyp: Codeunit, Objekt: "CXW Post Consignment Purchases".
3. Empfohlene Wiederholung: täglich.
4. Der ausführende Benutzer benötigt das Permission Set **"CXW Workshop All"** (deckt seit dieser Version auch den Kommissionsverkauf ab) sowie die Standard-Einkaufs-Berechtigungen für die Rechnungsbuchung.

## Status und Fehlerbehandlung der Kommissions-Buchungseinträge

Auf der Seite **"CXW Cons. Posting Entries"** sehen Sie alle Kommissions-Buchungseinträge mit Artikel, ermittelter Einkaufsbestellung, auslösender Verkaufsrechnung, Fälligkeitsdatum, Status und – im Fehlerfall – Fehlertext. Ein Eintrag durchläuft die Status **Offen → Gebucht** bzw. bei einem Fehlschlag **Offen → Fehler**.

Ein Eintrag steht auf Status "Fehler", wenn entweder
- **keine oder mehrere passende offene Einkaufsbestellungen** zum verkauften Artikel gefunden wurden (Fehlertext nennt die Artikelnummer), oder
- **das Buchen der Einkaufsrechnung selbst fehlgeschlagen ist** (z. B. gesperrte Buchungsperiode) – Fehlertext enthält die konkrete Fehlermeldung.

**Einen fehlerhaften Eintrag erneut anstoßen:** Wählen Sie den betroffenen Eintrag (oder mehrere) auf der Seite "CXW Cons. Posting Entries" aus und führen Sie die Aktion **"Retry"** aus. Der Status wird auf "Offen" zurückgesetzt; beim nächsten Lauf der Hintergrundverarbeitung wird der Eintrag automatisch erneut versucht – inklusive einer erneuten Ermittlung der passenden Einkaufsbestellung, falls diese beim ersten Versuch nicht gefunden wurde.

> Eine reine Lieferung ohne Fakturierung sowie der Verkauf eines Artikels ohne das Kennzeichen "Kommissionsverkauf" erzeugen keinen Eintrag.

## Datenmanagement

- **Sales Price / Archiv**: Bei jedem Ausführen von "Upload Sales Price" wird die freigegebene Preiszeile automatisch in die produktive Verkaufspreis-Tabelle (immer gültig für alle Kunden) sowie als neue, fortlaufend nummerierte Version in "Sales Price Archive" übernommen – auch bei einem erneuten Senden bereits übertragener Zeilen. Eine manuelle Pflege dieser beiden Tabellen ist nicht vorgesehen und nicht nötig.
- **Import/Export über Dateien**: Es existiert ein vorbereiteter, aber noch nicht angebundener Baustein für einen automatisierten, dateibasierten Preisimport. Dieser ist aktuell nicht Teil des produktiven Ablaufs (kein Job-Queue-Eintrag).
- **SellWatch-Ankaufsanfragen**: Die Tabellen hinter "SellWatch-Overview" sowie das Protokoll des Online-Checks ("Http Call Log") werden ausschließlich automatisiert befüllt; eine manuelle Pflege ist nicht vorgesehen und über die Seiten der Erweiterung auch nicht möglich (alle SellWatch-Seiten sind schreibgeschützt).
- **Workshop-Zeilen**: Werden ausschließlich über die Aktion "Send to Workshop" (Fachabteilung) sowie über die externe Workshop-API angelegt bzw. geändert. Die interne Übersichtsseite "CXW Workshop Lines" ist schreibgeschützt. Eine bereits verarbeitete Workshop-Zeile (Status "Verarbeitet") bleibt auch dann als Prüfnachweis bestehen, wenn die zugehörige Einkaufsbestellung storniert (gelöscht) wird.
- **Kommissions-Buchungseinträge**: Werden ausschließlich automatisch bei der VK-Rechnungsbuchung angelegt. Die Übersichtsseite "CXW Cons. Posting Entries" erlaubt außer der Aktion "Retry" (Statusänderung Fehler → Offen) keine manuelle Bearbeitung.

## Berechtigungen

Der Zugriff auf alle Objekte der Verkaufspreisverwaltung ist über das Permission Set **"CXWChronWSAll"** geregelt (deckt seit dem HTTP-Logging-Update auch die mit SellWatch geteilte Seite "Http Call Log" ab). Für SellWatch gilt das eigene Permission Set **"CXW SWChronWSAll"** (deckt "SellWatch-Overview", "SellWatch info" und die ebenfalls geteilte Seite "Http Call Log" sowie die zugrundeliegenden Tabellen ab). Für die Workshop-Ankaufsprüfung gibt es zwei getrennte Permission Sets: **"CXW Workshop All"** für den internen Vollzugriff (u. a. für den Job-Queue-Ausführungsbenutzer) und **"CXW Workshop API"** ausschließlich für den externen Workshop-Dienstbenutzer (nur Lese-/Änderungsrecht auf die Workshop-Zeilen, kein Zugriff auf Einkaufsbeleg oder Artikel). Der Kommissionsverkauf nutzt **kein eigenes** Permission Set, sondern ist seit dieser Version in **"CXW Workshop All"** enthalten (inkl. Lesezugriff auf Verkaufsrechnungen und die Einkaufseinrichtung). Alle Sets müssen den entsprechenden Benutzern bzw. Benutzergruppen noch zugewiesen werden, bevor diese die jeweiligen Seiten der Erweiterung nutzen können.

## Troubleshooting

| Problem | Ursache / Lösung |
|---|---|
| Import CSV lässt sich nicht ausführen | Grundeinstellungen (Mindestmarge %, Schwellenwert Lagerpreis %) sind nicht befüllt, oder die Liste enthält noch Preiszeilen aus einem vorherigen Durchlauf. |
| "Add all Countries" erzeugt keine Zeile für ein bestimmtes Land | Prüfen Sie, ob für das Land (Seite "Countries/Regions") "Verkaufspreis aktiviert" gesetzt ist. |
| Ein Benutzer kann die Seiten der Verkaufspreisverwaltung nicht öffnen | Prüfen Sie, ob dem Benutzer das Permission Set "CXWChronWSAll" zugewiesen ist. |
| Ein Preis wird trotz korrekter Eingabe nicht mit Marge X% berechnet | Die kategoriebasierte Nicht-Lagerpreis-Berechnung ist aktuell nicht automatisch eingebunden – bitte an das Entwicklungsteam eskalieren, falls diese Funktion benötigt wird. |
| "Upload Sales Price" meldet, dass keine API-Schnittstelle hinterlegt ist bzw. bricht ab | Prüfen Sie in den Grundeinstellungen, ob "Preisexport aktiv" gesetzt und ein "API-Schnittstellencode" ausgewählt ist, und ob die zugehörige Schnittstelle unter "API Interface Setup" aktiv sowie vollständig konfiguriert (Endpoint URL, ggf. API Key) ist. Details zum konkreten Fehler (Statuscode, Fehlermeldung) finden Sie auf der Seite "Http Call Log". |
| Einzelne Preiszeilen bleiben nach "Upload Sales Price" mit "Export Status" = "Error" stehen | Andere Zeilen im selben Lauf werden trotzdem weiterverarbeitet. Prüfen Sie die betroffene Zeile auf ungültige Werte (z. B. nicht existierender Währungscode) und lösen Sie den Upload für diese Zeile erneut aus. |
| "Export Data" auf "Data Export Entries" meldet bei einem Eintrag mit Zielcode `SALESPRICE` einen Fehler | Das ist so vorgesehen: Preisübertragungen laufen nur über "Upload Sales Price". Setzen Sie die betroffene Preiszeile erneut hoch; legen Sie **keinen** Eintrag `SALESPRICE` unter "Data Export API Setup" an. Hinweis: Der Status des Eintrags wechselt dabei auf "Fehler" und die Anzahl Versuche wird erhöht – auch wenn der Preis zuvor erfolgreich übertragen wurde ("Verarbeitet"). Es wird dabei nichts gesendet. |
| Ein Benutzer kann die SellWatch-Seiten nicht öffnen | Prüfen Sie, ob dem Benutzer das Permission Set "CXW SWChronWSAll" zugewiesen ist. |
| Eine Uhr wird auf "SellWatch-Overview" nie als online markiert bzw. "Http Call Log" zeigt Fehlschläge | Prüfen Sie, ob unter "API Interface Setup" ein Eintrag mit Code `WOA` existiert, aktiv ist und Endpoint URL sowie API Key gesetzt sind. Details zum konkreten Fehler (Statuscode, Fehlermeldung) finden Sie auf der Seite "Http Call Log". |
| Zu einer SellWatch-Anfrage wird kein Lieferant/keine Bestellung angelegt | Die Anlage erfolgt vollautomatisiert im Hintergrund; es gibt keine Aktion, mit der Sie dies als Key User manuell anstoßen können. Prüfen Sie zunächst, ob die Anfrage überhaupt vollständig eingegangen ist, und eskalieren Sie sonst an das Entwicklungsteam. |
| Ein Workshop-Benutzer kann nicht auf die API zugreifen | Prüfen Sie die OAuth2-App-Registrierung in Entra ID sowie ob dem dedizierten Workshop-Benutzer in BC exakt das Permission Set "CXW Workshop API" zugewiesen ist. |
| Workshop-Zeilen werden nicht verarbeitet, bleiben dauerhaft auf "WS geprüft" | Prüfen Sie, ob der Job-Queue-Eintrag für Codeunit "CXW Process Workshop Lines" existiert, aktiv und nicht fehlerhaft ist, und ob der ausführende Benutzer das Permission Set "CXW Workshop All" besitzt. |
| Eine Workshop-Zeile steht auf Status "Fehler" | Fehlertext im Feld "Last Error" auf Seite "CXW Workshop Lines" prüfen. Nach Behebung der Ursache (z. B. Buchungsperiode öffnen) Status manuell zurück auf "WS geprüft" setzen – die Zeile wird beim nächsten Job-Queue-Lauf automatisch erneut verarbeitet. |
| Versuch, eine Workshop-Zeile direkt auf Status "Fehler" zu setzen, schlägt fehl | Das ist beabsichtigt: Der Status "Fehler" darf nur aus "WS geprüft" heraus gesetzt werden und ausschließlich durch die automatische Verarbeitung selbst. |
| Für einen Kommissionsverkauf entsteht kein Kommissions-Buchungseintrag | Prüfen Sie, ob am verkauften Artikel das Kennzeichen "Consignment Sales" gesetzt ist und ob die Verkaufsrechnung tatsächlich als Rechnung gebucht wurde (nicht nur geliefert). |
| Ein Kommissions-Buchungseintrag steht dauerhaft auf Status "Fehler" | Fehlertext auf Seite "CXW Cons. Posting Entries" prüfen. Bei "keine/mehrere offene Bestellungen gefunden": Bestellsituation zum Artikel klären (z. B. wurde die Bestellung bereits storniert oder fakturiert?). Bei einer Buchungsfehlermeldung: Ursache beheben (z. B. Buchungsperiode öffnen) und danach die Aktion "Retry" ausführen. |
| Die automatische EK-Faktura wird nicht gebucht, obwohl das Fälligkeitsdatum erreicht ist | Prüfen Sie, ob der Job-Queue-Eintrag für Codeunit "CXW Post Consignment Purchases" existiert, aktiv und nicht fehlerhaft ist, und ob der ausführende Benutzer das Permission Set "CXW Workshop All" besitzt. |

## Eskalationswege

Bei technischen Fragen, die über die reine Konfiguration hinausgehen (z. B. Fehlermeldungen, die im Benutzer- oder Key-User-Handbuch nicht erklärt sind, oder Wünsche nach Aktivierung der aktuell zurückgestellten Funktionen), wenden Sie sich an das Entwicklungsteam – siehe Entwicklerhandbuch.
