# Funktionsregister – CHX.Webshop

**Version:** 27.0.0.2
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-11, vollständig neu erstellt am 2026-08-12, aktualisiert am 2026-08-12 (Workshop-Ankaufsprüfung ergänzt, SellWatch-Artikelanlage auf Item-Template umgestellt), aktualisiert am 2026-08-13 (Workshop-Ankaufsprüfung: Status "Fehler" und Feld "Letzter Fehler" ergänzt), vollständig gegengeprüft am 2026-08-13 (alle 50 AL-Dateien erneut gegen den Code geprüft; fehlende Aktion "Upload Sales Price" auf Seite 60322 ergänzt, sonst keine Abweichungen gefunden), aktualisiert am 2026-08-13 (Workshop-Ankaufsprüfung: Attribut 1–8 fachlich benannt statt Platzhalter), erneut gegengeprüft am 2026-08-13 (nur AL-Bezeichner der Felder 11–18 auf Tabelle 60318 umbenannt [z. B. "CXW Attribute 1" → "CXW Dial Color"], Captions unverändert; Verweise in Codeunit 60331, Seite 60338 und Seite 60339 gegen den aktuellen Code geprüft – Beschreibungen weiterhin korrekt, keine Änderung nötig), aktualisiert am 2026-08-14 (Kommissionsverkauf: verzögerte EK-Faktura ergänzt – neue Tabelle 60341, Enum 60343, Seite 60342, Codeunit 60344/60345; Permission Set 60301 erweitert; außerdem den seit Version 27.0.1.1 bereits real existierenden Bereich TableExtension 60322/PageExtension 60330 "CXW SW Purchases Setup" nachträglich erfasst und dabei die Objektzählung korrigiert [Tabellenerweiterungen und Seitenerweiterungen waren zuvor je um 1 zu niedrig]), vollständig gegengeprüft am 2026-09-02 (alle 57 AL-Objekte erneut Zeile für Zeile gegen den aktuellen Code abgeglichen – keine strukturellen Abweichungen; `CreateSellWatchItem` in Codeunit 60305 präzisiert: die Artikelvorlage wird jetzt aus dem Feld "SellWatch Item Template" der Einkaufseinrichtung gelesen, nicht mehr fest als erste vorhandene Vorlage; Version auf 27.0.0.2 nachgezogen)
**Abhängigkeiten:** CHX.Base (27.0.1.1)

---

## Zusammenfassung

CHX.Webshop bündelt vier weitgehend eigenständige Funktionsbereiche unter einem Dach: **SellWatch** wickelt den automatisierten Ankauf gebrauchter Uhren ab (eingehende Verkaufsanfragen – inzwischen auch per API von außen anlegbar –, automatische Lieferanten- und Bestellanlage, Online-Sichtbarkeitsprüfung beim Partner SellWatch), die **Workshop-Ankaufsprüfung** bindet eine externe Werkstatt in den Einkaufsprozess ein (Übergabe angekommener Bestellzeilen inkl. Herstellerseriennummer, externe Echtheits-/Attributprüfung per API, automatisierter Wareneingang bei Echtheit bzw. Stornierung bei Nicht-Echtheit), der neue Bereich **Kommissionsverkauf** bucht die Einkaufsrechnung zu auf Kommission verkaufter Ware nicht sofort, sondern verzögert und automatisiert nach der VK-Rechnungsbuchung (einrichtbare Anzahl Tage, mit Fehlerwarteschlange und manueller Nachbearbeitung), und die **Verkaufspreisverwaltung** steuert die Pflege, Prüfung, Freigabe und den Export von Webshop-Verkaufspreisen an ein externes System. Alle Bereiche teilen sich ein gemeinsames HTTP-Aufrufprotokoll bzw. folgen demselben Zwischentabellen-plus-API-Muster (bzw. beim Kommissionsverkauf einem Zwischentabellen-plus-Job-Queue-Muster); die Verkaufspreisverwaltung nutzt zusätzlich eine gemeinsame Schnittstellen-Konfigurationstabelle mit austauschbarer Authentifizierung (API-Schlüssel, Basis-Authentifizierung oder AWS Signature V4) sowie einen CSV-Importweg für Preisdaten und eine automatische Mehrwährungs-Ableitung. SellWatch besitzt seit einer früheren Erweiterung eine eigene, separat berechtigte API-Schreibschnittstelle für externe Systeme; die Workshop-Ankaufsprüfung folgt demselben Prinzip mit einer eigenen, bidirektionalen API für die externe Werkstatt. Der Kommissionsverkauf setzt auf das Artikel-Kennzeichen "Kommissionsverkauf" auf, das die Dependency CHX.Base bereitstellt.

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Codeunits | 6 |
| Tabellen | 12 |
| Tabellenerweiterungen | 6 |
| Seiten | 13 |
| Seitenerweiterungen | 5 |
| Xmlports | 1 |
| Enums | 9 |
| Permission Sets | 5 |
| **Gesamt Objekte** | **57** |
| **Gesamt Prozeduren/Trigger/Events** | **122** |

---

## Funktionsregister nach Objekt

### SellWatch (Uhren-Ankauf)

### Tabelle: CXW SellWatch Vendor Info (ID: 60300)

Speichert eine eingehende SellWatch-Ankaufsanfrage mit allen Lieferanten-, Uhren- und Angebotsdaten. Wird sowohl manuell als auch – seit der neuen API-Page 60337 – von externen Systemen per HTTP befüllt. Besitzt neben dem Primärschlüssel einen zweiten Schlüssel auf die SellWatch-Referenznummer (SRid) für die Dubletten-Prüfung.

*Keine eigenen Prozeduren oder Trigger – reine Datentabelle.*

### Tabelle: CXW Watch Online Approval (ID: 60301)

