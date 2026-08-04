# Funktionsregister – SL Chronext Webshop

**Version:** 1.0.0.0
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-04
**Abhängigkeiten:** keine

---

## Zusammenfassung

Dieses Projekt bildet die Verwaltung und Freigabe von Verkaufspreisen für den Webshop ab, migriert aus einem gewachsenen NAV-Altsystem. Neue Preise werden per CSV-Import eingelesen, inhaltlich geprüft (Mindestmarge, Preisschwankungen, Zeiträume) und von einem Sachbearbeiter freigegeben. Für Länder, die eine eigene Fremdwährung nutzen, kann mit einem Klick automatisch je Währung ein umgerechneter Preis erzeugt werden, statt für jedes Land einzeln. Ergänzend existiert ein noch nicht fertig angebundener Baustein für den automatisierten Preisexport/-import über Dateien (CSV/JSON), der aktuell als eigenständiger, aber inaktiver Programmteil vorliegt.

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Tabellen | 6 |
| Tabellenerweiterungen | 2 |
| Seiten | 3 |
| XMLports | 1 |
| Codeunits | 1 |
| Enums | 3 |
| **Gesamt Objekte** | **16** |
| **Gesamt Prozeduren/Trigger/Events** | **35** |

---

## Funktionsregister nach Objekt

### Tabelle: SL General Sales Price Setup (ID: 51000)

Grundeinstellungen für die Preisprüfung (Mindestmarge, Schwellenwerte, Preisexport-Schalter). Enthält keine eigene Programmlogik.

_Keine Prozeduren, Trigger oder Events._

---

### Tabelle: SL Sales Price Checking (ID: 51001)

