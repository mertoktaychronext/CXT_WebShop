# Funktionsregister – SL Chronext Webshop

**Version:** 1.0.0.0
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-05 (aktualisiert am 2026-08-10 – alle 26 Objekte und ihre Felder von IDs 51000–51007/Präfix „SL" nach IDs 60311–60336/Präfix „CXW" umnummeriert und umbenannt (reines Rename/Renumber, keine Logikänderung); zuvor: Artikelvarianten und Country Code vollständig aus dem Datenmodell entfernt)
**Abhängigkeiten:** keine

---

## Zusammenfassung

Dieses Projekt bildet die Verwaltung und Freigabe von Verkaufspreisen für den Webshop ab, migriert aus einem gewachsenen NAV-Altsystem. Neue Preise werden per CSV-Import eingelesen, inhaltlich geprüft (Mindestmarge, Preisschwankungen, Zeiträume) und von einem Sachbearbeiter freigegeben. Für jede Fremdwährung, die für den Webshop aktiviert ist, kann mit einem Klick automatisch ein umgerechneter Preis erzeugt werden ("Add all Currencies"). Mit der Aktion "Upload Sales Price" werden freigegebene Preiszeilen jetzt zuerst automatisch in die produktive Verkaufspreis-Tabelle sowie in ein versioniertes Preisarchiv übernommen und anschließend über eine konfigurierbare API-Schnittstelle an ein externes System (z. B. den Webshop selbst) übertragen. Ergänzend existiert ein automatisierter, dateibasierter CSV-Import-Baustein, der unabhängig vom manuellen Import läuft, aber aktuell noch nicht an eine Job-Queue angebunden ist. Ein Permission Set deckt den Zugriff auf alle eigenen Objekte ab.

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Tabellen | 7 |
| Tabellenerweiterungen | 3 |
| Seiten | 4 |
| Seitenerweiterungen | 3 |
| XMLports | 1 |
| Codeunits | 2 |
| Enums | 5 |
| Permission Sets | 1 |
| **Gesamt Objekte** | **26** |
| **Gesamt Prozeduren/Trigger/Events** | **47** |

---

## Funktionsregister nach Objekt

### Tabelle: CXW General Sales Price Setup (ID: 60311)

Einzige Einstellungstabelle (Singleton) für Mindestmarge, Preisschwankungs-Schwellenwerte und die Export-Anbindung (aktiv/inaktiv, verwendete API-Schnittstelle).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW API Interface Code" – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese tatsächlich für Verkaufspreise vorgesehen ist. |

### Tabelle: CXW Sales Price Checking (ID: 60312)

Das zentrale Arbeitstabelle für neu importierte, noch nicht freigegebene Verkaufspreise. Preiszeilen werden nur noch je Artikel/Währung geführt – weder ein eigener Variantencode noch ein Ländercode existieren auf dieser Tabelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Accept New Setup" – OnValidate` | Trigger | – | Verhindert, dass eine Preiszeile als "akzeptiert" markiert wird, bevor sie validiert wurde; sichert bei Annahme eine Kopie der Anmerkung und setzt bei Rücknahme die Freigabe wieder zurück. |
| 2 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer neuen Zeile automatisch Änderungsdatum und Benutzer ein. |
| 3 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer und setzt Freigabe/Validierung zurück, wenn sich die Währung nachträglich ändert. |
| 4 | `OnRename` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer, wenn der Schlüssel einer Zeile umbenannt wird. |

> **Hinweis:** Die Variable `Country: Record "Country/Region"` ist im Tabellencode noch deklariert, wird aber an keiner Stelle mehr verwendet (ungenutzte Variable).

### Tabelle: CXW Sales Price Archive (ID: 60313)

