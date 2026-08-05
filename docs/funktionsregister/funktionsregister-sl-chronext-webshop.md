# Funktionsregister – SL Chronext Webshop

**Version:** 1.0.0.0
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-05 (aktualisiert nach Senior-Dev-Cleanup, UI-Anbindung, Kommentar-Entfernung)
**Abhängigkeiten:** keine

---

## Zusammenfassung

Dieses Projekt bildet die Verwaltung und Freigabe von Verkaufspreisen für den Webshop ab, migriert aus einem gewachsenen NAV-Altsystem. Neue Preise werden per CSV-Import eingelesen, inhaltlich geprüft (Mindestmarge, Preisschwankungen, Zeiträume) und von einem Sachbearbeiter freigegeben. Für Länder, die eine eigene Fremdwährung nutzen, kann mit einem Klick automatisch je Währung ein umgerechneter Preis erzeugt werden ("Add all Currencies"), statt für jedes Land einzeln. Ergänzend existiert ein automatisierter, dateibasierter CSV-Import-Baustein (Inbound-Datei → Verarbeitung → Protokoll), der unabhängig vom manuellen Import läuft, aber aktuell noch nicht an eine Job-Queue angebunden ist. Die Länder-/Regionen- und Verkaufspreis-Stammdaten sind über zwei Seitenerweiterungen direkt in den Standard-BC-Seiten "Countries/Regions" und "Sales Prices" pflegbar; ein Permission Set deckt den Zugriff auf alle eigenen Objekte ab.

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Tabellen | 5 |
| Tabellenerweiterungen | 2 |
| Seiten | 3 |
| Seitenerweiterungen | 2 |
| XMLports | 1 |
| Codeunits | 1 |
| Enums | 3 |
| Permission Sets | 1 |
| **Gesamt Objekte** | **18** |
| **Gesamt Prozeduren/Trigger/Events** | **34** |

---

## Funktionsregister nach Objekt

### Tabelle: SL General Sales Price Setup (ID: 51000)

Einzige Einstellungstabelle (Singleton) für Mindestmarge und Preisschwankungs-Schwellenwerte. Enthält keine eigene Logik (keine Trigger/Prozeduren).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Einstellungstabelle. |

### Tabelle: SL Sales Price Checking (ID: 51001)

