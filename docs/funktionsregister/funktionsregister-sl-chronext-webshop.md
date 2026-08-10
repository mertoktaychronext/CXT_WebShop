# Funktionsregister – SL Chronext Webshop

**Version:** 1.0.0.1
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-10 (vollständige Neuerstellung nach Zusammenführung der Feature-Branches „SellWatch" (PR 862) und „SalesPrice" (PR 861) im Integrationsbranch `02-DEV/development`; ersetzt die Vorversion, die ausschließlich den SalesPrice-Teil abbildete)
**Abhängigkeiten:** keine

---

## Zusammenfassung

Diese Extension bündelt zwei unabhängige Geschäftsprozesse für den Chronext-Webshop, die beide aus einem gewachsenen NAV-Altsystem migriert wurden und sich denselben registrierten ID-Bereich (60300–60349) teilen. **SellWatch** wickelt den Ankauf gebrauchter Uhren von Privatpersonen über eine externe Ankaufsplattform ab: eingehende Angebote werden automatisiert zu Lieferanten und Einkaufsaufträgen, der Freigabestatus für den Online-Verkauf einer Uhr wird über eine externe Schnittstelle abgefragt, und der Bestellstatus wird an die Plattform zurückgemeldet – jeder externe Aufruf wird protokolliert. **SalesPrice** bildet die Verwaltung und Freigabe von Verkaufspreisen für den Webshop ab: Preise werden per CSV importiert, fachlich geprüft (Mindestmarge, Preisschwankungen, Zeiträume), von einem Sachbearbeiter freigegeben, bei Bedarf automatisch auf weitere Fremdwährungen ausgeweitet und über eine konfigurierbare API-Schnittstelle an ein externes System übertragen; ein automatisierter, dateibasierter Import-Baustein existiert zusätzlich, ist aber noch nicht an eine Job-Queue angebunden. Beide Bereiche haben eigene Tabellen und eigene Permission Sets und haben ansonsten keine fachlichen Berührungspunkte zueinander – sie teilen sich die Extension, den ID-Bereich sowie seit dem HTTP-Logging-Update vom 2026-08-10 das gemeinsame technische Protokoll „CXW Http Call Log" (Table 60302 / Page 60309) für sämtliche externen HTTP-Aufrufe.

---

## Objektübersicht

| Objekttyp | Anzahl (davon SellWatch) | Anzahl (davon SalesPrice) | Gesamt |
|---|---|---|---|
| Tabellen | 3 | 7 | 10 |
| Tabellenerweiterungen | 2 | 3 | 5 |
| Seiten | 3 | 4 | 7 |
| Seitenerweiterungen | 0 | 3 | 3 |
| XMLports | 0 | 1 | 1 |
| Codeunits | 1 | 2 | 3 |
| Enums | 1 | 5 | 6 |
| Permission Sets | 1 | 1 | 2 |
| **Gesamt Objekte** | **11** | **26** | **37** |
| **Gesamt Prozeduren/Trigger/Events/Actions** | **19** | **49** | **68** |

---

## Funktionsregister nach Objekt

### Tabelle: CXW SellWatch Vendor Info (ID: 60300)

Zwischenspeicher für Ankaufsangebote, die über die externe SellWatch-Plattform (Ankauf gebrauchter Uhren von Privatpersonen) eingehen: enthält alle Angaben zum Verkäufer (Adresse, Bankverbindung), zur angebotenen Uhr (Marke, Modell, Zustand, Zubehör) sowie den vereinbarten Ankaufspreis. Aus jedem Datensatz kann automatisiert ein Lieferant und ein Einkaufsauftrag erzeugt werden.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen (inkl. einem FlowField für die Sendungsverfolgungsnummer). |

### Tabelle: CXW Watch Online Approval (ID: 60301)