Versioniertes Archiv bereits hochgeladener Preiszeilen (reine Ablage, nicht editierbar über UI). Wird seit der Einführung von "Upload Sales Price" automatisch befüllt: Bei jedem Hochladen einer freigegebenen Preiszeile legt die Export-Anbindung hier eine neue, um eins hochgezählte Version ab.

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
| 1 | `Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass eine Endpunkt-URL hinterlegt ist und – falls eine Authentifizierung gewählt wurde – auch ein API-Schlüssel gespeichert ist. |
| 2 | `SetApiKey` | Prozedur | Public | Speichert einen neuen API-Schlüssel sicher (verschlüsselt) oder löscht ihn, wenn ein leerer Wert übergeben wird. |
| 3 | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand an die externe Schnittstelle aus. |
| 4 | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Bildet den eindeutigen internen Speicherschlüssel für den API-Schlüssel dieser Schnittstelle. |

### Tabellenerweiterung: CXW Country Region (ID: 60318, erweitert Land/Region)

Ergänzt Land/Region um Zusatzangaben für den Webshop-Betrieb: Besteuerungsart, Lieferzeit und die Standard-Fremdwährung dieses Landes. Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: CXW Sales Price (ID: 60319, erweitert Verkaufspreis)

Ergänzt den Standard-Verkaufspreis um Webshop-spezifische Felder (Grund, Kommentar, Anmerkung, Vergleichspreise, Vergleichs-Einzelpreis in Landeswährung). Über die Seitenerweiterung `CXW Sales Prices` (ID 60326) pflegbar; wird seit "Upload Sales Price" auch automatisiert durch Codeunit 60329 beschrieben.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: CXWCurrency (ID: 60320, erweitert Currency)

Ergänzt die Standard-Währung um die Markierung, ob diese Währung für die automatische Webshop-Preiserzeugung ("Add all Currencies") berücksichtigt werden soll.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition ("Sales Price Activated"). |

### Seite: CXW General Sales Price Setup (ID: 60321)

Einstellungsseite (Karte) für Mindestmarge, Preisschwankungs-Schwellenwerte und die Export-Anbindung. Über "Tell Me"/Verwaltung auffindbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnOpenPage` | Trigger | – | Legt die Einstellungszeile automatisch an, falls sie beim ersten Öffnen noch nicht existiert. |
| 2 | `APIInterfaceSetup` | Navigation-Action | Public | Öffnet die Verwaltung der externen API-Schnittstellen. |

### Seite: CXW Sales Price Checking List (ID: 60322)