Das zentrale Arbeitstabelle für neu importierte, noch nicht freigegebene Verkaufspreise.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"Accept New Setup" – OnValidate` | Trigger | – | Verhindert, dass eine Preiszeile als "akzeptiert" markiert wird, bevor sie validiert wurde; sichert bei Annahme eine Kopie der Anmerkung und setzt bei Rücknahme die Freigabe wieder zurück. |
| 2 | `"Country Code" – OnValidate` | Trigger | – | Übernimmt beim Erfassen eines Landes automatisch dessen hinterlegte Verkaufspreis-Währung, sofern das Land für Webshop-Preise aktiviert ist – sonst wird ein Fehler angezeigt. |
| 3 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer neuen Zeile automatisch Änderungsdatum und Benutzer ein. |
| 4 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer und setzt Freigabe/Validierung zurück, wenn sich Land oder Währung nachträglich ändern. |
| 5 | `OnRename` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer, wenn der Schlüssel einer Zeile umbenannt wird. |

### Tabelle: SL Sales Price Archive (ID: 51002)

Historisches Archiv bereits verarbeiteter Preiszeilen (reine Ablage, nicht editierbar über UI).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Archiv-Eintrags automatisch Änderungsdatum und Benutzer ein. |
| 2 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum und Benutzer bei einer nachträglichen Änderung des Archiv-Eintrags. |

### Tabelle: SL Sales Price Inbound File (ID: 51005)

Schlanke Zwischenablage für automatisiert eingehende CSV-Dateien (Ersatz für das ISV-Modul EXIN, siehe Entwicklerhandbuch).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines neuen Datei-Eintrags automatisch den Eingangszeitpunkt ein. |

### Tabelle: SL Sales Price Import Protocol (ID: 51006)

Protokolltabelle für Fehlermeldungen aus dem automatisierten Dateiimport.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den Erstellungszeitpunkt ein. |

### Tabellenerweiterung: SL Country Region (ID: 51000, erweitert Land/Region)

Ergänzt Land/Region um die für Webshop-Preise nötigen Felder (Aktivierung, Währung, Besteuerungsart, Lieferzeit). Enthält keine eigene Logik – die Felder sind über die Seitenerweiterung `SL Country Region Card` (ID 51000) im Standard-Land/Region-Datensatz pflegbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: SL Sales Price (ID: 51001, erweitert Verkaufspreis)

Ergänzt den Standard-Verkaufspreis um Webshop-spezifische Felder (Grund, Kommentar, Anmerkung, Vergleichspreise). Über die Seitenerweiterung `SL Sales Prices` (ID 51001) pflegbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Seite: SL General Sales Price Setup (ID: 51000)

Einstellungsseite (Karte) für Mindestmarge und Preisschwankungs-Schwellenwerte. Über "Tell Me"/Verwaltung auffindbar; auch direkt aus Page 51001 über die Navigation-Action erreichbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeige-/Eingabeseite. |

### Seite: SL Sales Price Checking List (ID: 51001)

Die zentrale Arbeitsliste für den kompletten Preisfreigabe-Workflow: Import, Prüfen, Freigeben, Währungserweiterung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `NonDEPrice – OnValidate` | Trigger | – | Verhindert das Umschalten zwischen "DE-Preisen" und "Nicht-DE-Preisen", solange noch unbearbeitete Zeilen in der Liste stehen. |
| 2 | `FinalPrice (Stock Price) – OnValidate` | Trigger | – | Markiert eine Preiszeile automatisch als "nicht validiert", sobald der Endpreis manuell geändert wird. |
| 3 | `GeneralSalesPriceSetup` | Navigation-Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung (Mindestmarge, Schwellenwerte). |
| 4 | `SalesPriceArchiveNav` | Navigation-Action | Public | Öffnet das Archiv der bereits verarbeiteten Verkaufspreise. |
| 5 | `Import CSV` | Action | Public | Liest eine CSV-Datei mit neuen Preiszeilen ein, sofern die Einstellungen vollständig sind und die Liste vorher geleert wurde. |
| 6 | `Validate` | Action | Public | Prüft alle offenen Preiszeilen fachlich (Mindestmarge, Preisschwankung, Land/Währungs-Konsistenz, Zeitraum) und markiert sie als validiert; bricht mit klarer Fehlermeldung ab, wenn einer Zeile das Land fehlt. |
| 7 | `Approve` | Action | Public | Gibt alle validierten, noch nicht akzeptierten Preiszeilen nach Sicherheitsabfrage gesammelt frei und vermerkt den freigebenden Benutzer. |
| 8 | `Add all Currencies` | Action | Public | Erzeugt für jede aktivierte Fremdwährung automatisch eine zusätzliche, währungsumgerechnete Kopie der DE-Basiszeile (ersetzt die frühere, länderbasierte "Add All Countries"-Funktion). |
| 9 | `OnOpenPage` | Trigger | – | Leert beim Öffnen der Liste alle vorhandenen Zeilen (Arbeitsliste wird bei jedem Aufruf neu befüllt). |
| 10 | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits akzeptierten Preiszeilen und blockt DE-Preise, wenn gerade der Nicht-DE-Modus aktiv ist. |
| 11 | `fnValidate` | Prozedur | Internal | Führt die fachliche Prüfung je Preiszeile durch (Vergleich mit vorherigem Preis, Margenprüfung anhand letzter Einkaufskosten, Land/Währungs-Abgleich, Zeitraumprüfung) und setzt eine erklärende Anmerkung, falls etwas auffällig ist. |
| 12 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Gruppe von Preiszeilen in einer bestimmten Preisspanne den Nicht-Lagerpreis inkl. Währungsumrechnung. |
| 13 | `CheckDEPrice` | Prozedur | Internal | Stellt sicher, dass in der aktuellen Ansicht nicht gleichzeitig DE- und Nicht-DE-Preise vorkommen. |

### Seite: SL Sales Price Archive (ID: 51002)

Reine Anzeigeliste des Preisarchivs (nicht editierbar). Über "Tell Me"/Verlauf auffindbar; auch direkt aus Page 51001 über die Navigation-Action erreichbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeigeliste. |

### Seitenerweiterung: SL Country Region Card (ID: 51000, erweitert Countries/Regions)

Macht die Webshop-Felder der Tabellenerweiterung 51000 im Standard-Land/Region-Datensatz sichtbar und pflegbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige (Gruppe "Webshop Sales Price"). |

### Seitenerweiterung: SL Sales Prices (ID: 51001, erweitert Sales Prices)

Macht die Webshop-Felder der Tabellenerweiterung 51001 im Standard-Verkaufspreis-Datensatz sichtbar und pflegbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige (Gruppe "Webshop Details"). |

### XMLport: SL Import Sales Price (ID: 51000)

Manueller CSV-Import direkt in die Arbeitsliste (Page 51001, Action "Import CSV").

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import die erste Zeile der CSV-Datei (Spaltenüberschriften). |
| 2 | `OnAfterInsertRecord` | Trigger | – | Wird nach jeder eingelesenen Preiszeile ausgeführt; enthält aktuell keine zusätzliche Logik (die frühere Länder-/Preisstaffel-Berechnung erfolgt stattdessen über die Actions in Page 51001). |
| 3 | `OnOpenPage` (Anfrageseite) | Trigger | – | Setzt beim Öffnen des Import-Dialogs die (aktuell ungenutzte) Option "Für alle Länder" zurück. |
| 4 | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor, damit die erste Zeile als Überschriftenzeile erkannt wird. |
| 5 | `OnPostXmlPort` | Trigger | – | Zeigt nach abgeschlossenem Import eine Bestätigungsmeldung an. |

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

### Enum: SL Taxation Type (ID: 51000)

Werte: " " (leer), Full Taxation, Differential Taxation, Both. Keine Prozeduren.

### Enum: SL Sales Price Reason Code (ID: 51001)

Werte: CatMan, Purchasing, Marketing. Keine Prozeduren.

### Enum: SL Ext Interface File Status (ID: 51002)

Werte: New, To Process, In Process, Processed, Error, Notification, Canceled. Keine Prozeduren.

### Permission Set: SLChronWSAll (ID: 51000)

Deckt den Lese-/Schreibzugriff auf alle sechs eigenen Tabellen sowie die Ausführung von Codeunit, XMLport und den drei Seiten dieser Extension ab. Muss noch einer Benutzergruppe zugewiesen werden. Keine Prozeduren.

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| Dateibasierter Import/Protokoll | Table 51005, Table 51006, Codeunit 51001 | Klar abgegrenzter, von der manuellen Arbeitsliste unabhängiger Baustein (eigene Tabellen, ein Event Publisher für lose Kopplung). Könnte als eigenständige "Import-Pipeline"-Erweiterung herausgelöst werden, sobald eine Job-Queue-Anbindung erfolgt (siehe `docs/SCHWACHSTELLEN.md`, N3). |
| Länder-/Währungs-Stammdaten | TableExtension 51000, PageExtension 51000 | Reine Stammdatenerweiterung von Land/Region; wird von mehreren Preisfunktionen gelesen, aber nirgends selbst verändert – wiederverwendbar für zukünftige, über den Webshop hinausgehende Länderfreigaben. |

---

**Hinweis zu diesem Update:** Gegenüber der ersten Fassung dieses Registers (2026-08-04) wurden ergänzt: die beiden Seitenerweiterungen (PagExt51000, PagExt51001), das Permission Set, die beiden Navigation-Actions in Page 51001 sowie Page 51002 (fehlte zuvor komplett). Entfernt wurde Table 51004 "SL Sales Price Outbound File" (durch den Nutzer gelöscht, da nach Entfernen von Codeunit 51000 verwaist). Alle Code-Kommentare wurden zwischenzeitlich auf Anweisung entfernt – dieses Register ersetzt sie als einzige verbleibende Erklärungsquelle für die Fachlogik.