Prüft je Artikel/Variante beim Partner SellWatch, ob eine Uhr online sichtbar geschaltet werden darf, und protokolliert das Ergebnis.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Check Online – OnValidate` | Trigger | – | Trägt beim Aktivieren der Online-Freigabe automatisch das heutige Datum als "Erstes Online-Datum" ein. |
| 2 | `ReadJSONFile` | Prozedur | Internal | Leere Hilfsfunktion ohne aktuelle Funktion – technischer Rest aus der Migration. |
| 3 | `CreateJsonObjectCheckOnline` | Prozedur | Public | Baut ein minimales JSON-Objekt mit der Eintragsnummer, aktuell ohne Aufrufer im Code. |
| 4 | `CreateEntryInexternalFile` | Prozedur | Public | Fragt beim Partner SellWatch per HTTP ab, ob eine Uhr online gehen darf, und setzt je nach Antwort die Online-Freigabe oder einen Hinweistext. |
| 5 | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt den protokollierten Anfragetext, wobei der API-Schlüssel durch einen Platzhalter ersetzt wird. |
| 6 | `LogHttpCall` | Prozedur | Internal | Schreibt jeden Sichtbarkeits-Aufruf (Erfolg wie Fehlschlag) in das gemeinsame HTTP-Aufrufprotokoll. |
| 7 | `LogHttpCallFailureTelemetry` | Prozedur | Internal | Meldet einen fehlgeschlagenen Sichtbarkeits-Aufruf zusätzlich an die technische Telemetrie, damit Ausfälle zentral auffallen. |

### Tabellenerweiterung: CXW SW Purchase Line (ID: 60303)

Ergänzt die Standard-Einkaufszeile um das Kennzeichen "Gebraucht", damit von SellWatch angelegte Bestellzeilen als Gebrauchtware markiert sind.

*Keine eigenen Trigger – reine Felderweiterung.*

### Tabellenerweiterung: CXW SW Purchase Header (ID: 60304)

Ergänzt den Standard-Einkaufskopf um eine Sendungsverfolgungsnummer, die auf eine SellWatch-Bestellung eingetragen und später an SellWatch zurückgemeldet werden kann.

*Keine eigenen Trigger – reine Felderweiterung.*

### Codeunit: CXW SellWatch Mgt (ID: 60305)

Legt aus eingehenden SellWatch-Verkaufsanfragen automatisch Lieferanten und Einkaufsbestellungen an.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung aller noch nicht angelegten SellWatch-Anfragen. |
| 2 | `ValidateAndCreateVendor` | Prozedur | Internal | Sucht für jede noch offene Anfrage einen passenden Lieferanten anhand von Name/Adresse/Telefon/E-Mail oder legt einen neuen Lieferanten samt Bankverbindung an. |
| 3 | `CreatePurchaseOrder` | Prozedur | Internal | Legt zu einer Anfrage eine Einkaufsbestellung mit einer Position an, lässt dafür dynamisch einen neuen Artikel anlegen (siehe `CreateSellWatchItem`) und gibt die Bestellung sofort frei. |
| 4 | `CreatePurchaseOrderinBV` | Prozedur | Internal | Verarbeitet nachträglich alle Anfragen, die für die Bestellanlage in der niederländischen Gesellschaft vorgemerkt wurden. |
| 5 | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet je nach Angebotsart, ob die Bestellung direkt in der deutschen Gesellschaft angelegt wird oder für die niederländische Gesellschaft vorgemerkt wird. |
| 6 | `CreateSellWatchItem` | Prozedur | Internal | Legt für eine SellWatch-Bestellzeile einen neuen Artikel anhand der in der Einkaufseinrichtung hinterlegten Artikelvorlage ("SellWatch Item Template") an (Beschreibung aus Marke/Modell/Baujahr, zweite Beschreibungszeile aus der Referenz) inklusive passender Basis-Mengeneinheit; bricht kontrolliert ab, wenn keine Vorlage eingerichtet ist oder die eingerichtete Vorlage nicht mehr existiert. |
| 7 | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Baut eine JSON-Rückmeldung mit Referenznummer, Bestellnummer und – falls vorhanden – Sendungsverfolgungsnummer; aktuell ohne Aufrufer im Code. |
| 8 | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Baut eine ausführliche JSON-Statusrückmeldung (Kontaktdaten, Uhrendetails, Link, Auszahlungsbetrag) für eine SellWatch-Anfrage; aktuell ohne Aufrufer im Code. |

### Tabellenerweiterung: CXW SW Purchases Setup (ID: 60322)

Ergänzt die Standard-Einkaufseinrichtung um zwei SellWatch-/kommissionsbezogene Einstellungen: die für die automatische SellWatch-Artikelanlage zu verwendende Artikelvorlage (siehe `CreateSellWatchItem` in Codeunit 60305) sowie die Anzahl Tage, um die die automatische EK-Faktura für auf Kommission verkaufte Artikel nach der VK-Rechnungsbuchung verzögert wird (siehe Codeunit 60344/60345).

*Keine eigenen Trigger – reine Felderweiterung.*

### Seitenerweiterung: CXW SW Purchases Setup (ID: 60330)

Zeigt auf der Standard-Einkaufseinrichtung die beiden SellWatch-/kommissionsbezogenen Einstellungsfelder (Artikelvorlage, Verzögerung Kommissionsrechnung) an.

*Keine eigenen Trigger – reine Seitenerweiterung.*

### Enum: CXW SW Order Status (ID: 60306)

Definiert die Bestellstatus-Werte (Uhr eingetroffen, online, reserviert, verkauft, Zahlungsbestätigung, gebucht), die in der Statusrückmeldung an SellWatch verwendet werden. *Reine Werteliste ohne Prozeduren.*

### Seite: CXW SellWatch-Overview (ID: 60307)

Nur-Lese-Übersicht aller eingehenden SellWatch-Ankaufsanfragen – die einzige Anzeige-Seite für diese Daten.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `ShowDocument` | Aktion | – | Öffnet die zur Anfrage gehörende Einkaufsbestellung. |
| 2 | `OnOpenPage` | Trigger | – | Zeigt beim Öffnen nur Anfragen mit einer gültigen SellWatch-Referenznummer. |

### Seite: CXW SellWatch info (ID: 60308)

Reine Anzeige-Kachel mit Uhrendetails (Marke, Modell, Referenz, Zustand, Abholdatum) ohne eigenes Verhalten.

### Seite: CXW SellWatch API (ID: 60337)

API-Schnittstelle (OData v4, `saliniLife/sellWatch/v2.0`), über die externe Systeme per HTTP-Aufruf neue SellWatch-Ankaufsanfragen anlegen oder bestehende aktualisieren können. Ergänzt die reine Anzeige-Seite „CXW SellWatch-Overview" (60307) um einen Schreibzugang, ohne diese zu verändern – Verarbeitungsfelder (Erstellt-Kennzeichen, Bestellnummer, Lieferantennummer) bleiben für externe Aufrufer gesperrt.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsertRecord` | Trigger | – | Setzt beim Anlegen über die API das Erstellt-Kennzeichen sowie Bestell- und Lieferantennummer zurück, prüft die Pflichtfelder und lehnt doppelte SellWatch-Referenznummern ab. |
| 2 | `OnModifyRecord` | Trigger | – | Verhindert bei Änderungen über die API, dass das Erstellt-Kennzeichen sowie Bestell- und Lieferantennummer überschrieben werden, prüft weiterhin die Pflichtfelder und lehnt eine Änderung der Referenznummer auf einen bereits vergebenen Wert ab. |
| 3 | `ValidateRequiredFields` | Prozedur | Internal | Stellt sicher, dass Referenznummer, Marke, Modell und Angebotspreis beim Anlegen oder Ändern über die API ausgefüllt sind. |
| 4 | `CheckDuplicateSRid` | Prozedur | Internal | Lehnt einen Neuanlage- oder Änderungs-Aufruf ab, wenn bereits eine andere Anfrage mit derselben SellWatch-Referenznummer existiert. |

