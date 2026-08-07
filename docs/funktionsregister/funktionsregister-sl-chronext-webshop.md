# Funktionsregister – SL Chronext Webshop

**Version:** 1.0.0.1
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-05 (aktualisiert 2026-08-07 – SellWatch-Ankaufsintegration ergänzt)
**Abhängigkeiten:** keine

---

## Zusammenfassung

Dieses Projekt bündelt mittlerweile zwei fachlich getrennte Prozesse. Zum einen die Verwaltung und Freigabe von Verkaufspreisen für den Webshop (migriert aus einem gewachsenen NAV-Altsystem, "SL"-Objekte): Neue Preise werden per CSV-Import eingelesen, inhaltlich geprüft (Mindestmarge, Preisschwankungen, Zeiträume) und von einem Sachbearbeiter freigegeben. Für jede Fremdwährung, die für den Webshop aktiviert ist, kann mit einem Klick automatisch ein umgerechneter Preis erzeugt werden ("Add all Currencies"). Mit der Aktion "Upload Sales Price" werden freigegebene Preiszeilen jetzt zuerst automatisch in die produktive Verkaufspreis-Tabelle sowie in ein versioniertes Preisarchiv übernommen und anschließend über eine konfigurierbare API-Schnittstelle an ein externes System (z. B. den Webshop selbst) übertragen. Ergänzend existiert ein automatisierter, dateibasierter CSV-Import-Baustein, der unabhängig vom manuellen Import läuft, aber aktuell noch nicht an eine Job-Queue angebunden ist.

Zum anderen, neu seit 2026-08-07, die Abwicklung von Ankaufsanfragen für gebrauchte Uhren über den Partner SellWatch ("SW"-Objekte): Aus eingehenden Anfragen werden automatisch Lieferanten und Einkaufsbestellungen erzeugt, der Bearbeitungsstatus wird per JSON an SellWatch zurückgemeldet, und Uhren können über eine externe Schnittstelle für den Online-Verkauf freigegeben werden. Beide Prozesse nutzen dieselbe generische Infrastruktur zur Verwaltung externer API-Schnittstellen (Table 51007 "SL API Interface Setup"). Zwei Permission Sets decken den Zugriff auf die jeweils eigenen Objekte ab (eines je Prozess).

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Tabellen | 9 |
| Tabellenerweiterungen | 5 |
| Seiten | 6 |
| Seitenerweiterungen | 3 |
| XMLports | 1 |
| Codeunits | 3 |
| Enums | 6 |
| Permission Sets | 2 |
| **Gesamt Objekte** | **35** |
| **Gesamt Prozeduren/Trigger/Events** | **60** |

---

## Funktionsregister nach Objekt

### Tabelle: SL General Sales Price Setup (ID: 51000)

Einzige Einstellungstabelle (Singleton) für Mindestmarge, Preisschwankungs-Schwellenwerte und die Export-Anbindung (aktiv/inaktiv, verwendete API-Schnittstelle).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"API Interface Code" – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese tatsächlich für Verkaufspreise vorgesehen ist. |

### Tabelle: SL Sales Price Checking (ID: 51001)

