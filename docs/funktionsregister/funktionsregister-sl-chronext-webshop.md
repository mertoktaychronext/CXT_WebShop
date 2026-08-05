# Funktionsregister – SL Chronext Webshop

**Version:** 1.0.0.0
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-05 (aktualisiert – NonDEPrice-Umschalter entfernt, Validate-Beobachtung erledigt)
**Abhängigkeiten:** keine

---

## Zusammenfassung

Dieses Projekt bildet die Verwaltung und Freigabe von Verkaufspreisen für den Webshop ab, migriert aus einem gewachsenen NAV-Altsystem. Neue Preise werden per CSV-Import eingelesen, inhaltlich geprüft (Mindestmarge, Preisschwankungen, Zeiträume) und von einem Sachbearbeiter freigegeben. Für jede Fremdwährung, die für den Webshop aktiviert ist, kann mit einem Klick automatisch ein umgerechneter Preis erzeugt werden ("Add all Currencies") – die Aktivierung erfolgt direkt auf der Währung selbst, nicht mehr länderbezogen. Ergänzend existiert ein automatisierter, dateibasierter CSV-Import-Baustein, der unabhängig vom manuellen Import läuft, aber aktuell noch nicht an eine Job-Queue angebunden ist. Land/Region liefert weiterhin Zusatzangaben wie Besteuerungsart und Lieferzeit, ist aber für die Frage "wird diese Fremdwährung für den Webshop bepreist?" nicht mehr maßgeblich. Ein Permission Set deckt den Zugriff auf alle eigenen Objekte ab.

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Tabellen | 5 |
| Tabellenerweiterungen | 3 |
| Seiten | 3 |
| Seitenerweiterungen | 3 |
| XMLports | 1 |
| Codeunits | 1 |
| Enums | 3 |
| Permission Sets | 1 |
| **Gesamt Objekte** | **20** |
| **Gesamt Prozeduren/Trigger/Events** | **31** |

---

## Funktionsregister nach Objekt

### Tabelle: SL General Sales Price Setup (ID: 51000)

Einzige Einstellungstabelle (Singleton) für Mindestmarge und Preisschwankungs-Schwellenwerte. Enthält keine eigene Logik (keine Trigger/Prozeduren).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Einstellungstabelle. |

### Tabelle: SL Sales Price Checking (ID: 51001)