Die zentrale Arbeitsliste für den kompletten Preisfreigabe-Workflow: Import, Prüfen, Freigeben, Währungserweiterung und Hochladen an das externe System.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FinalPrice (CXW Stock Price) – OnValidate` | Trigger | – | Markiert eine Preiszeile automatisch als "nicht validiert", sobald der Endpreis manuell geändert wird. |
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

### Seite: CXW Sales Price Archive (ID: 60323)

Reine Anzeigeliste des Preisarchivs (nicht editierbar). Über "Tell Me"/Verlauf auffindbar; auch direkt aus Page 60322 über die Navigation-Action erreichbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeigeliste. |

### Seite: CXW API Interface Setup (ID: 60324)

Verwaltungsliste für externe API-Schnittstellen (Endpunkt, Authentifizierung, API-Schlüssel, betroffene Tabelle, Aktiv-Kennzeichen).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `ApiKey – OnValidate` | Trigger | – | Speichert einen eingegebenen API-Schlüssel sicher ab und entfernt ihn danach aus dem sichtbaren Eingabefeld. |

### XMLport: CXW Import Sales Price (ID: 60328)

Manueller CSV-Import direkt in die Arbeitsliste (Page 60322, Action "Import CSV").

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import die erste Zeile der CSV-Datei (Spaltenüberschriften). |
| 2 | `OnAfterInsertRecord` | Trigger | – | Wird nach jeder eingelesenen Preiszeile ausgeführt; enthält aktuell keine zusätzliche Logik. |
| 3 | `OnOpenPage` (Anfrageseite) | Trigger | – | Setzt beim Öffnen des Import-Dialogs die (aktuell ungenutzte) Option "Für alle Länder" zurück. |
| 4 | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor, damit die erste Zeile als Überschriftenzeile erkannt wird. |
| 5 | `OnPostXmlPort` | Trigger | – | Zeigt nach abgeschlossenem Import eine Bestätigungsmeldung an. |

### Codeunit: CXW Export Gateway Sales Price (ID: 60329)

Übernimmt freigegebene Preiszeilen in die produktiven Tabellen und überträgt sie an ein externes System. Wird ausschließlich von Page 60322, Action "Upload Sales Price" aufgerufen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `WriteBackAndArchive` | Prozedur | Public | Übernimmt eine freigegebene Preiszeile in die produktive Verkaufspreis-Tabelle (legt sie neu an oder aktualisiert eine bestehende, immer gültig für "Alle Kunden") und legt anschließend eine neue, versionierte Kopie im Preisarchiv ab. Läuft vor jeder Dateierzeugung für den externen Versand. |
| 2 | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Verkaufspreis, Vergleichspreise, Grund und Anmerkung von der Preiszeile auf den Verkaufspreis-Datensatz. |
| 3 | `ArchiveCheckingLine` | Prozedur | Internal | Ermittelt die nächste freie Versionsnummer für eine Preiszeile im Archiv und legt dort eine neue, vollständige Kopie der Preiszeile ab. |
| 4 | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis-Datensatz vollständig in eine JSON-Datei um, legt sie in der Ausgangsdatei-Tabelle ab und stößt den Versand an die externe Schnittstelle an. |
| 5 | `SendToApiInterface` | Prozedur | Internal | Sendet die erzeugte JSON-Datei per HTTP an die in der Einrichtung hinterlegte externe Schnittstelle und vermerkt Erfolg oder Fehlermeldung am Dateieintrag. |
| 6 | `AddFieldToJson` | Prozedur | Internal | Wandelt ein einzelnes Datenfeld eines Verkaufspreis-Datensatzes typgerecht (Zahl, Text, Ja/Nein …) in ein JSON-Element um. |

### Codeunit: CXW Import Sales Prices (ID: 60330)

Automatisierter, dateibasierter CSV-Import (unabhängig vom manuellen Import über die XMLport). Verarbeitet eine hochgeladene Datei aus Table 60315 und schreibt das Ergebnis nach "Sales Price" bzw. protokolliert Fehler in Table 60316.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung einer eingegangenen Preisdatei. |
| 2 | `ProcessFile` | Prozedur | Internal | Liest die Datei zeilenweise ein, prüft die Kopfzeile, wandelt die Datenzeilen in temporäre Verkaufspreis-Datensätze um und schreibt am Ende das Ergebnis fest. |
| 3 | `ProcessLine` | Prozedur | Internal | Wandelt eine einzelne CSV-Zeile anhand ihrer Spaltenposition in einen temporären Verkaufspreis-Datensatz um. |
| 4 | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Kopfzeile der Datei exakt die erwartete Anzahl und Reihenfolge an Spalten enthält – verhindert, dass vertauschte Spalten unbemerkt falschen Feldern zugeordnet werden. |
| 5 | `WriteProtocol` | Prozedur | Internal | Schreibt eine Fehlermeldung zu einer verarbeiteten Datei in das Import-Protokoll (Table 60316). |
| 6 | `WriteSalesPrices` | Prozedur | Internal | Übernimmt die eingelesenen Preiszeilen in die echte Verkaufspreis-Tabelle – legt neue Preise an oder aktualisiert bestehende. |
| 7 | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert nach jeder Änderung eines bestehenden Verkaufspreises durch den automatisierten Import, inklusive Vorher-/Nachher-Stand – ermöglicht eigene Erweiterungen, ohne diese Codeunit selbst anzupassen. |

> **Hinweis:** `WriteSalesPrices` ruft `SalesPrice.Get(...)` inzwischen mit genau den 8 echten Primärschlüsselfeldern der Standardtabelle "Sales Price" auf (mit `''` für "Variant Code"); die frühere Schlüssel-Abweichung an dieser Stelle ist behoben. Dieser Baustein ist weiterhin an keiner Stelle produktiv verdrahtet.

### Enum: CXW Taxation Type (ID: 60331)

Werte: " " (leer), Full Taxation, Differential Taxation, Both. Keine Prozeduren.

### Enum: CXW Sales Price Reason Code (ID: 60332)

Werte: CatMan, Purchasing, Marketing. Keine Prozeduren.

### Enum: CXW Ext Interface File Status (ID: 60333)

Werte: New, To Process, In Process, Processed, Error, Notification, Canceled. Keine Prozeduren.

### Enum: CXW Sales Price Export Status (ID: 60334)

Werte: Not Sent, Sent, Error. Bildet auf der Preiszeile ab, ob und wie erfolgreich der Versand an das externe System war. Keine Prozeduren.

### Enum: CXW API Auth Type (ID: 60335)

Werte: None, API Key (Header), Basic Authentication. Steuert, wie sich die Export-Anbindung gegenüber der externen Schnittstelle authentifiziert. Keine Prozeduren.

### Permission Set: CXWChronWSAll (ID: 60336)

Deckt den Lese-/Schreibzugriff auf alle sieben eigenen Tabellen sowie die Ausführung beider Codeunits, der XMLport und aller vier Seiten dieser Extension ab. Muss noch einer Benutzergruppe zugewiesen werden. Keine Prozeduren.

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| Export-Anbindung an externe Systeme | Codeunit 60329, Table 60314, Table 60317, Page 60324, Enum 60335 | Generischer, wiederverwendbarer Baustein (konfigurierbare Endpunkte, Authentifizierung, JSON-Versand per Reflection) – nicht spezifisch auf Verkaufspreise beschränkt und für andere Export-Szenarien (andere Tabellen) direkt wiederverwendbar. |
| Dateibasierter Import/Protokoll | Table 60315, Table 60316, Codeunit 60330 | Klar abgegrenzter, von der manuellen Arbeitsliste unabhängiger Baustein (eigene Tabellen, ein Event Publisher für lose Kopplung). Könnte als eigenständige "Import-Pipeline"-Erweiterung herausgelöst werden, sobald eine Job-Queue-Anbindung erfolgt. |
| Währungs-/Länder-Stammdaten | TableExtension 60318, TableExtension 60320, PageExtension 60325, PageExtension 60327 | Reine Stammdatenerweiterung von Land/Region und Währung; wird von den Preisfunktionen nur gelesen, aber nirgends selbst verändert – wiederverwendbar für zukünftige, über den Webshop hinausgehende Länder-/Währungsfreigaben. |

---

**Hinweis zu diesem Update:** Gegenüber der Vorversion (2026-08-05, 26 Objekte/47 Funktionen) hat sich die Objekt- und Funktionsanzahl nicht verändert – zwei Changes (`remove-item-variants`, `remove-country-code`) haben ausschließlich Felder (`"Variant Code"` auf Table 60312/60313, `"Country Code"` auf Table 60313, `"Country/Region Code"` auf TableExtension 60319) sowie zugehörige Spalten und Codezeilen innerhalb bestehender Prozeduren entfernt, ohne neue Prozeduren/Trigger/Events einzuführen oder bestehende zu löschen. Betroffene Beschreibungen wurden entsprechend angepasst: Table 60312 (Zusammenfassung), TableExtension 60319 (Zusammenfassung), `UpdateSalesPriceFields` (Codeunit 60329). Der Hinweis zu Codeunit 60330 wurde aktualisiert, da die dort beschriebene Schlüssel-Abweichung in `WriteSalesPrices` als Nebeneffekt von `remove-country-code` behoben wurde. Ergebnis unverändert: 26 Objekte, 47 Funktionen.

**Update 2026-08-10:** Alle 26 Objekte dieser Erweiterung (Tabellen, Tabellenerweiterungen, Seiten, Seitenerweiterungen, XMLport, Codeunits, Enums, Permission Set) sowie alle von ihnen definierten Felder wurden reinen Rename/Renumber-Charakters von den IDs 51000–51007 (Präfix „SL") in den registrierten idRange-Block 60311–60336 (Präfix „CXW") verschoben – ohne Änderung an Geschäftslogik, Verhalten oder Feld-Captions. Zwei Bezeichner mussten wegen des 30-Zeichen-Limits von AL zusätzlich gekürzt werden: Table 60316 heißt technisch „CXW Price Import Protocol" (ohne „Sales" im Bezeichner, fachlich weiterhin die Sales-Price-Import-Protokolltabelle), und das Feld „Non Stock Price Threshold %" auf Table 60311 trägt technisch den Bezeichner „CXW Non Stock Price Thresh %" (Caption unverändert). Alle Objekt- und ID-Referenzen in diesem Dokument wurden entsprechend aktualisiert; siehe Entwicklerhandbuch für Details.