Das zentrale Arbeitstabelle für neu importierte, noch nicht freigegebene Verkaufspreise. Preiszeilen werden nur noch je Artikel/Währung geführt – weder ein eigener Variantencode noch ein Ländercode existieren auf dieser Tabelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"Accept New Setup" – OnValidate` | Trigger | – | Verhindert, dass eine Preiszeile als "akzeptiert" markiert wird, bevor sie validiert wurde; sichert bei Annahme eine Kopie der Anmerkung und setzt bei Rücknahme die Freigabe wieder zurück. |
| 2 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer neuen Zeile automatisch Änderungsdatum und Benutzer ein. |
| 3 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer und setzt Freigabe/Validierung zurück, wenn sich die Währung nachträglich ändert. |
| 4 | `OnRename` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer, wenn der Schlüssel einer Zeile umbenannt wird. |

> **Hinweis:** Die Variable `Country: Record "Country/Region"` ist im Tabellencode noch deklariert, wird aber an keiner Stelle mehr verwendet (ungenutzte Variable).

### Tabelle: SL Sales Price Archive (ID: 51002)

Versioniertes Archiv bereits hochgeladener Preiszeilen (reine Ablage, nicht editierbar über UI). Wird seit der Einführung von "Upload Sales Price" automatisch befüllt: Bei jedem Hochladen einer freigegebenen Preiszeile legt die Export-Anbindung hier eine neue, um eins hochgezählte Version ab.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Archiv-Eintrags automatisch Änderungsdatum und Benutzer ein. |
| 2 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum und Benutzer bei einer nachträglichen Änderung des Archiv-Eintrags. |

### Tabelle: SL Sales Price Outbound File (ID: 51004)

Ablage der tatsächlich an die externe Schnittstelle gesendeten Preisdateien (JSON) inklusive Versand-Status und Antworttext – dient der Nachvollziehbarkeit fehlgeschlagener Übertragungen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Ausgangsdatei-Eintrags automatisch den Erstellungszeitpunkt ein. |

### Tabelle: SL Sales Price Inbound File (ID: 51005)

Schlanke Zwischenablage für automatisiert eingehende CSV-Dateien.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines neuen Datei-Eintrags automatisch den Eingangszeitpunkt ein. |

### Tabelle: SL Sales Price Import Protocol (ID: 51006)

Protokolltabelle für Fehlermeldungen aus dem automatisierten Dateiimport.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den Erstellungszeitpunkt ein. |

### Tabelle: SL API Interface Setup (ID: 51007)

Verwaltet die Zugangsdaten und Konfiguration externer Schnittstellen (Endpunkt-URL, Authentifizierungsart, betroffene Tabelle). Der API-Schlüssel wird verschlüsselt im Isolated Storage abgelegt, nicht im Klartext in der Tabelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass eine Endpunkt-URL hinterlegt ist und – falls eine Authentifizierung gewählt wurde – auch ein API-Schlüssel gespeichert ist. |
| 2 | `SetApiKey` | Prozedur | Public | Speichert einen neuen API-Schlüssel sicher (verschlüsselt) oder löscht ihn, wenn ein leerer Wert übergeben wird. |
| 3 | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand an die externe Schnittstelle aus. |
| 4 | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Bildet den eindeutigen internen Speicherschlüssel für den API-Schlüssel dieser Schnittstelle. |

### Tabelle: SellWatch Vendor Info (ID: 51008)

Speichert eingehende Ankaufsanfragen von SellWatch (Verkäufer-, Uhren- und Angebotsdaten) inkl. eines berechneten Felds für die Tracking-Nummer der zugehörigen Bestellung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Datentabelle. |

### Tabelle: Watch Online Approval (ID: 51009)

Verwaltet je Artikel/Variante, ob eine angekaufte Uhr für den Online-Verkauf im Webshop freigegeben ist.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"Check Online" – OnValidate` | Trigger | – | Trägt automatisch das Datum der Erstfreigabe ein, sobald eine Uhr für den Online-Verkauf freigegeben wird. |
| 2 | `ReadJSONFile` | Prozedur | Internal | Nicht implementierte Altfunktion ohne Logik. |
| 3 | `CreateJsonObjectCheckOnline` | Prozedur | Public | Baut ein einfaches JSON-Dokument mit der laufenden Nummer eines Freigabe-Datensatzes. |
| 4 | `CreateEntryInexternalFile` | Prozedur | Public | Fragt bei der (in `SL API Interface Setup`, Code "WOA") konfigurierten externen Schnittstelle ab, ob eine Uhr online gehen darf, und setzt je nach Antwort die Online-Freigabe oder eine Bemerkung, dass die Uhr offline bleibt. |