Steuert und protokolliert, ob eine bereits eingegangene Uhr online zum Verkauf freigegeben werden darf: fragt bei der externen SellWatch-Schnittstelle an, ob eine Uhr „online gehen" darf, und speichert das Ergebnis inklusive Zeitpunkt.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Check Online" – OnValidate` | Trigger | – | Trägt automatisch das Datum der Erst-Online-Schaltung ein, sobald eine Uhr als „online" markiert wird. |
| 2 | `ReadJSONFile` | Prozedur | Internal | Leere, aktuell ungenutzte Hilfsfunktion ohne Funktionsumfang (technischer Rest aus der Altsystem-Migration). |
| 3 | `CreateJsonObjectCheckOnline` | Prozedur | Public | Baut aus einem Datensatz eine einfache JSON-Nachricht mit der laufenden Nummer auf – Hilfsfunktion für den externen Abgleich. |
| 4 | `CreateEntryInexternalFile` | Prozedur | Public | Fragt bei der externen SellWatch-Schnittstelle an, ob eine bestimmte Uhr online gehen darf, wertet die Antwort aus, setzt bei Freigabe automatisch das Erst-Online-Datum und protokolliert jeden Aufruf (Erfolg wie Fehler) im HTTP-Aufrufprotokoll. |
| 5 | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine für das Protokoll geeignete Textform der Anfrage, in der der geheime API-Schlüssel durch einen Platzhalter ersetzt ist, damit er nicht im Klartext gespeichert wird. |
| 6 | `LogHttpCall` | Prozedur | Internal | Legt zu jedem Aufruf der externen Schnittstelle einen Protokolleintrag mit Anfrage, Antwort, Erfolg/Fehler und HTTP-Status an. |
| 7 | `LogHttpCallFailureTelemetry` | Prozedur | Internal | Meldet einen fehlgeschlagenen Aufruf der externen Schnittstelle zusätzlich an die technische Überwachung (Telemetrie), damit IT-Verantwortliche gehäufte Fehler frühzeitig erkennen. |

> **Hinweis:** Der API-Schlüssel wird verschlüsselt im Isolated Storage abgelegt (kein Klartext-Secret mehr im Code); auch das Protokoll speichert den Schlüssel nur redigiert (`***redacted***`).

### Tabelle: CXW Http Call Log (ID: 60302)

Technisches Protokoll aller HTTP-Aufrufe externer Schnittstellen inklusive Anfrage- und Antwortinhalt – dient der Fehlersuche bei gescheiterten Übertragungen. Seit dem HTTP-Logging-Update (2026-08-10) ein gemeinsames Protokoll für sowohl die SellWatch-Online-Freigabe-Schnittstelle als auch den Verkaufspreis-Export (Codeunit 60329); das Feld „CXW Source Table No." unterscheidet die auslösende Quelltabelle (60301 SellWatch bzw. 60314 SalesPrice).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den Zeitpunkt des Aufrufs ein. |

### Tabellenerweiterung: CXW SW Purchase Line (ID: 60303, erweitert Einkaufszeile)

Ergänzt die Einkaufszeile um die Kennzeichnung „Used Good" (Gebrauchtware), damit angekaufte Gebrauchtuhren im Einkauf erkennbar sind. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition. |

### Tabellenerweiterung: CXW SW Purchase Header (ID: 60304, erweitert Einkaufskopf)

Ergänzt den Einkaufsauftragskopf um eine Sendungsverfolgungsnummer, die an SellWatch zurückgemeldet werden kann. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition. |

### Codeunit: CXW SellWatch Mgt (ID: 60305)

Zentrale Ablauflogik für den Ankaufsprozess von SellWatch-Angeboten: legt aus einem SellWatch-Angebot bei Bedarf automatisch einen neuen Lieferanten an, erstellt daraus einen Einkaufsauftrag und gibt ihn sofort frei. Baut außerdem die Nachrichten auf, mit denen Bestellung und Status an SellWatch zurückgemeldet werden.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die automatische Prüfung und Anlage von Lieferanten samt Einkaufsauftrag für alle noch nicht verarbeiteten SellWatch-Angebote. |
| 2 | `ValidateAndCreateVendor` | Prozedur | Internal | Sucht für jedes neue SellWatch-Angebot einen passenden, bereits vorhandenen Lieferanten (anhand Name, Adresse, Telefon, E-Mail); wird keiner gefunden, legt sie automatisch einen neuen Lieferanten samt Bankverbindung an und stößt anschließend die Erstellung des Einkaufsauftrags an. |
| 3 | `CreatePurchaseOrder` | Prozedur | Internal | Legt für ein SellWatch-Angebot, das noch keinen Einkaufsauftrag hat, automatisch einen Einkaufsauftrag mit Artikelzeile (abhängig von der Angebotsart: Kommission, Direktkauf oder Eintausch), Menge 1 und dem vereinbarten Ankaufspreis an und gibt ihn sofort manuell frei. |
| 4 | `CreatePurchaseOrderinBV` | Prozedur | Internal | Verarbeitet gesammelt alle SellWatch-Angebote, die für eine andere Gesellschaft (BV) vorgemerkt, aber noch ohne Einkaufsauftrag sind, und legt für sie nachträglich den Einkaufsauftrag an. |
| 5 | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet je nach Angebotsart, ob der Einkaufsauftrag sofort in der aktuellen Gesellschaft angelegt wird oder für eine andere Gesellschaft (BV) vorgemerkt werden muss. |
| 6 | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Baut aus einem Einkaufsauftrag eine JSON-Nachricht mit Bestell- und ggf. Sendungsverfolgungsnummer für die Rückmeldung an SellWatch auf. |
| 7 | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Baut eine vollständige Status-Rückmeldung an SellWatch auf (z. B. „Uhr angekommen", „online", „verkauft") inklusive Verkäuferdaten, Uhrendetails, Link zur Online-Freigabe sowie – bei Kommissionsgeschäften – der final ausgezahlten Provision in der jeweiligen Währung. |

> **Hinweis:** Zwei im NAV-Altsystem vorhandene Standardprozeduren (`SetPostingGroups`, `GetnewNoSeries` auf dem Lieferanten) waren im Quellexport nicht enthalten und wurden beim Übertrag nach AL als offene TODOs markiert; die Nummernvergabe für neue Lieferanten läuft aktuell über den Standard-Vorgang der Einkaufs- & Zahlungseinrichtung. Fachlich manuell prüfen, ob Buchungsgruppen korrekt gesetzt werden.

### Enum: CXW SW Order Status (ID: 60306)

Werte: „ " (leer), Watch Arrived, Watch is Online, Watch is Reserved, Watch is Sold, c2c payment confirmation, CPST WE2 Posted. Bildet den Status eines SellWatch-Ankaufs für die Rückmeldung an die externe Plattform ab. Keine Prozeduren.

### Seite: CXW SellWatch-Overview (ID: 60307)

Übersichtsliste aller eingegangenen SellWatch-Angebote mit Verkäufer-, Uhren- und Auftragsdaten (nicht editierbar). Über „Tell Me"/Listen auffindbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `ShowDocument` | Action | Public | Öffnet den zu einem SellWatch-Angebot bereits angelegten Einkaufsauftrag. |
| 2 | `OnOpenPage` | Trigger | – | Zeigt beim Öffnen nur Angebote mit einer tatsächlich vorhandenen SellWatch-Anfragenummer an. |

### Seite: CXW SellWatch info (ID: 60308)

Infokachel (Kartenteil) mit den wichtigsten Uhrendaten eines SellWatch-Angebots (Marke, Modell, Zustand, Zubehör, Angebotsart, Abholtermin) zur Einbindung in andere Seiten.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeige. |

### Seite: CXW Http Call Log (ID: 60309)

Technische Protokollliste aller HTTP-Aufrufe – seit dem HTTP-Logging-Update sowohl der SellWatch-Online-Freigabe-Schnittstelle als auch des Verkaufspreis-Exports; ermöglicht IT/Key User das Herunterladen von Anfrage und Antwort eines einzelnen Aufrufs zur Fehleranalyse. Über „Tell Me"/Listen auffindbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `DownloadRequest` | Action | Public | Lädt den protokollierten Anfrage-Inhalt eines Aufrufs als Textdatei herunter. |
| 2 | `DownloadResponse` | Action | Public | Lädt den protokollierten Antwort-Inhalt eines Aufrufs als Textdatei herunter. |

### Permission Set: CXW SWChronWSAll (ID: 60310)

Deckt den Lese-/Schreibzugriff auf alle drei SellWatch-Tabellen sowie die Ausführung von Codeunit 60305 und der drei SellWatch-Seiten ab. Muss noch einer Benutzergruppe zugewiesen werden. Keine Prozeduren.

### Tabelle: CXW General Sales Price Setup (ID: 60311)

Einzige Einstellungstabelle (Singleton) für Mindestmarge, Preisschwankungs-Schwellenwerte und die Export-Anbindung (aktiv/inaktiv, verwendete API-Schnittstelle).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW API Interface Code" – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese tatsächlich für Verkaufspreise vorgesehen ist. |

### Tabelle: CXW Sales Price Checking (ID: 60312)

Das zentrale Arbeitstabelle für neu importierte, noch nicht freigegebene Verkaufspreise. Preiszeilen werden nur noch je Artikel/Währung geführt – weder ein eigener Variantencode noch ein Ländercode existieren auf dieser Tabelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Accept New Setup" – OnValidate` | Trigger | – | Verhindert, dass eine Preiszeile als „akzeptiert" markiert wird, bevor sie validiert wurde; sichert bei Annahme eine Kopie der Anmerkung und setzt bei Rücknahme die Freigabe wieder zurück. |
| 2 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer neuen Zeile automatisch Änderungsdatum und Benutzer ein. |
| 3 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer und setzt Freigabe/Validierung zurück, wenn sich die Währung nachträglich ändert. |
| 4 | `OnRename` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer, wenn der Schlüssel einer Zeile umbenannt wird. |