### Permission Set: CXW SWChronWSAll (ID: 60310)

Berechtigt zum vollständigen Arbeiten mit den SellWatch-Tabellen, -Seiten und der Verarbeitungslogik sowie dem gemeinsamen HTTP-Aufrufprotokoll. Deckt seit dieser Version auch die neue API-Page 60337 ab.

### Permission Set: CXW Sell Watch API (ID: 60300)

Eigener, schlanker Berechtigungssatz speziell für den externen (Entra-)Benutzer, der über die API-Page 60337 auf die SellWatch-Ankaufsanfragen zugreift – gewährt Lese-, Einfüge- und Änderungsrecht auf die Tabelle "CXW SellWatch Vendor Info", getrennt vom umfassenderen internen Berechtigungssatz 60310.

---

### Workshop-Ankaufsprüfung

Bindet eine externe Werkstatt in den Einkaufsprozess für angekaufte Uhren ein: Der Einkäufer meldet angekommene Bestellzeilen samt Herstellerseriennummer an die Werkstatt, diese prüft Echtheit und Attribute über eine eigene API, und eine Hintergrundverarbeitung bucht bei bestätigter Echtheit automatisch den Wareneingang bzw. storniert die Bestellung bei Nicht-Echtheit. Folgt demselben Zwischentabellen-plus-API-Muster wie SellWatch.

### Enum: CXW Workshop Line Status (ID: 60337)

Definiert die vier Prüfstatus einer Werkstattzeile (Neu, WS geprüft, Verarbeitet, Fehler). *Reine Werteliste ohne Prozeduren.*

### Tabelle: CXW Workshop Line (ID: 60318)

Ein Datensatz je an die Werkstatt übergebener Bestellzeile: hält die Herstellerseriennummer, den Prüfstatus, das Echtheits-Kennzeichen der Werkstatt, zehn Attributfelder (die ersten acht fachlich benannt: Zifferblattfarbe, Gehäusedurchmesser, Armbandmaterial, Gehäusematerial, Werk, Geschlecht, Glas, Ausstattung; Attribut 9/10 weiterhin Platzhalter) sowie den zuletzt aufgetretenen Verarbeitungsfehler.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer Werkstattzeile automatisch den Erstellungszeitpunkt ein. |
| 2 | `OnModify` | Trigger | – | Verhindert einen Rückschritt des Prüfstatus (von "WS geprüft" zurück auf "Neu" oder weg von "Verarbeitet") sowie einen Wechsel auf "Fehler" aus einem anderen Status als "WS geprüft" heraus, unabhängig davon, ob die Änderung über die API oder intern erfolgt; trägt beim Wechsel auf "WS geprüft" automatisch den Prüfzeitpunkt ein. |

### Tabellenerweiterung: CXW Workshop Purchase Line (ID: 60321)

Ergänzt die Standard-Einkaufszeile um Herstellerseriennummer, ein Kennzeichen "Nicht angekommen" sowie ein Kennzeichen "An Werkstatt gesendet".

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnDelete` | Trigger | – | Löscht beim Löschen einer Einkaufszeile die zugehörige Werkstattzeile automatisch mit, sofern diese noch nicht abschließend verarbeitet wurde; bereits verarbeitete Werkstattzeilen bleiben als Prüfnachweis bestehen. |

### Seitenerweiterung: CXW Workshop Purchase Order (ID: 60328)

Ergänzt die Standard-Einkaufsbestellung um die Aktion "An Werkstatt senden".

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Send to Workshop` | Aktion | – | Fragt für jede offene, noch nicht übertragene Bestellzeile die Ankunft ab, erfasst bei Bestätigung die Herstellerseriennummer über einen Eingabedialog und legt daraus eine Werkstattzeile an; nicht angekommene oder abgebrochene Zeilen werden übersprungen, ohne die übrigen Zeilen zu blockieren. |
| 2 | `SendLinesToWorkshop` | Prozedur | Internal | Ermittelt alle offenen, noch nicht an die Werkstatt gesendeten Bestellzeilen und verarbeitet sie nacheinander; zeigt am Ende eine Sammelmeldung zu nicht übertragenen Zeilen an. |
| 3 | `ProcessLine` | Prozedur | Internal | Führt für eine einzelne Bestellzeile die Ankunfts- und Seriennummer-Abfrage aus und legt bei Erfolg die Werkstattzeile an. |
| 4 | `AddErrorLine` | Prozedur | Internal | Trägt eine nicht übertragene Zeile mit Grund in die Sammelmeldung ein. |
| 5 | `CreateWorkshopLine` | Prozedur | Internal | Legt zu einer erfolgreich erfassten Bestellzeile die zugehörige Werkstattzeile mit Status "Neu" an. |

### Seitenerweiterung: CXW Workshop Purch Order Subf (ID: 60329)