> **Hinweis:** `CreateEntryInexternalFile` bricht bewusst kommentarlos ab, wenn die Schnittstelle nicht konfiguriert/aktiv ist oder kein API-Key hinterlegt ist — ebenso, wenn der HTTP-Aufruf fehlschlägt. Es gibt aktuell keine Protokollierung eines Fehlschlags (Follow-up-Anforderung angekündigt).

### Tabellenerweiterung: SL Country Region (ID: 51000, erweitert Land/Region)

Ergänzt Land/Region um Zusatzangaben für den Webshop-Betrieb: Besteuerungsart, Lieferzeit und die Standard-Fremdwährung dieses Landes. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: SL Sales Price (ID: 51001, erweitert Verkaufspreis)

Ergänzt den Standard-Verkaufspreis um Webshop-spezifische Felder (Grund, Kommentar, Anmerkung, Vergleichspreise, Vergleichs-Einzelpreis in Landeswährung). Über die Seitenerweiterung `SL Sales Prices` (ID 51001) pflegbar; wird seit "Upload Sales Price" auch automatisiert durch Codeunit 51000 beschrieben.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: SLCurrency (ID: 51002, erweitert Currency)

Ergänzt die Standard-Währung um die Markierung, ob diese Währung für die automatische Webshop-Preiserzeugung ("Add all Currencies") berücksichtigt werden soll.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition ("Sales Price Activated"). |

### Tabellenerweiterung: SW Purchase Line (ID: 51003, erweitert Einkaufsbestellzeile)

Ergänzt die Einkaufsbestellzeile um ein Kennzeichen "Gebrauchtware" für SellWatch-Bestellungen. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition ("Used good"). |

### Tabellenerweiterung: SW Purchase Header (ID: 51004, erweitert Einkaufsbestellkopf)

Ergänzt den Bestellkopf um eine Tracking-Nummer für SellWatch-Bestellungen. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition ("Tracking Number"). |

### Seite: SL General Sales Price Setup (ID: 51000)

Einstellungsseite (Karte) für Mindestmarge, Preisschwankungs-Schwellenwerte und die Export-Anbindung. Über "Tell Me"/Verwaltung auffindbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnOpenPage` | Trigger | – | Legt die Einstellungszeile automatisch an, falls sie beim ersten Öffnen noch nicht existiert. |
| 2 | `APIInterfaceSetup` | Navigation-Action | Public | Öffnet die Verwaltung der externen API-Schnittstellen. |

### Seite: SL Sales Price Checking List (ID: 51001)

Die zentrale Arbeitsliste für den kompletten Preisfreigabe-Workflow: Import, Prüfen, Freigeben, Währungserweiterung und Hochladen an das externe System.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FinalPrice (Stock Price) – OnValidate` | Trigger | – | Markiert eine Preiszeile automatisch als "nicht validiert", sobald der Endpreis manuell geändert wird. |
| 2 | `GeneralSalesPriceSetup` | Navigation-Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung (Mindestmarge, Schwellenwerte, Export-Anbindung). |
| 3 | `SalesPriceArchiveNav` | Navigation-Action | Public | Öffnet das Archiv der bereits hochgeladenen Verkaufspreise. |
| 4 | `Import CSV` | Action | Public | Liest eine CSV-Datei mit neuen Preiszeilen ein, sofern die Einstellungen vollständig sind und die Liste vorher geleert wurde. |
| 5 | `Validate` | Action | Public | Rundet die Preise und prüft alle offenen Preiszeilen fachlich (Mindestmarge, Preisschwankung, Zeitraum). |
| 6 | `Approve` | Action | Public | Gibt alle validierten, noch nicht akzeptierten Preiszeilen nach Sicherheitsabfrage gesammelt frei und vermerkt den freigebenden Benutzer. |
| 7 | `Add all Currencies` | Action | Public | Erzeugt für jede aktivierte Fremdwährung automatisch eine zusätzliche, währungsumgerechnete Kopie der Basiszeile. |
| 8 | `Upload Sales Price` | Action | Public | Übernimmt jede freigegebene Preiszeile zuerst in die produktive Verkaufspreis-Tabelle (immer als "Für alle Kunden" gültig) und in ein versioniertes Preisarchiv, und überträgt sie anschließend über die konfigurierte API-Schnittstelle an das externe System. Bereits erfolgreich übertragene Zeilen werden nur nach Rückfrage erneut gesendet. |
| 9 | `OnOpenPage` | Trigger | – | Leert beim Öffnen der Liste alle vorhandenen Zeilen (Arbeitsliste wird bei jedem Aufruf neu befüllt). |
| 10 | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits akzeptierten Preiszeilen. |
| 11 | `fnValidate` | Prozedur | Internal | Führt die fachliche Prüfung je Preiszeile durch (Vergleich mit vorherigem Preis, Margenprüfung anhand letzter Einkaufskosten, Zeitraumprüfung) und setzt eine erklärende Anmerkung, falls etwas auffällig ist. |
| 12 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Gruppe von Preiszeilen in einer bestimmten Preisspanne den Nicht-Lagerpreis inkl. Währungsumrechnung. Aktuell aus keinem aktiven Ablauf heraus aufgerufen. |