Das zentrale Arbeitstabelle für neu importierte, noch nicht freigegebene Verkaufspreise. Preiszeilen werden nur noch je Artikel/Variante/Währung geführt – ein eigener Ländercode existiert auf dieser Tabelle nicht mehr (die frühere länderbasierte Zuordnung wurde vollständig durch die Währung ersetzt).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"Accept New Setup" – OnValidate` | Trigger | – | Verhindert, dass eine Preiszeile als "akzeptiert" markiert wird, bevor sie validiert wurde; sichert bei Annahme eine Kopie der Anmerkung und setzt bei Rücknahme die Freigabe wieder zurück. |
| 2 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer neuen Zeile automatisch Änderungsdatum und Benutzer ein. |
| 3 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer und setzt Freigabe/Validierung zurück, wenn sich die Währung nachträglich ändert. |
| 4 | `OnRename` | Trigger | – | Aktualisiert Änderungsdatum/Benutzer, wenn der Schlüssel einer Zeile umbenannt wird. |

> **Hinweis:** Die Variable `Country: Record "Country/Region"` ist im Tabellencode noch deklariert, wird aber seit dem Entfernen des Ländercode-Feldes an keiner Stelle mehr verwendet (ungenutzte Variable).

### Tabelle: SL Sales Price Archive (ID: 51002)

Historisches Archiv bereits verarbeiteter Preiszeilen (reine Ablage, nicht editierbar über UI).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Archiv-Eintrags automatisch Änderungsdatum und Benutzer ein. |
| 2 | `OnModify` | Trigger | – | Aktualisiert Änderungsdatum und Benutzer bei einer nachträglichen Änderung des Archiv-Eintrags. |

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

### Tabellenerweiterung: SL Country Region (ID: 51000, erweitert Land/Region)

Ergänzt Land/Region um Zusatzangaben für den Webshop-Betrieb: Besteuerungsart, Lieferzeit und die Standard-Fremdwährung dieses Landes. Die frühere Aktivierungsmarkierung ("Sales Price Activated") befindet sich seit diesem Update nicht mehr hier, sondern direkt auf der Währung (siehe Tabellenerweiterung 51002). Enthält keine eigene Logik.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: SL Sales Price (ID: 51001, erweitert Verkaufspreis)

Ergänzt den Standard-Verkaufspreis um Webshop-spezifische Felder (Grund, Kommentar, Anmerkung, Vergleichspreise, Land/Region). Über die Seitenerweiterung `SL Sales Prices` (ID 51001) pflegbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinitionen. |

### Tabellenerweiterung: SLCurrency (ID: 51002, erweitert Currency) — NEU

Ergänzt die Standard-Währung um die Markierung, ob diese Währung für die automatische Webshop-Preiserzeugung ("Add all Currencies") berücksichtigt werden soll. Ersetzt die frühere länderbasierte Aktivierung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Felddefinition ("Sales Price Activated"). |

### Seite: SL General Sales Price Setup (ID: 51000)

Einstellungsseite (Karte) für Mindestmarge und Preisschwankungs-Schwellenwerte. Über "Tell Me"/Verwaltung auffindbar; auch direkt aus Page 51001 über die Navigation-Action erreichbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeige-/Eingabeseite. |

### Seite: SL Sales Price Checking List (ID: 51001)

Die zentrale Arbeitsliste für den kompletten Preisfreigabe-Workflow: Import, Prüfen, Freigeben, Währungserweiterung. Die Spalte "Country Code" wurde aus der Liste entfernt, da das zugrundeliegende Feld nicht mehr existiert. Der frühere "Non DE Price"-Umschalter wurde vollständig entfernt (Feld, Variable und die davon abhängige Sperre der Aktion "Add all Currencies").

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FinalPrice (Stock Price) – OnValidate` | Trigger | – | Markiert eine Preiszeile automatisch als "nicht validiert", sobald der Endpreis manuell geändert wird. |
| 2 | `GeneralSalesPriceSetup` | Navigation-Action | Public | Öffnet die allgemeine Verkaufspreiseinrichtung (Mindestmarge, Schwellenwerte). |
| 3 | `SalesPriceArchiveNav` | Navigation-Action | Public | Öffnet das Archiv der bereits verarbeiteten Verkaufspreise. |
| 4 | `Import CSV` | Action | Public | Liest eine CSV-Datei mit neuen Preiszeilen ein, sofern die Einstellungen vollständig sind und die Liste vorher geleert wurde. |
| 5 | `Validate` | Action | Public | Rundet die Preise und prüft alle offenen Preiszeilen fachlich (Mindestmarge, Preisschwankung, Zeitraum). |
| 6 | `Approve` | Action | Public | Gibt alle validierten, noch nicht akzeptierten Preiszeilen nach Sicherheitsabfrage gesammelt frei und vermerkt den freigebenden Benutzer. |
| 7 | `Add all Currencies` | Action | Public | Erzeugt für jede aktivierte Fremdwährung automatisch eine zusätzliche, währungsumgerechnete Kopie der Basiszeile. Jetzt ohne Einschränkung durch einen DE-/Nicht-DE-Modus immer verfügbar. |
| 8 | `OnOpenPage` | Trigger | – | Leert beim Öffnen der Liste alle vorhandenen Zeilen (Arbeitsliste wird bei jedem Aufruf neu befüllt). |
| 9 | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits akzeptierten Preiszeilen. |
| 10 | `fnValidate` | Prozedur | Internal | Führt die fachliche Prüfung je Preiszeile durch (Vergleich mit vorherigem Preis, Margenprüfung anhand letzter Einkaufskosten, Zeitraumprüfung) und setzt eine erklärende Anmerkung, falls etwas auffällig ist. |
| 11 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Gruppe von Preiszeilen in einer bestimmten Preisspanne den Nicht-Lagerpreis inkl. Währungsumrechnung. |