> **Hinweis:** Die Variable `Country: Record "Country/Region"` ist im Tabellencode noch deklariert, wird aber an keiner Stelle mehr verwendet (ungenutzte Variable).

### Tabelle: CXW Sales Price Archive (ID: 60313)

Versioniertes Archiv bereits hochgeladener Preiszeilen (reine Ablage, nicht editierbar über UI). Wird seit der Einführung von „Upload Sales Price" automatisch befüllt: Bei jedem Hochladen einer freigegebenen Preiszeile legt die Export-Anbindung hier eine neue, um eins hochgezählte Version ab.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Archiv-Eintrags automatisch Änderungsdatum und Benutzer ein. |
| 2 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum und Benutzer bei einer nachträglichen Änderung des Archiv-Eintrags. |

### Tabelle: CXW Sales Price Outbound File (ID: 60314)

Ablage der tatsächlich an die externe Schnittstelle gesendeten Preisdateien (JSON) inklusive Versand-Status und Antworttext – dient der Nachvollziehbarkeit fehlgeschlagener Übertragungen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Ausgangsdatei-Eintrags automatisch den Erstellungszeitpunkt ein. |

### Tabelle: CXW Sales Price Inbound File (ID: 60315)

Schlanke Zwischenablage für automatisiert eingehende CSV-Dateien.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines neuen Datei-Eintrags automatisch den Eingangszeitpunkt ein. |