### Seite: SL Sales Price Archive (ID: 51002)

Reine Anzeigeliste des Preisarchivs (nicht editierbar). Über "Tell Me"/Verlauf auffindbar; auch direkt aus Page 51001 über die Navigation-Action erreichbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeigeliste. |

### Seite: SL API Interface Setup (ID: 51003)

Verwaltungsliste für externe API-Schnittstellen (Endpunkt, Authentifizierung, API-Schlüssel, betroffene Tabelle, Aktiv-Kennzeichen).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `ApiKey – OnValidate` | Trigger | – | Speichert einen eingegebenen API-Schlüssel sicher ab und entfernt ihn danach aus dem sichtbaren Eingabefeld. |

### Seite: SellWatch-Overview (ID: 51004)

Schreibgeschützte Übersicht aller SellWatch-Ankaufsanfragen mit Sprung zur zugehörigen Einkaufsbestellung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnOpenPage` | Trigger | – | Zeigt beim Öffnen nur SellWatch-Anfragen mit einer echten Anfrage-ID an. |
| 2 | `Show Document` | Action | Public | Öffnet die zu einer SellWatch-Anfrage gehörende Einkaufsbestellung zur Ansicht. |

### Seite: SellWatch info (ID: 51005)

Infobox-Ausschnitt (CardPart) mit den Uhren-Detailinformationen einer SellWatch-Anfrage, gedacht zum Einbetten auf einer übergeordneten Karte/Rollencenter.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden. |

### XMLport: SL Import Sales Price (ID: 51000)

Manueller CSV-Import direkt in die Arbeitsliste (Page 51001, Action "Import CSV").

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import die erste Zeile der CSV-Datei (Spaltenüberschriften). |
| 2 | `OnAfterInsertRecord` | Trigger | – | Wird nach jeder eingelesenen Preiszeile ausgeführt; enthält aktuell keine zusätzliche Logik. |
| 3 | `OnOpenPage` (Anfrageseite) | Trigger | – | Setzt beim Öffnen des Import-Dialogs die (aktuell ungenutzte) Option "Für alle Länder" zurück. |
| 4 | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor, damit die erste Zeile als Überschriftenzeile erkannt wird. |
| 5 | `OnPostXmlPort` | Trigger | – | Zeigt nach abgeschlossenem Import eine Bestätigungsmeldung an. |

### Codeunit: SL Export Gateway Sales Price (ID: 51000)

Übernimmt freigegebene Preiszeilen in die produktiven Tabellen und überträgt sie an ein externes System. Wird ausschließlich von Page 51001, Action "Upload Sales Price" aufgerufen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `WriteBackAndArchive` | Prozedur | Public | Übernimmt eine freigegebene Preiszeile in die produktive Verkaufspreis-Tabelle (legt sie neu an oder aktualisiert eine bestehende, immer gültig für "Alle Kunden") und legt anschließend eine neue, versionierte Kopie im Preisarchiv ab. Läuft vor jeder Dateierzeugung für den externen Versand. |
| 2 | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Verkaufspreis, Vergleichspreise, Grund und Anmerkung von der Preiszeile auf den Verkaufspreis-Datensatz. |
| 3 | `ArchiveCheckingLine` | Prozedur | Internal | Ermittelt die nächste freie Versionsnummer für eine Preiszeile im Archiv und legt dort eine neue, vollständige Kopie der Preiszeile ab. |
| 4 | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis-Datensatz vollständig in eine JSON-Datei um, legt sie in der Ausgangsdatei-Tabelle ab und stößt den Versand an die externe Schnittstelle an. |
| 5 | `SendToApiInterface` | Prozedur | Internal | Sendet die erzeugte JSON-Datei per HTTP an die in der Einrichtung hinterlegte externe Schnittstelle und vermerkt Erfolg oder Fehlermeldung am Dateieintrag. |
| 6 | `AddFieldToJson` | Prozedur | Internal | Wandelt ein einzelnes Datenfeld eines Verkaufspreis-Datensatzes typgerecht (Zahl, Text, Ja/Nein …) in ein JSON-Element um. |

### Codeunit: SL Import Sales Prices (ID: 51001)

Automatisierter, dateibasierter CSV-Import (unabhängig vom manuellen Import über die XMLport). Verarbeitet eine hochgeladene Datei aus Table 51005 und schreibt das Ergebnis nach "Sales Price" bzw. protokolliert Fehler in Table 51006.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung einer eingegangenen Preisdatei. |
| 2 | `ProcessFile` | Prozedur | Internal | Liest die Datei zeilenweise ein, prüft die Kopfzeile, wandelt die Datenzeilen in temporäre Verkaufspreis-Datensätze um und schreibt am Ende das Ergebnis fest. |
| 3 | `ProcessLine` | Prozedur | Internal | Wandelt eine einzelne CSV-Zeile anhand ihrer Spaltenposition in einen temporären Verkaufspreis-Datensatz um. |
| 4 | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Kopfzeile der Datei exakt die erwartete Anzahl und Reihenfolge an Spalten enthält – verhindert, dass vertauschte Spalten unbemerkt falschen Feldern zugeordnet werden. |
| 5 | `WriteProtocol` | Prozedur | Internal | Schreibt eine Fehlermeldung zu einer verarbeiteten Datei in das Import-Protokoll (Table 51006). |
| 6 | `WriteSalesPrices` | Prozedur | Internal | Übernimmt die eingelesenen Preiszeilen in die echte Verkaufspreis-Tabelle – legt neue Preise an oder aktualisiert bestehende. |
| 7 | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert nach jeder Änderung eines bestehenden Verkaufspreises durch den automatisierten Import, inklusive Vorher-/Nachher-Stand – ermöglicht eigene Erweiterungen, ohne diese Codeunit selbst anzupassen. |

> **Hinweis:** `WriteSalesPrices` ruft `SalesPrice.Get(...)` inzwischen mit genau den 8 echten Primärschlüsselfeldern der Standardtabelle "Sales Price" auf (mit `''` für "Variant Code"); die frühere Schlüssel-Abweichung an dieser Stelle ist behoben. Dieser Baustein ist weiterhin an keiner Stelle produktiv verdrahtet.

### Codeunit: SellWatch Mgt (ID: 51002)

Verarbeitet eingehende SellWatch-Ankaufsanfragen: legt Lieferanten und Einkaufsbestellungen an und baut die Statusmeldungen für die Rückmeldung an SellWatch. Migriert aus einem NAV-Altsystem.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die automatische Anlage neuer Lieferanten und Bestellungen aus offenen SellWatch-Ankaufsanfragen. |
| 2 | `ValidateAndCreateVendor` | Prozedur | Internal | Prüft für jede neue SellWatch-Ankaufsanfrage, ob bereits ein passender Lieferant existiert; legt andernfalls einen neuen Lieferanten samt Bankverbindung an. |
| 3 | `CreatePurchaseOrder` | Prozedur | Internal | Erstellt für eine SellWatch-Anfrage automatisch eine Einkaufsbestellung mit einer Position für die angebotene Uhr und gibt sie frei. |
| 4 | `CreatePurchaseOrderinBV` | Prozedur | Internal | Verarbeitet nachträglich alle SellWatch-Anfragen, die für die Bestellerstellung im BV-System vorgemerkt, aber noch ohne Bestellnummer sind. |
| 5 | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet je nach Angebotsart, ob die Bestellung direkt in der GmbH angelegt oder für die spätere BV-Verarbeitung vorgemerkt wird. |
| 6 | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Baut aus einer Einkaufsbestellung ein JSON-Dokument mit Bestellnummer, Lieferantenreferenz und Tracking-Nummer für den Datenaustausch mit SellWatch. |
| 7 | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Baut ein JSON-Dokument mit dem aktuellen Status einer SellWatch-Anfrage (z. B. angekommen, online, verkauft) inklusive Kontakt-, Uhren- und Auszahlungsdaten für die Rückmeldung an SellWatch. |

> **Hinweis:** Aus dem NAV-Quellsystem wurden bewusst nicht übernommen: die Prozeduren `SetPostingGroups()` und `GetnewNoSeries()` auf dem Standard-Lieferanten (keine Quelle mehr verfügbar), das Feld `Street` auf dem Lieferanten sowie zwei Funktionen, die Dateien über inzwischen nicht mehr benötigte Alt-Objekte ausgegeben haben. Betroffene Stellen sind im Code mit `// TODO` markiert.