Zwischenablage für neu importierte Preise, bevor sie geprüft und freigegeben werden.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Stock Price – OnValidate` | Trigger | – | Sollte prüfen, ob sich der Verkaufspreis geändert hat; diese Prüfung ist im Altsystem bereits deaktiviert und wurde unverändert übernommen. |
| 2 | `Accept New Setup – OnValidate` | Trigger | – | Verhindert, dass ein Preis freigegeben wird, bevor er geprüft wurde, und sichert beim Freigeben eine Kopie der Bemerkung. |
| 3 | `Country Code – OnValidate` | Trigger | – | Übernimmt beim Auswählen eines Landes automatisch dessen hinterlegte Währung und stellt sicher, dass das Land für den Verkaufspreis freigegeben ist. |
| 4 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer neuen Preiszeile automatisch Datum und Benutzer der letzten Änderung ein. |
| 5 | `OnModify` | Trigger | – | Setzt die Prüf- und Freigabekennzeichen zurück, sobald sich Land oder Währung einer Preiszeile ändern, damit sie erneut geprüft wird. |
| 6 | `OnRename` | Trigger | – | Aktualisiert Datum und Benutzer der letzten Änderung, wenn sich der Schlüssel einer Preiszeile ändert. |

---

### Tabelle: SL Sales Price Archive (ID: 51002)

Revisionssichere Ablage bereits hochgeladener Preise (aktuell nur lesend genutzt, siehe Seite 51002).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Archivieren eines Preises automatisch Datum und Benutzer ein. |
| 2 | `OnModify` | Trigger | – | Aktualisiert Datum und Benutzer, falls ein archivierter Preis nachträglich geändert wird. |

---

### Tabelle: SL Sales Price Outbound File (ID: 51004)

Ablage für Preisdaten, die an ein externes System übergeben werden sollen (Teil des noch nicht fertiggestellten Exportbausteins).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Setzt beim Anlegen eines Ausgangsdatensatzes automatisch den Zeitpunkt "Eingefügt am". |

---

### Tabelle: SL Sales Price Inbound File (ID: 51005)

Ablage für eingehende Preisdateien aus einem externen System (Teil des noch nicht fertiggestellten Importbausteins).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Setzt beim Anlegen eines Eingangsdatensatzes automatisch den Zeitpunkt "Eingefügt am". |

---

### Tabelle: SL Sales Price Import Protocol (ID: 51006)

Fehlerprotokoll für den automatisierten Dateiimport.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Setzt beim Anlegen eines Protokolleintrags automatisch den Zeitpunkt "Erstellt am". |

---

### Tabellenerweiterung: SL Country Region (ID: 51000, erweitert Land/Region)

Ergänzt Land/Region um Angaben zur Webshop-Preisfindung (Besteuerungsart, Lieferzeit, Fremdwährung, Freigabe für den Preisexport). Enthält keine eigene Programmlogik.

_Keine Prozeduren, Trigger oder Events._

---

### Tabellenerweiterung: SL Sales Price (ID: 51001, erweitert Verkaufspreis)

Ergänzt den Standard-Verkaufspreis um Felder für UVP, Streichpreis, Grundcode, Bemerkung/Kommentar und einen lokalwährungsbezogenen Vergleichspreis. Enthält keine eigene Programmlogik.

_Keine Prozeduren, Trigger oder Events._

---

### Seite: SL General Sales Price Setup (ID: 51000)

Eingabemaske für die Grundeinstellungen (Mindestmarge, Schwellenwerte). Enthält keine eigene Programmlogik.

_Keine Prozeduren, Trigger oder Events._

---

### Seite: SL Sales Price Checking List (ID: 51001)

Zentrale Arbeitsliste für Import, Prüfung und Freigabe neuer Verkaufspreise – das Herzstück dieses Projekts.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `NonDEPrice – OnValidate` | Trigger | – | Verhindert das Umschalten zwischen deutschem und internationalem Preismodus, solange noch Preiszeilen in der Liste stehen. |
| 2 | `FinalPrice (Stock Price) – OnValidate` | Trigger | – | Markiert eine Preiszeile automatisch als "nicht geprüft", sobald der Verkaufspreis manuell geändert wird. |
| 3 | `OnOpenPage` | Trigger | – | Leert beim Öffnen der Liste alle vorhandenen Preiszeilen, sodass nur aktuell importierte Preise angezeigt werden. |
| 4 | `OnModifyRecord` | Trigger | – | Verhindert das nachträgliche Ändern bereits freigegebener Preise und blockt deutsche Preise im internationalen Preismodus. |
| 5 | Action `Import CSV` | Trigger (OnAction) | – | Prüft, ob die Grundeinstellungen vollständig sind, und startet den Import einer CSV-Datei mit neuen Verkaufspreisen. |
| 6 | Action `Validate` | Trigger (OnAction) | – | Rundet importierte Preise, ergänzt fehlende Länder-Währungen und stößt die inhaltliche Prüfung aller Preiszeilen an. |
| 7 | Action `Approve` | Trigger (OnAction) | – | Gibt nach Rückfrage alle geprüften Preiszeilen zur Weiterverarbeitung frei und vermerkt den genehmigenden Benutzer. |
| 8 | Action `Add all Currencies` | Trigger (OnAction) | – | Erzeugt ausgehend von einer deutschen Preiszeile automatisch je genutzter Fremdwährung eine umgerechnete Preiszeile – eine Zeile pro Währung statt pro Land. |
| 9 | `fnValidate` | Prozedur | Internal | Vergleicht jede neue Preiszeile mit dem zuletzt aktiven Preis, prüft Mindestmarge und Preisschwankungen und vermerkt Auffälligkeiten als Bemerkung. |
| 10 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Preisspanne den Nicht-Lagerpreis anhand eines hinterlegten prozentualen Aufschlags. |
| 11 | `CheckEntries` | Prozedur | Internal | Ursprünglich eine Vorprüfung vor Aktionen; ist bereits im Altsystem deaktiviert und daher aktuell wirkungslos. |
| 12 | `CheckDEPrice` | Prozedur | Internal | Stellt sicher, dass in der Liste nicht gleichzeitig deutsche und internationale Preise gemischt werden. |

> Hinweis: Die Action „Upload Sales Price" ist im Code vollständig deaktiviert (auskommentiert) und wird daher hier nicht als aktive Funktion geführt. Sie war ursprünglich für die Übergabe freigegebener Preise an ein externes System vorgesehen; die Umsetzung ist auf Kundenwunsch zurückgestellt.

---

### XMLport: SL Import Sales Price (ID: 51000)

Technische Komponente hinter der Action „Import CSV" – liest die hochgeladene Datei ein.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Einlesen automatisch die erste Zeile der CSV-Datei (Spaltenüberschriften). |
| 2 | `OnAfterInsertRecord` | Trigger | – | War ursprünglich für automatische Länder- und Preisberechnung vorgesehen; diese Logik ist deaktiviert, da es dafür bereits aktive, gleichwertige Funktionen in der Preisprüfungsliste gibt. |
| 3 | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor, indem die Kopfzeilen-Erkennung zurückgesetzt wird. |
| 4 | `OnPostXmlPort` | Trigger | – | Zeigt nach Abschluss des Imports eine Bestätigungsmeldung an. |
| 5 | Requestpage `OnOpenPage` | Trigger | – | Setzt die (aktuell ungenutzte) Option "Preis für alle Länder festlegen" beim Öffnen des Importdialogs zurück. |

---

### Codeunit: SL Import Sales Prices (ID: 51001)

Noch nicht produktiv angebundener Baustein für einen automatisierten, dateibasierten Preisimport direkt in die echten Verkaufspreise (unabhängig vom manuellen CSV-Import über die Preisprüfungsliste).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung einer eingegangenen Preisdatei. |
| 2 | `ProcessFile` | Prozedur | Internal | Liest eine hochgeladene Datei Zeile für Zeile ein, prüft die Spaltenüberschriften und übergibt die Daten zur Übernahme in die Verkaufspreise. |
| 3 | `ProcessLine` | Prozedur | Internal | Wandelt eine einzelne Dateizeile in einen vorläufigen Verkaufspreis-Datensatz um. |
| 4 | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Spaltenüberschriften der importierten Datei den erwarteten Feldern entsprechen. |
| 5 | `WriteProtocol` | Prozedur | Internal | Vermerkt Fehlermeldungen zu einer importierten Datei in einem Protokoll. |
| 6 | `WriteSalesPrices` | Prozedur | Internal | Übernimmt die eingelesenen Preise in die echten Verkaufspreise – legt neue Preise an oder aktualisiert bestehende. |
| 7 | `OnAfterSalesPriceModify` | Event Publisher | Public | Meldet anderen Programmteilen, dass ein bestehender Verkaufspreis durch den automatisierten Import geändert wurde. |

---

### Enum: SL Taxation Type (ID: 51000)

Werteliste für die Besteuerungsart eines Landes (Vollbesteuerung, Differenzbesteuerung, Beides). Enthält keine Programmlogik.

### Enum: SL Sales Price Reason Code (ID: 51001)

Werteliste für den Grund einer Preisänderung (CatMan, Einkauf, Marketing). Enthält keine Programmlogik.

### Enum: SL Ext Interface File Status (ID: 51002)

Werteliste für den Verarbeitungsstatus einer Import-/Exportdatei (Neu, In Bearbeitung, Verarbeitet, Fehler, …). Enthält keine Programmlogik.

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| Dateibasierter Preisimport/-export | Codeunit `SL Import Sales Prices` (51001), Tabellen `SL Sales Price Outbound/Inbound File` (51004/51005), `SL Sales Price Import Protocol` (51006), Enum `SL Ext Interface File Status` (51002) | Funktional klar abgegrenzter Integrationsbaustein ohne enge Kopplung an die eigentliche Preisprüfungsliste; aktuell ohnehin noch nicht produktiv angebunden – guter Zeitpunkt, ihn als eigene, wiederverwendbare Extension anzulegen, statt ihn nachträglich später herauszulösen. |
| Preisprüfung & -freigabe | Tabellen `SL General Sales Price Setup` (51000), `SL Sales Price Checking` (51001), `SL Sales Price Archive` (51002), Seiten 51000–51002, XMLport `SL Import Sales Price` (51000) | Bildet einen in sich geschlossenen Geschäftsprozess (Import → Prüfung → Freigabe → Archiv). Sollte als Kern-Modul zusammenbleiben, nicht weiter aufteilen. |
| Tabellenerweiterungen Land/Region & Verkaufspreis | `SL Country Region` (TabExt 51000), `SL Sales Price` (TabExt 51001) | Reine Datenmodell-Ergänzungen ohne eigene Logik; müssen mit dem jeweils nutzenden Modul (Preisprüfung bzw. Dateiimport) mitwandern, keine eigenständige Auslagerung sinnvoll. |