Zeigt auf der Bestellzeilen-Übersicht zusätzlich Herstellerseriennummer und "An Werkstatt gesendet" an und sperrt die Bearbeitung einer Zeile, sobald sie an die Werkstatt gesendet wurde.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterGetRecord` | Trigger | – | Sperrt die Standardfelder einer Zeile (Artikel, Menge, Preis u. a.) für die Bearbeitung, sobald diese bereits an die Werkstatt gesendet wurde. |
| 2 | `OnNewRecord` | Trigger | – | Hält eine neu angelegte Zeile bearbeitbar, bis sie an die Werkstatt gesendet wird. |

### Seite: CXW Workshop Lines (ID: 60338)

Nur-Lese-Übersicht aller Werkstattzeilen (inkl. Attribute, Status, Prüfzeitpunkt und letztem Verarbeitungsfehler) für die interne Nachverfolgung. *Keine eigenen Prozeduren oder Trigger.*

### Seite: CXW Workshop Line API (ID: 60339)

API-Schnittstelle (OData v4, `saliniLife/workshop/v1.0`), über die die externe Werkstatt offene Werkstattzeilen liest und ihr Prüfergebnis (Attribute, Echtheit, Status) zurückschreibt. Anlegen und Löschen über die API sind gesperrt.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnModifyRecord` | Trigger | – | Lehnt einen Änderungsversuch über die API ab, wenn die Werkstatt versucht, Schlüssel-, Artikel- oder Seriennummernfelder zu verändern; erlaubt bleiben nur Attribute, Echtheits-Kennzeichen und Status. |

### Seite: CXW Serial No. Input (ID: 60340)

Kleiner Eingabedialog zur Erfassung der Herstellerseriennummer, der von der Aktion "An Werkstatt senden" aufgerufen wird.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `GetSerialNo` | Prozedur | Public | Gibt die im Dialog eingegebene Herstellerseriennummer an den Aufrufer zurück. |

### Codeunit: CXW Process Workshop Lines (ID: 60331)

Als Aufgabenwarteschlangen-Eintrag lauffähige Hintergrundverarbeitung, die alle von der Werkstatt geprüften Zeilen abschließend bearbeitet.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung aller Werkstattzeilen im Status "WS geprüft". |
| 2 | `ProcessCheckedLines` | Prozedur | Internal | Ermittelt alle geprüften Werkstattzeilen und übergibt sie einzeln zur Verarbeitung. |
| 3 | `ProcessLineWithErrorHandling` | Prozedur | Internal | Verarbeitet eine Zeile fehlerisoliert: bei Fehlschlag werden der Fehlertext und der Status "Fehler" auf der Zeile vermerkt, ohne die Verarbeitung der übrigen Zeilen zu blockieren. |
| 4 | `TryProcessLine` | Prozedur | Internal | Entscheidet anhand des Echtheits-Kennzeichens, ob die Zeile als echt oder nicht echt weiterverarbeitet wird. |
| 5 | `ProcessGenuineLine` | Prozedur | Internal | Bucht bei bestätigter Echtheit ausschließlich den Wareneingang der zugehörigen Bestellung (keine Rechnung) und überträgt die gemeldeten Attribute auf den Artikel; setzt danach den Status auf "Verarbeitet" und löscht einen zuvor vermerkten Fehlertext. |
| 6 | `ProcessNonGenuineLine` | Prozedur | Internal | Storniert bei widerlegter Echtheit die zugehörige Bestellung (öffnet sie bei Bedarf zuvor wieder) und setzt den Status auf "Verarbeitet" sowie den Fehlertext zurück, bevor die Bestellung gelöscht wird, damit die Werkstattzeile als Nachweis erhalten bleibt. |
| 7 | `GetWorkshopLineAttributeValue` | Prozedur | Internal | Liest den Wert eines der zehn Attributfelder einer Werkstattzeile anhand seiner laufenden Nummer aus. |
| 8 | `GetAttributeMapping` | Prozedur | Internal | Liefert den Artikelattribut-Namen für ein Werkstattzeilen-Attribut (für Attribut 1–8 fachliche Namen wie "Dial Color"/"Case Diameter"; Attribut 9/10 weiterhin Platzhalternamen, finale Benennung offen). |
| 9 | `SetItemAttributeValue` | Prozedur | Internal | Trägt einen Attributwert als Standard-Artikelattribut auf dem Artikel ein und legt fehlende Attribute/Attributwerte automatisch an. |
| 10 | `GetOrCreateAttributeId` | Prozedur | Internal | Sucht ein Standard-Artikelattribut anhand des Namens oder legt es neu an (Typ Text). |
| 11 | `GetOrCreateAttributeValueId` | Prozedur | Internal | Sucht einen Attributwert anhand des Textes oder legt ihn neu an. |

### Permission Set: CXW Workshop All (ID: 60301)

Berechtigt zum vollständigen internen Arbeiten mit den Workshop-Tabellen, -Seiten und der Verarbeitungslogik – inklusive der für Wareneingang, Stornierung und Artikelattribute benötigten Standardtabellen (Purchase Header/Line, Item, Item Attribute, Item Attribute Value, Item Attribute Value Mapping), damit die Job-Queue-Codeunit 60331 eigenständig lauffähig ist. Deckt seit dieser Version zusätzlich den Kommissionsverkauf ab (Table 60341, Codeunit 60344/60345, Page 60342) inklusive des dafür benötigten Lesezugriffs auf Sales Invoice Header/Line und die Einkaufseinrichtung.

### Permission Set: CXW Workshop API (ID: 60302)

Eigener, schlanker Berechtigungssatz speziell für den externen Werkstatt-Benutzer – gewährt ausschließlich Lese- und Änderungsrecht auf die Tabelle "CXW Workshop Line" (kein Einfügen/Löschen, kein Zugriff auf Einkaufsbeleg oder Artikel).

---

### Kommissionsverkauf: Verzögerte EK-Faktura

Uhren, die auf Kommission angekauft wurden (Artikel-Kennzeichen "Kommissionsverkauf" aus der Dependency CHX.Base), lösen bei der VK-Rechnungsbuchung keine sofortige, sondern eine verzögerte, automatisierte EK-Faktura der zugehörigen Einkaufsbestellung aus – mit einrichtbarer Verzögerung in Tagen, Fehlerwarteschlange und manueller Nachbearbeitung fehlerhafter Fälle.

### Enum: CXW Consignment Posting Status (ID: 60343)

Definiert die drei Verarbeitungsstatus eines Kommissions-Buchungseintrags (Offen, Gebucht, Fehler). *Reine Werteliste ohne Prozeduren.*

### Tabelle: CXW Consignment Posting Entry (ID: 60341)

Ein Datensatz je gebuchter VK-Rechnungszeile eines Kommissionsartikels: hält den verkauften Artikel, die ermittelte Einkaufsbestellung, die auslösende Verkaufsrechnung samt Buchungsdatum, das Fälligkeitsdatum für die automatische EK-Faktura, den Verarbeitungsstatus sowie einen zuletzt aufgetretenen Fehlertext.