### Enum: SL Taxation Type (ID: 51000)

Werte: " " (leer), Full Taxation, Differential Taxation, Both. Keine Prozeduren.

### Enum: SL Sales Price Reason Code (ID: 51001)

Werte: CatMan, Purchasing, Marketing. Keine Prozeduren.

### Enum: SL Ext Interface File Status (ID: 51002)

Werte: New, To Process, In Process, Processed, Error, Notification, Canceled. Keine Prozeduren.

### Enum: SL Sales Price Export Status (ID: 51003)

Werte: Not Sent, Sent, Error. Bildet auf der Preiszeile ab, ob und wie erfolgreich der Versand an das externe System war. Keine Prozeduren.

### Enum: SL API Auth Type (ID: 51004)

Werte: None, API Key (Header), Basic Authentication. Steuert, wie sich die Export-Anbindung gegenüber der externen Schnittstelle authentifiziert. Keine Prozeduren.

### Enum: SW Order Status (ID: 51006)

Werte: " " (leer), Watch Arrived, Watch is Online, Watch is Reserved, Watch is Sold, c2c payment confirmation, CPST WE2 Posted. Bildet den Bearbeitungsstatus einer SellWatch-Anfrage ab, der per JSON an SellWatch zurückgemeldet wird. Keine Prozeduren.