### Tabelle: CXW Price Import Protocol (ID: 60316)

Protokolltabelle für Fehlermeldungen aus dem automatisierten Dateiimport.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den Erstellungszeitpunkt ein. |

### Tabelle: CXW API Interface Setup (ID: 60317)

Verwaltet die Zugangsdaten und Konfiguration externer Schnittstellen (Endpunkt-URL, Authentifizierungsart, betroffene Tabelle). Der API-Schlüssel wird verschlüsselt im Isolated Storage abgelegt, nicht im Klartext in der Tabelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Active" – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass eine Endpunkt-URL hinterlegt ist und – falls eine Authentifizierung gewählt wurde – auch ein API-Schlüssel gespeichert ist. |
| 2 | `SetApiKey` | Prozedur | Public | Speichert einen neuen API-Schlüssel sicher (verschlüsselt) oder löscht ihn, wenn ein leerer Wert übergeben wird. |
| 3 | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand an die externe Schnittstelle aus. |
| 4 | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Bildet den eindeutigen internen Speicherschlüssel für den API-Schlüssel dieser Schnittstelle. |

### Tabellenerweiterung: CXW Country Region (ID: 60318, erweitert Land/Region)

Ergänzt Land/Region um Zusatzangaben für den Webshop-Betrieb: Besteuerungsart, Lieferzeit und die Standard-Fremdwährung dieses Landes. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: CXW Sales Price (ID: 60319, erweitert Verkaufspreis)