*Keine eigenen Trigger – reine Datentabelle.*

### Codeunit: CXW Consignment Sale Detection (ID: 60344)

Reagiert auf die Buchung einer Verkaufsrechnung und legt für jede Zeile eines Kommissionsartikels einen Kommissions-Buchungseintrag an, inklusive automatischer Ermittlung der zugehörigen offenen Einkaufsbestellung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterPostSalesDocCreateConsignmentEntries` | Event Subscriber | Internal | Reagiert auf jede gebuchte Verkaufsrechnung (nicht bei reiner Lieferung oder Buchungsvorschau) und legt für jede Zeile eines Kommissionsartikels einen Kommissions-Buchungseintrag an, ohne die Rechnungsbuchung selbst jemals zu gefährden. |
| 2 | `TryCreateConsignmentEntry` | Prozedur | Internal | Legt einen einzelnen Kommissions-Buchungseintrag mit Fälligkeitsdatum (Buchungsdatum plus eingerichtete Verzögerung) an und ermittelt dafür die zugehörige Einkaufsbestellung. |
| 3 | `SetPurchaseOrder` | Prozedur | Public | Ermittelt die offene, wareneingebuchte, aber noch nicht fakturierte Einkaufsbestellung zu einem Artikel; bei eindeutigem Treffer wird der Eintrag auf "Offen" gesetzt, bei keinem oder mehreren Treffern auf "Fehler" mit sprechendem Hinweistext. Wird auch von der Job-Queue-Verarbeitung (Codeunit 60345) für die "Erneut versuchen"-Funktion wiederverwendet. |

### Codeunit: CXW Post Consignment Purchases (ID: 60345)

Als Aufgabenwarteschlangen-Eintrag lauffähige Hintergrundverarbeitung, die fällige Kommissions-Buchungseinträge automatisch als Einkaufsrechnung bucht.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung aller fälligen, noch offenen Kommissions-Buchungseinträge. |
| 2 | `ProcessDueEntries` | Prozedur | Internal | Ermittelt alle Einträge mit Status "Offen" und erreichtem Fälligkeitsdatum und übergibt sie einzeln zur Verarbeitung. |
| 3 | `ProcessEntryWithErrorHandling` | Prozedur | Internal | Verarbeitet einen Eintrag fehlerisoliert: bei Erfolg wird der Status auf "Gebucht" gesetzt, bei Fehlschlag auf "Fehler" mit Fehlertext, ohne die Verarbeitung der übrigen fälligen Einträge zu blockieren. |
| 4 | `TryProcessEntry` | Prozedur | Internal | Bucht die zur Einkaufsbestellung passende Einkaufsrechnung: ermittelt bei Bedarf zunächst nochmals die passende Bestellung (für zuvor fehlgeschlagene Ermittlungen, damit "Erneut versuchen" wirksam ist), prüft, dass noch eine offene Menge zu fakturieren ist, setzt eine fehlende Kreditorenrechnungsnummer aus der Verkaufsrechnungsnummer ab, aktualisiert die zu fakturierende Menge und bucht die Rechnung ohne erneuten Wareneingang. |

### Seite: CXW Cons. Posting Entries (ID: 60342)

Übersicht aller Kommissions-Buchungseinträge inklusive der Möglichkeit, fehlerhafte Einträge nach manueller Korrektur erneut zur Verarbeitung anzustoßen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Retry` | Aktion | – | Setzt die ausgewählten Einträge mit Status "Fehler" zurück auf "Offen", damit sie beim nächsten Lauf der Hintergrundverarbeitung erneut versucht werden. |

---

### Gemeinsame HTTP-Infrastruktur (von SellWatch und Verkaufspreisverwaltung genutzt)

### Tabelle: CXW Http Call Log (ID: 60302)

Protokolliert jeden ausgehenden HTTP-Aufruf (SellWatch-Sichtbarkeitsprüfung wie Verkaufspreis-Export) mit Zeitpunkt, Ziel-URL, Erfolg, Status-Code sowie Anfrage- und Antworttext.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den aktuellen Zeitpunkt ein. |

### Seite: CXW Http Call Log (ID: 60309)

Nur-Lese-Übersicht des gemeinsamen HTTP-Aufrufprotokolls für beide Funktionsbereiche.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `DownloadRequest` | Aktion | – | Lädt den protokollierten Anfragetext als Datei herunter. |
| 2 | `DownloadResponse` | Aktion | – | Lädt den protokollierten Antworttext als Datei herunter. |

### Tabelle: CXW API Interface Setup (ID: 60317)

Zentrale Konfiguration ausgehender API-Schnittstellen: Endpunkt-URL, HTTP-Methode, SOAPAction und austauschbare Authentifizierung (kein Schlüssel, API-Schlüssel, Basis-Authentifizierung oder AWS Signature V4). Geheimnisse werden sicher im Isolated Storage abgelegt statt im Klartext-Feld.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass Endpunkt-URL und die zur gewählten Authentifizierungsart passenden Zugangsdaten vollständig hinterlegt sind. |
| 2 | `SetApiKey` | Prozedur | Public | Speichert einen API-Schlüssel sicher im Isolated Storage statt im Klartext-Tabellenfeld. |
| 3 | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand einer Anfrage aus. |
| 4 | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Baut den internen Speicherschlüssel für den API-Schlüssel dieser Schnittstelle. |
| 5 | `SetAwsSecretAccessKey` | Prozedur | Public | Speichert den AWS Secret Access Key sicher im Isolated Storage. |
| 6 | `GetAwsSecretAccessKey` | Prozedur | Public | Liest den gespeicherten AWS Secret Access Key für die Signaturberechnung aus. |
| 7 | `GetAwsSecretAccessKeyIsolatedStorageKey` | Prozedur | Internal | Baut den internen Speicherschlüssel für den AWS Secret Access Key dieser Schnittstelle. |
| 8 | `SetAwsSessionToken` | Prozedur | Public | Speichert ein temporäres AWS Session Token sicher im Isolated Storage. |
| 9 | `GetAwsSessionToken` | Prozedur | Public | Liest das gespeicherte AWS Session Token für die Signaturberechnung aus. |
| 10 | `GetAwsSessionTokenIsolatedStorageKey` | Prozedur | Internal | Baut den internen Speicherschlüssel für das AWS Session Token dieser Schnittstelle. |
| 11 | `IsApiKeyFieldRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart ein API-Schlüssel-Feld angezeigt werden muss. |
| 12 | `IsAwsFieldsRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart die AWS-Felder benötigt werden. |