### Permission Set: SLChronWSAll (ID: 51000)

Deckt den Lese-/Schreibzugriff auf alle sieben Sales-Price-Tabellen sowie die Ausführung beider Sales-Price-Codeunits, der XMLport und aller vier Sales-Price-Seiten ab. Muss noch einer Benutzergruppe zugewiesen werden. Keine Prozeduren.

### Permission Set: SWChronWSAll (ID: 51001)

Deckt den Lese-/Schreibzugriff auf die beiden SellWatch-Tabellen, die Ausführung der Codeunit `SellWatch Mgt` sowie beide SellWatch-Seiten ab. Muss noch einer Benutzergruppe zugewiesen werden. Keine Prozeduren.

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| SellWatch-Ankaufsintegration | Table 51008/51009, Codeunit 51002, Page 51004/51005, Enum 51006, TableExt 51003/51004, Permission Set SWChronWSAll | Fachlich vollständig eigenständiger Prozess (Ankauf gebrauchter Uhren) ohne inhaltliche Berührung zur Preisprüfung/-freigabe; einzige Kopplung ist die gemeinsam genutzte API-Schnittstellen-Verwaltung (siehe unten). Klarer Kandidat für eine eigene Extension, falls SellWatch getrennt vom Preis-Webshop weiterentwickelt oder ausgerollt werden soll. |
| Export-Anbindung an externe Systeme | Codeunit 51000, Table 51004, Table 51007, Page 51003, Enum 51004 | Generischer, wiederverwendbarer Baustein (konfigurierbare Endpunkte, Authentifizierung, JSON-Versand per Reflection) – nicht spezifisch auf Verkaufspreise beschränkt und inzwischen bereits von zwei unabhängigen Prozessen genutzt (Sales-Price-Export **und** seit 2026-08-07 auch `Watch Online Approval` aus der SellWatch-Integration). Damit ein noch stärkerer Kandidat als zuvor für eine eigene, gemeinsame Basis-Extension, von der beide Fach-Extensions abhängen. |
| Dateibasierter Import/Protokoll | Table 51005, Table 51006, Codeunit 51001 | Klar abgegrenzter, von der manuellen Arbeitsliste unabhängiger Baustein (eigene Tabellen, ein Event Publisher für lose Kopplung). Könnte als eigenständige "Import-Pipeline"-Erweiterung herausgelöst werden, sobald eine Job-Queue-Anbindung erfolgt. |
| Währungs-/Länder-Stammdaten | TableExtension 51000, TableExtension 51002, PageExtension 51000, PageExtension 51002 | Reine Stammdatenerweiterung von Land/Region und Währung; wird von den Preisfunktionen nur gelesen, aber nirgends selbst verändert – wiederverwendbar für zukünftige, über den Webshop hinausgehende Länder-/Währungsfreigaben. |