### Seite: SL Sales Price Archive (ID: 51002)

Reine Anzeigeliste des Preisarchivs (nicht editierbar). Über "Tell Me"/Verlauf auffindbar; auch direkt aus Page 51001 über die Navigation-Action erreichbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Anzeigeliste. |

### Seitenerweiterung: SL Country Region Card (ID: 51000, erweitert Countries/Regions)

Macht die Land/Region-Zusatzfelder (Besteuerungsart, Lieferzeit, Standard-Fremdwährung) im Standard-Land/Region-Datensatz sichtbar und pflegbar. Das Feld "Sales Price Activated" wurde hier entfernt (siehe Seitenerweiterung 51002).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige (Gruppe "Webshop Sales Price"). |

### Seitenerweiterung: SL Sales Prices (ID: 51001, erweitert Sales Prices)

Macht die Webshop-Felder der Tabellenerweiterung 51001 im Standard-Verkaufspreis-Datensatz sichtbar und pflegbar.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige (Gruppe "Webshop Details"). |

### Seitenerweiterung: SLCurrencies (ID: 51002, erweitert Currencies) — NEU

Macht das neue Aktivierungsfeld der Tabellenerweiterung 51002 in der Standard-Währungsliste sichtbar und pflegbar. Damit lässt sich pro Währung direkt einstellen, ob "Add all Currencies" sie berücksichtigt.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| – | – | – | – | Keine Prozeduren/Trigger vorhanden – reine Feldanzeige. |

### XMLport: SL Import Sales Price (ID: 51000)

Manueller CSV-Import direkt in die Arbeitsliste (Page 51001, Action "Import CSV").

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import die erste Zeile der CSV-Datei (Spaltenüberschriften). |
| 2 | `OnAfterInsertRecord` | Trigger | – | Wird nach jeder eingelesenen Preiszeile ausgeführt; enthält aktuell keine zusätzliche Logik. |
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

Deckt den Lese-/Schreibzugriff auf alle fünf eigenen Tabellen sowie die Ausführung von Codeunit, XMLport und den drei Seiten dieser Extension ab. Muss noch einer Benutzergruppe zugewiesen werden. Keine Prozeduren.

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| Dateibasierter Import/Protokoll | Table 51005, Table 51006, Codeunit 51001 | Klar abgegrenzter, von der manuellen Arbeitsliste unabhängiger Baustein (eigene Tabellen, ein Event Publisher für lose Kopplung). Könnte als eigenständige "Import-Pipeline"-Erweiterung herausgelöst werden, sobald eine Job-Queue-Anbindung erfolgt (siehe `docs/SCHWACHSTELLEN.md`, N3). |
| Währungs-/Länder-Stammdaten | TableExtension 51000, TableExtension 51002, PageExtension 51000, PageExtension 51002 | Reine Stammdatenerweiterung von Land/Region und Währung; wird von den Preisfunktionen nur gelesen, aber nirgends selbst verändert – wiederverwendbar für zukünftige, über den Webshop hinausgehende Länder-/Währungsfreigaben. |

---

**Hinweis zu diesem Update:** Gegenüber der Vorversion (2026-08-05, 20 Objekte/32 Funktionen) wurde der "Non DE Price"-Umschalter (Feld, Variable `NonDEPrice`, `Enabled`-Bedingung auf "Add all Currencies") vollständig aus Page 51001 entfernt (war zuvor auskommentiert statt gelöscht). Die zuvor gemeldete Beobachtung zur Währungscode-Zuweisung in der Validate-Aktion hat sich durch eine zwischenzeitliche Änderung des Nutzers bereits erledigt und ist entfallen. Ergebnis: 20 Objekte, 31 Funktionen.