### Seite: CXW API Interface Setup (ID: 60324)

Übersicht aller konfigurierten ausgehenden API-Schnittstellen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Code – OnDrillDown` | Trigger | – | Öffnet beim Klick auf den Code die Detailkarte der Schnittstelle. |

### Seite: CXW API Interface Setup Card (ID: 60325)

Detailkarte einer einzelnen API-Schnittstelle; blendet je nach gewählter Authentifizierungsart nur die dafür relevanten Felder ein.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Auth Type – OnValidate` | Trigger | – | Blendet beim Wechsel der Authentifizierungsart die passenden Eingabefelder (API-Schlüssel bzw. AWS-Felder) ein oder aus. |
| 2 | `ApiKey – OnValidate` | Trigger | – | Speichert den eingegebenen API-Schlüssel sicher und löscht ihn anschließend aus dem Eingabefeld, damit er nicht erneut angezeigt wird. |
| 3 | `AwsSecretAccessKey – OnValidate` | Trigger | – | Speichert den eingegebenen AWS Secret Access Key sicher und löscht ihn anschließend aus dem Eingabefeld. |
| 4 | `AwsSessionToken – OnValidate` | Trigger | – | Speichert das eingegebene AWS Session Token sicher und löscht es anschließend aus dem Eingabefeld. |
| 5 | `OnAfterGetCurrRecord` | Trigger | – | Legt beim Anzeigen eines Datensatzes fest, welche Authentifizierungsfelder passend zur gewählten Art sichtbar sind. |

### Enum: CXW API Auth Type (ID: 60335)

Definiert die unterstützten Authentifizierungsarten für ausgehende Schnittstellen (kein Schlüssel, API-Schlüssel, Basis-Authentifizierung, AWS Signature V4). *Reine Werteliste ohne Prozeduren.*

### Enum: CXW Http Method (ID: 60336)

Definiert die für eine Schnittstelle wählbaren HTTP-Methoden (POST, PATCH, PUT, GET, DELETE). *Reine Werteliste ohne Prozeduren.*

---

### Verkaufspreisverwaltung

### Tabelle: CXW General Sales Price Setup (ID: 60311)

Grundeinstellungen der Verkaufspreisverwaltung: Mindestmarge, Preisstaffeln, Schwellenwerte sowie Export-Schalter und ausgewählte API-Schnittstelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW API Interface Code – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese tatsächlich für Verkaufspreise konfiguriert ist. |

### Tabelle: CXW Sales Price Checking (ID: 60312)

Arbeitsbereich für die Prüfung und Freigabe neuer Verkaufspreise, bevor sie in den Standard-Verkaufspreisen übernommen werden.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Accept New Setup – OnValidate` | Trigger | – | Verlangt vor der Freigabe eine vorherige Validierung, sichert bei Freigabe den bisherigen Hinweistext und setzt bei Rücknahme der Freigabe den Validierungsstatus zurück. |
| 2 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer Prüfzeile automatisch Bearbeiter und Zeitpunkt ein. |
| 3 | `OnModify` | Trigger | – | Aktualisiert Bearbeiter und Zeitpunkt bei jeder Änderung und setzt Validierung/Freigabe zurück, sobald sich die Währung ändert. |
| 4 | `OnRename` | Trigger | – | Aktualisiert Bearbeiter und Zeitpunkt, wenn der Schlüssel einer Prüfzeile geändert wird. |

### Seite: CXW Sales Price Checking List (ID: 60322)

Arbeitsliste zur Prüfung, Validierung und Freigabe neuer Verkaufspreise inklusive CSV-Import und Export an die externe Schnittstelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FinalPrice – OnValidate` | Trigger | – | Setzt den Validierungsstatus einer Zeile zurück, sobald der Endpreis manuell geändert wird. |
| 2 | `Import CSV` | Aktion | – | Importiert eine CSV-Datei mit neuen Verkaufspreisen, sofern noch keine offenen Prüfzeilen vorhanden sind. |
| 3 | `Validate` | Aktion | – | Rundet die eingegebenen Preise und prüft alle offenen Zeilen auf Marge, Preisabweichung und Datumsplausibilität. |
| 4 | `Approve` | Aktion | – | Gibt nach Bestätigung alle validierten Zeilen zur Übernahme frei und vermerkt den freigebenden Benutzer. |
| 5 | `Add all Currencies` | Aktion | – | Legt für eine freigegebene Zeile automatisch die Preise in allen weiteren aktivierten Währungen anhand des aktuellen Wechselkurses an. |
| 6 | `Upload Sales Price` | Aktion | – | Übernimmt alle freigegebenen Preiszeilen als Standard-Verkaufspreise, archiviert sie und sendet sie einzeln an die konfigurierte externe Schnittstelle; fragt bei bereits zuvor gesendeten Zeilen nach, ob diese erneut gesendet werden sollen, und meldet am Ende, wie viele von wie vielen Zeilen erfolgreich exportiert wurden. |
| 7 | `OnOpenPage` | Trigger | – | Leert beim Öffnen die Arbeitsliste, damit nur die zuletzt importierten Zeilen bearbeitet werden. |
| 8 | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits freigegebenen Preiszeilen. |
| 9 | `fnValidate` | Prozedur | Internal | Führt die eigentliche Prüflogik aus: vergleicht mit dem bisherigen Preis, prüft die Mindestmarge und das Start-/Enddatum und trägt passende Hinweise ein. |
| 10 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Preisspanne den Nicht-Lagerpreis anhand eines hinterlegten Prozentaufschlags. |

### Seite: CXW General Sales Price Setup (ID: 60321)