Ergänzt den Standard-Verkaufspreis um Webshop-spezifische Felder (Grund, Kommentar, Anmerkung, Vergleichspreise, Vergleichs-Einzelpreis in Landeswährung). Über die Seitenerweiterung „CXW Sales Prices" (ID 60326) pflegbar; wird seit „Upload Sales Price" auch automatisiert durch Codeunit 60329 beschrieben.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: CXWCurrency (ID: 60320, erweitert Currency)

Ergänzt die Standard-Währung um die Markierung, ob diese Währung für die automatische Webshop-Preiserzeugung („Add all Currencies") berücksichtigt werden soll.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition („Sales Price Activated"). |

### Seite: CXW General Sales Price Setup (ID: 60321)

Einstellungsseite (Karte) für Mindestmarge, Preisschwankungs-Schwellenwerte und die Export-Anbindung. Über „Tell Me"/Verwaltung auffindbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnOpenPage` | Trigger | – | Legt die Einstellungszeile automatisch an, falls sie beim ersten Öffnen noch nicht existiert. |
| 2 | `APIInterfaceSetup` | Navigation-Action | Public | Öffnet die Verwaltung der externen API-Schnittstellen. |

### Seite: CXW Sales Price Checking List (ID: 60322)

Die zentrale Arbeitsliste für den kompletten Preisfreigabe-Workflow: Import, Prüfen, Freigeben, Währungserweiterung und Hochladen an das externe System.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FinalPrice (CXW Stock Price) – OnValidate` | Trigger | – | Markiert eine Preiszeile automatisch als „nicht validiert", sobald der Endpreis manuell geändert wird. |
| 2 | `GeneralSalesPriceSetup` | Navigation-Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung (Mindestmarge, Schwellenwerte, Export-Anbindung). |
| 3 | `SalesPriceArchiveNav` | Navigation-Action | Public | Öffnet das Archiv der bereits hochgeladenen Verkaufspreise. |
| 4 | `Import CSV` | Action | Public | Liest eine CSV-Datei mit neuen Preiszeilen ein, sofern die Einstellungen vollständig sind und die Liste vorher geleert wurde. |
| 5 | `Validate` | Action | Public | Rundet die Preise und prüft alle offenen Preiszeilen fachlich (Mindestmarge, Preisschwankung, Zeitraum). |
| 6 | `Approve` | Action | Public | Gibt alle validierten, noch nicht akzeptierten Preiszeilen nach Sicherheitsabfrage gesammelt frei und vermerkt den freigebenden Benutzer. |
| 7 | `Add all Currencies` | Action | Public | Erzeugt für jede aktivierte Fremdwährung automatisch eine zusätzliche, währungsumgerechnete Kopie der Basiszeile. |
| 8 | `Upload Sales Price` | Action | Public | Übernimmt jede freigegebene Preiszeile zuerst in die produktive Verkaufspreis-Tabelle (immer als „Für alle Kunden" gültig) und in ein versioniertes Preisarchiv, und überträgt sie anschließend über die konfigurierte API-Schnittstelle an das externe System. Bereits erfolgreich übertragene Zeilen werden nur nach Rückfrage erneut gesendet. |
| 9 | `OnOpenPage` | Trigger | – | Leert beim Öffnen der Liste alle vorhandenen Zeilen (Arbeitsliste wird bei jedem Aufruf neu befüllt). |
| 10 | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits akzeptierten Preiszeilen. |
| 11 | `fnValidate` | Prozedur | Internal | Führt die fachliche Prüfung je Preiszeile durch (Vergleich mit vorherigem Preis, Margenprüfung anhand letzter Einkaufskosten, Zeitraumprüfung) und setzt eine erklärende Anmerkung, falls etwas auffällig ist. |
| 12 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Gruppe von Preiszeilen in einer bestimmten Preisspanne den Nicht-Lagerpreis inkl. Währungsumrechnung. Aktuell aus keinem aktiven Ablauf heraus aufgerufen. |

### Seite: CXW Sales Price Archive (ID: 60323)

Reine Anzeigeliste des Preisarchivs (nicht editierbar). Über „Tell Me"/Verlauf auffindbar; auch direkt aus Page 60322 über die Navigation-Action erreichbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeigeliste. |

### Seite: CXW API Interface Setup (ID: 60324)

Verwaltungsliste für externe API-Schnittstellen (Endpunkt, Authentifizierung, API-Schlüssel, betroffene Tabelle, Aktiv-Kennzeichen).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `ApiKey – OnValidate` | Trigger | – | Speichert einen eingegebenen API-Schlüssel sicher ab und entfernt ihn danach aus dem sichtbaren Eingabefeld. |

### Seitenerweiterung: CXW Country Region Card (ID: 60325, erweitert Land/Region-Karte)

Zeigt die neuen Zusatzangaben aus TableExtension 60318 auf der Land/Region-Karte an. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige. |

### Seitenerweiterung: CXW Sales Prices (ID: 60326, erweitert Verkaufspreise)

Zeigt die neuen Webshop-Felder aus TableExtension 60319 auf der Standard-Verkaufspreisliste an. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige. |

### Seitenerweiterung: CXW Currencies (ID: 60327, erweitert Währungen)

Zeigt die Markierung „Sales Price Activated" aus TableExtension 60320 auf der Standard-Währungsliste an. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige. |

### XMLport: CXW Import Sales Price (ID: 60328)

Manueller CSV-Import direkt in die Arbeitsliste (Page 60322, Action „Import CSV").

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import die erste Zeile der CSV-Datei (Spaltenüberschriften). |
| 2 | `OnAfterInsertRecord` | Trigger | – | Wird nach jeder eingelesenen Preiszeile ausgeführt; enthält aktuell keine zusätzliche Logik. |
| 3 | `OnOpenPage` (Anfrageseite) | Trigger | – | Setzt beim Öffnen des Import-Dialogs die (aktuell ungenutzte) Option „Für alle Länder" zurück. |
| 4 | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor, damit die erste Zeile als Überschriftenzeile erkannt wird. |
| 5 | `OnPostXmlPort` | Trigger | – | Zeigt nach abgeschlossenem Import eine Bestätigungsmeldung an. |

### Codeunit: CXW Export Gateway Sales Price (ID: 60329)

Übernimmt freigegebene Preiszeilen in die produktiven Tabellen und überträgt sie an ein externes System. Wird ausschließlich von Page 60322, Action „Upload Sales Price" aufgerufen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `WriteBackAndArchive` | Prozedur | Public | Übernimmt eine freigegebene Preiszeile in die produktive Verkaufspreis-Tabelle (legt sie neu an oder aktualisiert eine bestehende, immer gültig für „Alle Kunden") und legt anschließend eine neue, versionierte Kopie im Preisarchiv ab. Läuft vor jeder Dateierzeugung für den externen Versand. |
| 2 | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Verkaufspreis, Vergleichspreise, Grund und Anmerkung von der Preiszeile auf den Verkaufspreis-Datensatz. |
| 3 | `ArchiveCheckingLine` | Prozedur | Internal | Ermittelt die nächste freie Versionsnummer für eine Preiszeile im Archiv und legt dort eine neue, vollständige Kopie der Preiszeile ab. |
| 4 | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis-Datensatz vollständig in eine JSON-Datei um, legt sie in der Ausgangsdatei-Tabelle ab und stößt den Versand an die externe Schnittstelle an. |
| 5 | `SendToApiInterface` | Prozedur | Internal | Sendet die erzeugte JSON-Datei per HTTP an die in der Einrichtung hinterlegte externe Schnittstelle, vermerkt Erfolg oder Fehlermeldung am Dateieintrag und protokolliert jeden Aufruf (Erfolg wie Fehler) im gemeinsamen HTTP-Aufrufprotokoll (Table 60302). |
| 6 | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine für das Protokoll geeignete Textform der Anfrage, in der der geheime Authorization-Header durch einen Platzhalter ersetzt ist, damit er nicht im Klartext gespeichert wird. |
| 7 | `LogHttpCall` | Prozedur | Internal | Legt zu jedem Aufruf der externen Schnittstelle einen Eintrag im gemeinsamen HTTP-Aufrufprotokoll (Table 60302) mit Anfrage, Antwort, Erfolg/Fehler und HTTP-Status an. |
| 8 | `AddFieldToJson` | Prozedur | Internal | Wandelt ein einzelnes Datenfeld eines Verkaufspreis-Datensatzes typgerecht (Zahl, Text, Ja/Nein …) in ein JSON-Element um. |

### Codeunit: CXW Import Sales Prices (ID: 60330)

Automatisierter, dateibasierter CSV-Import (unabhängig vom manuellen Import über die XMLport). Verarbeitet eine hochgeladene Datei aus Table 60315 und schreibt das Ergebnis nach „Sales Price" bzw. protokolliert Fehler in Table 60316.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung einer eingegangenen Preisdatei. |
| 2 | `ProcessFile` | Prozedur | Internal | Liest die Datei zeilenweise ein, prüft die Kopfzeile, wandelt die Datenzeilen in temporäre Verkaufspreis-Datensätze um und schreibt am Ende das Ergebnis fest. |
| 3 | `ProcessLine` | Prozedur | Internal | Wandelt eine einzelne CSV-Zeile anhand ihrer Spaltenposition in einen temporären Verkaufspreis-Datensatz um. |
| 4 | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Kopfzeile der Datei exakt die erwartete Anzahl und Reihenfolge an Spalten enthält – verhindert, dass vertauschte Spalten unbemerkt falschen Feldern zugeordnet werden. |
| 5 | `WriteProtocol` | Prozedur | Internal | Schreibt eine Fehlermeldung zu einer verarbeiteten Datei in das Import-Protokoll (Table 60316). |
| 6 | `WriteSalesPrices` | Prozedur | Internal | Übernimmt die eingelesenen Preiszeilen in die echte Verkaufspreis-Tabelle – legt neue Preise an oder aktualisiert bestehende. |
| 7 | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert nach jeder Änderung eines bestehenden Verkaufspreises durch den automatisierten Import, inklusive Vorher-/Nachher-Stand – ermöglicht eigene Erweiterungen, ohne diese Codeunit selbst anzupassen. |

> **Hinweis:** `WriteSalesPrices` ruft `SalesPrice.Get(...)` mit genau den 8 echten Primärschlüsselfeldern der Standardtabelle „Sales Price" auf (mit `''` für „Variant Code"). Dieser Baustein ist weiterhin an keiner Stelle produktiv verdrahtet (keine Job-Queue-Anbindung).

### Enum: CXW Taxation Type (ID: 60331)

Werte: „ " (leer), Full Taxation, Differential Taxation, Both. Keine Prozeduren.

### Enum: CXW Sales Price Reason Code (ID: 60332)

Werte: CatMan, Purchasing, Marketing. Keine Prozeduren.

### Enum: CXW Ext Interface File Status (ID: 60333)

Werte: New, To Process, In Process, Processed, Error, Notification, Canceled. Keine Prozeduren.

### Enum: CXW Sales Price Export Status (ID: 60334)

Werte: Not Sent, Sent, Error. Bildet auf der Preiszeile ab, ob und wie erfolgreich der Versand an das externe System war. Keine Prozeduren.

### Enum: CXW API Auth Type (ID: 60335)

Werte: None, API Key (Header), Basic Authentication. Steuert, wie sich die Export-Anbindung gegenüber der externen Schnittstelle authentifiziert. Keine Prozeduren.

### Permission Set: CXWChronWSAll (ID: 60336)

Deckt den Lese-/Schreibzugriff auf alle sieben SalesPrice-Tabellen sowie die Ausführung beider SalesPrice-Codeunits, der XMLport und aller vier SalesPrice-Seiten ab. Muss noch einer Benutzergruppe zugewiesen werden. Keine Prozeduren.

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| SellWatch-Ankaufsanbindung | Table 60300, Table 60301, Table 60302, TableExtension 60303, TableExtension 60304, Codeunit 60305, Enum 60306, Page 60307–60309, Permission Set 60310 | Vollständig eigenständiger, klar abgegrenzter Geschäftsprozess (Ankauf gebrauchter Uhren) mit eigenen Tabellen, eigenem Permission Set und ohne jede fachliche Abhängigkeit zu SalesPrice – idealer Kandidat für eine eigene Extension, sobald ein zweiter Ankaufskanal oder eine separate Freigabe-/Release-Strategie gewünscht ist. |
| Externe HTTP-Anbindung mit Protokollierung | Table 60301 (Procedures `CreateEntryInexternalFile`, `LogHttpCall`, `LogHttpCallFailureTelemetry`), Table 60302, Page 60309 | Wiederkehrendes Muster (HTTP-Aufruf + Protokoll-Tabelle + Telemetrie bei Fehlern), das strukturell dem Export-Gateway von SalesPrice ähnelt, aber unabhängig implementiert ist – bei einer Konsolidierung könnte ein gemeinsamer, generischer „HTTP-Call-Logger"-Baustein für beide Bereiche entstehen. |
| Export-Anbindung an externe Systeme (SalesPrice) | Codeunit 60329, Table 60314, Table 60317, Page 60324, Enum 60335 | Generischer, wiederverwendbarer Baustein (konfigurierbare Endpunkte, Authentifizierung, JSON-Versand per Reflection) – nicht spezifisch auf Verkaufspreise beschränkt und für andere Export-Szenarien (andere Tabellen) direkt wiederverwendbar. |
| Dateibasierter Import/Protokoll (SalesPrice) | Table 60315, Table 60316, Codeunit 60330 | Klar abgegrenzter, von der manuellen Arbeitsliste unabhängiger Baustein (eigene Tabellen, ein Event Publisher für lose Kopplung). Könnte als eigenständige „Import-Pipeline"-Erweiterung herausgelöst werden, sobald eine Job-Queue-Anbindung erfolgt. |
| Währungs-/Länder-Stammdaten (SalesPrice) | TableExtension 60318, TableExtension 60320, PageExtension 60325, PageExtension 60327 | Reine Stammdatenerweiterung von Land/Region und Währung; wird von den Preisfunktionen nur gelesen, aber nirgends selbst verändert – wiederverwendbar für zukünftige, über den Webshop hinausgehende Länder-/Währungsfreigaben. |

---

**Hinweis zu diesem Update:** Diese Version ersetzt vollständig die Vorversion, die ausschließlich die 26 SalesPrice-Objekte abbildete. Grund: Der Merge der Feature-Branches „SellWatch" (PR 862) und „SalesPrice" (PR 861) in den Integrationsbranch `02-DEV/development` hatte den SellWatch-Anteil der Dokumentation nicht mit übernommen, obwohl die 11 SellWatch-Objekte im Quellcode vollständig vorhanden sind und mitkompilieren. Alle 37 Objekte wurden für dieses Dokument direkt aus dem aktuellen Quellcode (Branch `02-DEV/development`) neu erfasst; an den bereits zuvor dokumentierten 26 SalesPrice-Objekten hat sich inhaltlich nichts geändert (stichprobenartig gegen den aktuellen Code geprüft: Tab 60311, Tab 60317, Pag 60321, Pag 60322, Pag 60324, XmlPort 60328, Codeunit 60329, Codeunit 60330 – alle deckungsgleich mit der Vorversion). Ergebnis: 37 Objekte (11 SellWatch + 26 SalesPrice), 66 Prozeduren/Trigger/Events/Actions (19 SellWatch + 47 SalesPrice).