---

**Hinweis zum Update vom 2026-08-05:** Gegenüber der Vorversion hatte sich die Objekt- und Funktionsanzahl nicht verändert – zwei Changes (`remove-item-variants`, `remove-country-code`) hatten ausschließlich Felder (`"Variant Code"` auf Table 51001/51002, `"Country Code"` auf Table 51002, `"Country/Region Code"` auf TableExtension 51001) sowie zugehörige Spalten und Codezeilen innerhalb bestehender Prozeduren entfernt, ohne neue Prozeduren/Trigger/Events einzuführen oder bestehende zu löschen. Ergebnis damals: 26 Objekte, 47 Funktionen.

**Hinweis zum Update vom 2026-08-07:** Aus einer NAV→AL-Migration wurde die komplette SellWatch-Ankaufsintegration neu hinzugefügt: Table 51008 "SellWatch Vendor Info", Table 51009 "Watch Online Approval", Codeunit 51002 "SellWatch Mgt", Page 51004 "SellWatch-Overview", Page 51005 "SellWatch info", Enum 51006 "SW Order Status", TableExtension 51003 "SW Purchase Line", TableExtension 51004 "SW Purchase Header" sowie Permission Set 51001 "SWChronWSAll". Dabei wurde ein zunächst hartcodierter API-Key in `Watch Online Approval` entfernt und stattdessen über die bereits vorhandene, generische Infrastruktur in Table 51007 "SL API Interface Setup" bezogen (Isolated Storage) — dadurch entstand eine neue, bewusste Abhängigkeit der SellWatch-Integration auf diese gemeinsame Basis. Ergebnis: 35 Objekte, 60 Funktionen (+9 Objekte / +13 Funktionen gegenüber der Vorversion).