Einrichtungsseite für die Grundeinstellungen der Verkaufspreisverwaltung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnOpenPage` | Trigger | – | Legt beim ersten Öffnen automatisch den einzigen Einstellungsdatensatz an, falls er noch fehlt. |

### Tabelle: CXW Sales Price Archive (ID: 60313)

Versionierte Ablage aller bereits verarbeiteten Verkaufspreis-Prüfzeilen zu Nachvollziehbarkeitszwecken.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Archiveintrags automatisch Bearbeiter und Zeitpunkt ein. |
| 2 | `OnModify` | Trigger | – | Aktualisiert Bearbeiter und Zeitpunkt bei jeder nachträglichen Änderung eines Archiveintrags. |

### Seite: CXW Sales Price Archive (ID: 60323)

Nur-Lese-Übersicht aller archivierten, historischen Verkaufspreis-Versionen.

### Codeunit: CXW Export Gateway Sales Price (ID: 60329)

Übernimmt geprüfte Verkaufspreise in die Standard-Verkaufspreise, archiviert sie und versendet sie an die konfigurierte externe Schnittstelle inklusive AWS-Signaturberechnung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `WriteBackAndArchive` | Prozedur | Public | Legt einen geprüften Preis als Standard-Verkaufspreis an oder aktualisiert ihn und archiviert die zugrunde liegende Prüfzeile. |
| 2 | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Preis und die webshop-spezifischen Zusatzfelder von der Prüfzeile auf den Verkaufspreis. |
| 3 | `ResolveUnitPriceLCY` | Prozedur | Internal | Ermittelt den Preis in Hauswährung anhand des hinterlegten oder des zuletzt bekannten Wechselkurses. |
| 4 | `ArchiveCheckingLine` | Prozedur | Internal | Legt eine neue, fortlaufend nummerierte Archivversion der Prüfzeile an. |
| 5 | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis per Reflection in JSON um, legt ihn als Ausgangsdatei ab und sendet ihn an die konfigurierte externe Schnittstelle. |
| 6 | `SendToApiInterface` | Prozedur | Internal | Baut die HTTP-Anfrage inklusive gewählter Authentifizierung auf, sendet sie an die konfigurierte Schnittstelle und protokolliert Erfolg oder Fehler. |
| 7 | `BuildSigV4Headers` | Prozedur | Internal | Berechnet die AWS-Signatur-Header für eine Anfrage nach dem AWS-Signature-V4-Verfahren. |
| 8 | `SanitizeHeaderText` | Prozedur | Internal | Entfernt aus Zugangsdaten alle Zeichen, die von .NET als ungültiger HTTP-Header abgelehnt würden (z. B. versehentlich mitkopierte Sonderzeichen). |
| 9 | `HexEncode` | Prozedur | Internal | Wandelt binäre Daten in eine hexadezimale Textdarstellung um, die für die Signaturberechnung benötigt wird. |
| 10 | `Sha256HexLower` | Prozedur | Internal | Berechnet einen SHA-256-Hash für die AWS-Signaturberechnung. |
| 11 | `HmacChainStep` | Prozedur | Internal | Führt einen einzelnen Schritt der AWS-Schlüsselableitung aus (HMAC-Verkettung). |
| 12 | `DeriveSigningKey` | Prozedur | Internal | Leitet aus dem AWS-Geheimschlüssel den tagesgültigen Signaturschlüssel ab. |
| 13 | `HmacSignatureHexLower` | Prozedur | Internal | Berechnet die endgültige AWS-Signatur einer Anfrage. |
| 14 | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt den protokollierten Anfragetext, wobei alle Zugangsdaten durch einen Platzhalter ersetzt werden. |
| 15 | `LogHttpCall` | Prozedur | Internal | Schreibt jeden Preis-Export-Aufruf (Erfolg wie Fehlschlag) in das gemeinsame HTTP-Aufrufprotokoll. |
| 16 | `AddFieldToJson` | Prozedur | Internal | Fügt ein einzelnes Datenfeld typgerecht (Zahl, Kommazahl, Ja/Nein, Text) einem JSON-Objekt hinzu. |

### Enum: CXW Sales Price Reason Code (ID: 60332)

Definiert die Gründe für eine Preisänderung (Kategorie-Management, Einkauf, Marketing). *Reine Werteliste ohne Prozeduren.*

### Enum: CXW Sales Price Export Status (ID: 60334)

Definiert den Versandstatus einer freigegebenen Preiszeile (noch nicht gesendet, gesendet, Fehler). *Reine Werteliste ohne Prozeduren.*

### Tabellenerweiterung: CXW Sales Price (ID: 60319)

Ergänzt den Standard-Verkaufspreis um webshop-spezifische Zusatzfelder: Änderungsgrund, Kommentar, internen Hinweis sowie empfohlenen Verkaufspreis, Streichpreis und Preis in Hauswährung (jeweils inkl. MwSt.).

*Keine eigenen Trigger – reine Felderweiterung.*

### Tabellenerweiterung: CXW Currency (ID: 60320)

Ergänzt die Standard-Währung um ein Kennzeichen, ob diese Währung für Webshop-Verkaufspreise aktiviert ist.

*Keine eigenen Trigger – reine Felderweiterung.*

### Seitenerweiterung: CXW Sales Prices (ID: 60326)

Zeigt auf der Standard-Verkaufspreise-Seite zusätzlich die webshop-spezifischen Felder (Änderungsgrund, empfohlener Preis, Streichpreis, Preis in Hauswährung, Hinweis, Kommentar) an.

### Seitenerweiterung: CXW Currencies (ID: 60327)

Zeigt auf der Standard-Währungsseite zusätzlich das Kennzeichen "Für Webshop-Verkaufspreise aktiviert" an.

### Xmlport: CXW Import Sales Price (ID: 60328)

Importiert eine CSV-Datei mit neuen Verkaufspreisen in die Prüfliste.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import die erste Zeile (Spaltenüberschriften). |
| 2 | `OnAfterInsertRecord` | Trigger | – | Leerer technischer Trigger ohne zusätzliche Logik. |
| 3 | `OnOpenPage` (Anfrageseite) | Trigger | – | Setzt beim Öffnen des Importdialogs die Option "Preis für alle Länder setzen" zurück auf Nein. |
| 4 | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor, indem die Kopfzeilen-Erkennung aktiviert wird. |
| 5 | `OnPostXmlPort` | Trigger | – | Zeigt nach abgeschlossenem Import eine Bestätigungsmeldung an. |

### Codeunit: CXW Import Sales Prices (ID: 60330)

Liest eine hochgeladene CSV-Datei zeilenweise ein, prüft Spaltenanzahl und -reihenfolge und übernimmt die Werte in die Standard-Verkaufspreise.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet die Verarbeitung einer hochgeladenen Preisdatei. |
| 2 | `ProcessFile` | Prozedur | Internal | Liest die Datei zeilenweise ein, prüft die Kopfzeile und übergibt jede Datenzeile zur Verarbeitung; bricht bei Fehlern mit Protokolleintrag ab. |
| 3 | `ProcessLine` | Prozedur | Internal | Wandelt eine einzelne CSV-Zeile in einen temporären Verkaufspreis-Datensatz um. |
| 4 | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Kopfzeile der Datei exakt den erwarteten Spaltennamen in der erwarteten Reihenfolge entspricht. |
| 5 | `WriteProtocol` | Prozedur | Internal | Schreibt eine Fehlermeldung zu einer Importdatei in das Importprotokoll. |
| 6 | `WriteSalesPrices` | Prozedur | Internal | Legt die eingelesenen Preise als neue Verkaufspreise an oder aktualisiert bestehende. |
| 7 | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert nach der Aktualisierung eines bestehenden Verkaufspreises, damit andere Erweiterungen darauf reagieren können. |

### Enum: CXW Taxation Type (ID: 60331)

Definiert die Besteuerungsart eines SellWatch-Angebots (Vollbesteuerung, Differenzbesteuerung, beides). *Reine Werteliste ohne Prozeduren.*

### Enum: CXW Ext Interface File Status (ID: 60333)

Definiert den Verarbeitungsstatus einer Import-/Export-Datei (neu, zu verarbeiten, in Verarbeitung, verarbeitet, Fehler, Hinweis, storniert). *Reine Werteliste ohne Prozeduren.*

### Tabelle: CXW Sales Price Outbound File (ID: 60314)

Speichert jede an die externe Schnittstelle gesendete Preisdatei inklusive Status und Antworttext.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer Ausgangsdatei automatisch den Erstellungszeitpunkt ein. |

### Tabelle: CXW Sales Price Inbound File (ID: 60315)

Speichert eine hochgeladene CSV-Preisdatei als Blob zusammen mit ihrem Verarbeitungsstatus.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Hochladen einer Datei automatisch den Zeitpunkt ein. |

### Tabelle: CXW Price Import Protokoll (ID: 60316)

Protokolliert Fehler- und Hinweismeldungen, die beim CSV-Import einer Preisdatei aufgetreten sind.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den Zeitpunkt ein. |

### Permission Set: CXWChronWSAll (ID: 60336)

Berechtigt zum vollständigen Arbeiten mit den Verkaufspreisverwaltungs-Tabellen, -Seiten, -Codeunits und dem CSV-Import sowie dem gemeinsamen HTTP-Aufrufprotokoll und der Schnittstellen-Konfiguration.

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| SellWatch als eigenständige Extension | Table 60300, 60301; TableExtension 60303, 60304; Codeunit 60305; Page 60307, 60308, 60337; PermissionSet 60300, 60310 (+ anteilig 60302/60309/60317) | Fachlich klar abgegrenzter Bereich (Uhren-Ankauf über den Partner SellWatch) mit eigenem Datenmodell und jetzt auch eigener API-Schreibschnittstelle. Bereits heute im ID-Bereich 60300–60310 (plus 60337 für die API) sauber getrennt von der Verkaufspreisverwaltung (60311–60336) — die Trennung ist im Code bereits angelegt, nur noch nicht als eigenes Deployment-Artefakt umgesetzt. |
| Workshop-Ankaufsprüfung als eigenständige Extension | Enum 60337; Table 60318; TableExtension 60321; PageExtension 60328, 60329; Page 60338, 60339, 60340; Codeunit 60331; PermissionSet 60301, 60302 | Fachlich ebenso klar abgegrenzt wie SellWatch (eigenes Datenmodell, eigene bidirektionale API, eigene Hintergrundverarbeitung) und folgt bewusst demselben Architekturmuster. Einzige Kopplung an den Rest der Extension ist die Erweiterung der Standard-Einkaufszeile/-bestellung. Vor einer Auslagerung klären: der App-ID-Bereich 60300–60349 ist nach dieser Erweiterung weitgehend ausgeschöpft (nach Kommissionsverkauf nur noch 4 freie IDs, 60346–60349), eine eigenständige Extension bräuchte einen eigenen `idRanges`-Block. |
| Kommissionsverkauf (verzögerte EK-Faktura) als eigenständige Extension | Enum 60343; Table 60341; Codeunit 60344, 60345; Page 60342; anteilig PermissionSet 60301 | Fachlich klar abgegrenzter, neuer Prozess mit eigenem Datenmodell und eigener Job-Queue-Verarbeitung. Anders als SellWatch/Workshop aber **nicht sauber isolierbar**: setzt zwingend das Artikel-Kennzeichen "Kommissionsverkauf" aus der Dependency CHX.Base voraus und reagiert auf die Standard-Verkaufsrechnungsbuchung (Subscriber auf `Sales-Post`) statt nur auf eigene Bestellobjekte – eine Auslagerung müsste diese Abhängigkeit und den Subscriber mitnehmen. |
| Gemeinsame HTTP-Infrastruktur (Aufrufprotokoll + Schnittstellen-Konfiguration) als Basis-Baustein | Table 60302 „CXW Http Call Log", Table 60317 „CXW API Interface Setup", Page 60309, 60324, 60325 | Wird von SellWatch UND Verkaufspreisverwaltung gleichermaßen genutzt (Authentifizierung, Protokollierung, Signaturberechnung). Sollte bei einer Aufteilung in zwei Extensions als dritter, gemeinsamer Basis-Baustein bestehen bleiben, statt dupliziert zu werden. |
| CSV-Import-Pfad der Verkaufspreisverwaltung | Codeunit 60330, Table 60315, 60316, Xmlport 60328 | Laut Code-Kommentaren aktuell nicht produktiv angebunden (unabhängiger Baustein). Eigenständig genug, um bei Bedarf separat weiterzuentwickeln oder zu entfernen, ohne den produktiven Preis-Freigabeprozess zu berühren. |
| SellWatch-JSON-Rückmeldungen ohne aktuellen Aufrufer | Codeunit 60305 (`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE`), Table 60301 (`CreateJsonObjectCheckOnline`) | Fertige Bausteine für eine Rückmeldung an SellWatch (Bestellstatus, Auszahlungsbetrag), aber im aktuellen Code nirgends aufgerufen. Vor einer Auslagerung klären, ob dieser Rückkanal noch gebraucht wird oder toter Code ist. |
