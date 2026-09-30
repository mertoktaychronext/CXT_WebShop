# Funktionsregister – CHX.Webshop

**Version:** 27.0.0.10
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-11, vollständig neu erstellt am 2026-08-12, aktualisiert am 2026-08-12 (Workshop-Ankaufsprüfung ergänzt, SellWatch-Artikelanlage auf Item-Template umgestellt), aktualisiert am 2026-08-13 (Workshop-Ankaufsprüfung: Status "Fehler" und Feld "Letzter Fehler" ergänzt), vollständig gegengeprüft am 2026-08-13 (alle 50 AL-Dateien erneut gegen den Code geprüft; fehlende Aktion "Upload Sales Price" auf Seite 60322 ergänzt, sonst keine Abweichungen gefunden), aktualisiert am 2026-08-13 (Workshop-Ankaufsprüfung: Attribut 1–8 fachlich benannt statt Platzhalter), erneut gegengeprüft am 2026-08-13 (nur AL-Bezeichner der Felder 11–18 auf Tabelle 60318 umbenannt [z. B. "CXW Attribute 1" → "CXW Dial Color"], Captions unverändert; Verweise in Codeunit 60331, Seite 60338 und Seite 60339 gegen den aktuellen Code geprüft – Beschreibungen weiterhin korrekt, keine Änderung nötig), aktualisiert am 2026-08-14 (Kommissionsverkauf: verzögerte EK-Faktura ergänzt – neue Tabelle 60341, Enum 60343, Seite 60342, Codeunit 60344/60345; Permission Set 60301 erweitert; außerdem den seit Version 27.0.1.1 bereits real existierenden Bereich TableExtension 60322/PageExtension 60330 "CXW SW Purchases Setup" nachträglich erfasst und dabei die Objektzählung korrigiert [Tabellenerweiterungen und Seitenerweiterungen waren zuvor je um 1 zu niedrig]), vollständig gegengeprüft am 2026-09-02 (alle 57 AL-Objekte erneut Zeile für Zeile gegen den aktuellen Code abgeglichen – keine strukturellen Abweichungen; `CreateSellWatchItem` in Codeunit 60305 präzisiert: die Artikelvorlage wird jetzt aus dem Feld "SellWatch Item Template" der Einkaufseinrichtung gelesen, nicht mehr fest als erste vorhandene Vorlage; Version auf 27.0.0.2 nachgezogen), aktualisiert am 2026-09-23 (Verkaufspreisverwaltung: Aktion "Add all Currencies" durch "Add all Countries" ersetzt, neue Prozeduren `fnAddAllCountries`/`CreateCountryLine` auf Page 60322, Tabellen-/Seitenerweiterung 60320/60327 auf Währung entfernt und durch 60346/60347 auf Land/Region ersetzt, `CreateExternalInterfaceFile` um Ländercode erweitert – 57 Objekte / 124 Funktionen), aktualisiert am 2026-09-24 (SalesPrice-Export protokolliert Übertragungen in der ChronextBC-Tabelle „Data Export Entry" statt in Tabelle 60314; neue Prozedur `CreateDataExportEntry` in Codeunit 60329; Tabelle 60314 als veraltet markiert, Version 27.0.0.3 – 57 Objekte / 125 Funktionen), vollständig gegengeprüft und nachgezogen am 2026-09-29 (alle 92 AL-Objekte gegen den Code abgeglichen; 35 bisher fehlende Objekte ergänzt – neue Bereiche **On-Demand-Beschaffung**, **Webshop-Verfügbarkeit & Lieferzeiten** und **Kennzeichen "Auftrag halten"**, dazu SalesPrice-Export über Aufgabenwarteschlange [Table/Page 60320, Codeunit 60332–60334, EnumExt 60300, PageExt 60336] und Workshop-Bestelldaten [Codeunit 60335/60336]; Codeunit 60329 und Aktion "Release Sales Prices" auf Page 60322 neu beschrieben; TableExtension 60346 entfernt [Länderfelder liegen jetzt in ChronextBC]; API-Pfad von Page 60339 korrigiert – Version 27.0.0.8, 92 Objekte / 326 Funktionen), aktualisiert am 2026-09-30 (Kennzeichen "Auftrag halten" nach CHX.Base verschoben: TableExtension 60300 und PageExtension 60337 entfernt, Feld aus PageExtension 60334 entfernt – Version 27.0.0.10, 90 Objekte / 325 Funktionen; seit 29.09. neu hinzugekommene Objekte anderer Entwickler, z. B. Codeunit 60350, sind noch nicht erfasst)
**Abhängigkeiten:** CHX.Base (27.0.3.4), ChronextBC (liefert "Data Export Entry"/"Data Export API Setup" sowie die Länderfelder für Verkaufspreise und Lieferzeiten)

---

## Zusammenfassung

CHX.Webshop bündelt vier weitgehend eigenständige Funktionsbereiche unter einem Dach: **SellWatch** wickelt den automatisierten Ankauf gebrauchter Uhren ab (eingehende Verkaufsanfragen – inzwischen auch per API von außen anlegbar –, automatische Lieferanten- und Bestellanlage, Online-Sichtbarkeitsprüfung beim Partner SellWatch), die **Workshop-Ankaufsprüfung** bindet eine externe Werkstatt in den Einkaufsprozess ein (Übergabe angekommener Bestellzeilen inkl. Herstellerseriennummer, externe Echtheits-/Attributprüfung per API, automatisierter Wareneingang bei Echtheit bzw. Stornierung bei Nicht-Echtheit), der neue Bereich **Kommissionsverkauf** bucht die Einkaufsrechnung zu auf Kommission verkaufter Ware nicht sofort, sondern verzögert und automatisiert nach der VK-Rechnungsbuchung (einrichtbare Anzahl Tage, mit Fehlerwarteschlange und manueller Nachbearbeitung), und die **Verkaufspreisverwaltung** steuert die Pflege, Prüfung, Freigabe und den Export von Webshop-Verkaufspreisen an ein externes System. Alle Bereiche teilen sich ein gemeinsames HTTP-Aufrufprotokoll bzw. folgen demselben Zwischentabellen-plus-API-Muster (bzw. beim Kommissionsverkauf einem Zwischentabellen-plus-Job-Queue-Muster); die Verkaufspreisverwaltung nutzt zusätzlich eine gemeinsame Schnittstellen-Konfigurationstabelle mit austauschbarer Authentifizierung (API-Schlüssel, Basis-Authentifizierung oder AWS Signature V4) sowie einen CSV-Importweg für Preisdaten und eine automatische Mehrwährungs-Ableitung. SellWatch besitzt seit einer früheren Erweiterung eine eigene, separat berechtigte API-Schreibschnittstelle für externe Systeme; die Workshop-Ankaufsprüfung folgt demselben Prinzip mit einer eigenen, bidirektionalen API für die externe Werkstatt. Der Kommissionsverkauf setzt auf das Artikel-Kennzeichen "Kommissionsverkauf" auf, das die Dependency CHX.Base bereitstellt.

Seit der letzten Gesamtprüfung sind zwei weitere Bereiche hinzugekommen: Die **On-Demand-Beschaffung** verknüpft Verkaufsauftragszeilen wiederbeschaffbarer Artikel mit passenden Einkaufsbestellzeilen (manuell oder durch automatische Anlage einer Bestellung) und zeigt den Beschaffungsstand direkt am Verkaufsauftrag. Der Bereich **Webshop-Verfügbarkeit & Lieferzeiten** erkennt Bestandsänderungen in den Webshop-Lagerorten automatisch, berechnet je Land Lieferzeiten und Lagerzeiten und überträgt beides über die ChronextBC-Exportinfrastruktur an den Webshop. Das zwischenzeitlich hier angelegte **Kennzeichen "Auftrag halten"** liegt seit Version 27.0.0.10 in CHX.Base. Die Verkaufspreisverwaltung versendet freigegebene Preise inzwischen nicht mehr direkt, sondern stellt sie in eine Exportwarteschlange, die eine Aufgabenwarteschlange mit automatischer Wiederholung abarbeitet.

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Codeunits | 16 |
| Tabellen | 16 |
| Tabellenerweiterungen | 7 |
| Seiten | 22 |
| Seitenerweiterungen | 12 |
| Xmlports | 1 |
| Enums | 9 |
| Enum-Erweiterungen | 1 |
| Permission Sets | 6 |
| **Gesamt Objekte** | **90** |
| **Gesamt Prozeduren/Trigger/Events** | **325** |

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

Ergänzt die Standard-Einkaufszeile um das Kennzeichen "Gebraucht", damit von SellWatch angelegte Bestellzeilen als Gebrauchtware markiert sind. Enthält außerdem die Verknüpfungsfelder "Verkaufsauftragsnr." und "Verkaufszeilennr." der On-Demand-Beschaffung (siehe dort).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnDelete` | Trigger | – | Entfernt beim Löschen einer Einkaufszeile die Verknüpfung auf der zugeordneten On-Demand-Verkaufszeile, damit diese wieder neu beschafft werden kann. |

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

Ergänzt die Standard-Einkaufseinrichtung um drei Einstellungen: die für die automatische SellWatch-Artikelanlage zu verwendende Artikelvorlage (siehe `CreateSellWatchItem` in Codeunit 60305), die Anzahl Tage, um die die automatische EK-Faktura für auf Kommission verkaufte Artikel nach der VK-Rechnungsbuchung verzögert wird (siehe Codeunit 60344/60345), sowie den Mandantennamen "Workshop Tenant", den die Werkstatt-API im Feld `tenant` mitliefert (siehe Page 60339).

*Keine eigenen Trigger – reine Felderweiterung.*

### Seitenerweiterung: CXW SW Purchases Setup (ID: 60330)

Zeigt auf der Standard-Einkaufseinrichtung die drei Einstellungsfelder (Artikelvorlage, Verzögerung Kommissionsrechnung, Workshop Tenant) an.

*Keine eigenen Trigger – reine Seitenerweiterung.*

### Enum: CXW SW Order Status (ID: 60306)

Definiert die Bestellstatus-Werte (Uhr eingetroffen, online, reserviert, verkauft, Zahlungsbestätigung, gebucht), die in der Statusrückmeldung an SellWatch verwendet werden. *Reine Werteliste ohne Prozeduren.*

### Seite: CXW SellWatch-Overview (ID: 60307)

Nur-Lese-Übersicht aller eingehenden SellWatch-Ankaufsanfragen – die einzige Anzeige-Seite für diese Daten; zeigt auch die über die API gelieferten Felder Geschlecht, Sprache und Nuvei-Kontocode.

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

Ein Datensatz je an die Werkstatt übergebener Bestellzeile: hält die Herstellerseriennummer, den Prüfstatus, das Echtheits-Kennzeichen der Werkstatt, zehn Attributfelder (die ersten acht fachlich benannt: Zifferblattfarbe, Gehäusedurchmesser, Armbandmaterial, Gehäusematerial, Werk, Geschlecht, Glas, Ausstattung; Attribut 9/10 weiterhin Platzhalter) sowie den zuletzt aufgetretenen Verarbeitungsfehler. Seit Version 27.0.0.7 zusätzlich eine Momentaufnahme der Bestell- und Uhrendaten zum Zeitpunkt der Übergabe (Kreditor, Kreditorenname, Lieferantenbestellnr., Variante, Beschreibung, Menge, EK-Preis [Caption "Direct Unit Cost"], Währung, Gebrauchtware sowie Marke, Modell, Untermodell, Referenz, Baujahr, Zustand, Box und Zertifikat aus den Artikelattributen).

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
| 5 | `CreateWorkshopLine` | Prozedur | Internal | Legt zu einer erfolgreich erfassten Bestellzeile die zugehörige Werkstattzeile mit Status "Neu" an und übernimmt dabei die Bestell- und Uhrendaten (über Codeunit 60335). |

### Seitenerweiterung: CXW Workshop Purch Order Subf (ID: 60329)

Zeigt auf der Bestellzeilen-Übersicht zusätzlich Herstellerseriennummer und "An Werkstatt gesendet" an und sperrt die Bearbeitung einer Zeile, sobald sie an die Werkstatt gesendet wurde.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterGetRecord` | Trigger | – | Sperrt die Standardfelder einer Zeile (Artikel, Menge, Preis u. a.) für die Bearbeitung, sobald diese bereits an die Werkstatt gesendet wurde. |
| 2 | `OnNewRecord` | Trigger | – | Hält eine neu angelegte Zeile bearbeitbar, bis sie an die Werkstatt gesendet wird. |

### Seite: CXW Workshop Lines (ID: 60338)

Nur-Lese-Übersicht aller Werkstattzeilen (inkl. Attribute, Status, Prüfzeitpunkt, letztem Verarbeitungsfehler sowie den an die Werkstatt übergebenen Bestell- und Uhrendaten) für die interne Nachverfolgung. *Keine eigenen Prozeduren oder Trigger.*

### Seite: CXW Workshop Line API (ID: 60339)

API-Schnittstelle (OData v4, `chronext/CXTServices/v1.0`, Entität `workshopLines`), über die die externe Werkstatt offene Werkstattzeilen samt Bestell- und Uhrendaten liest und ihr Prüfergebnis (Attribute, Echtheit, Status) zurückschreibt. Anlegen und Löschen über die API sind gesperrt.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnModifyRecord` | Trigger | – | Lehnt einen Änderungsversuch über die API ab, wenn die Werkstatt versucht, Schlüssel-, Artikel-, Seriennummern- oder Bestelldatenfelder zu verändern; erlaubt bleiben nur Attribute, Echtheits-Kennzeichen und Status. |
| 2 | `OnOpenPage` | Trigger | – | Liest beim Aufruf den Mandantennamen aus der Einkaufseinrichtung ("Workshop Tenant"), der in jeder Zeile als `tenant` mitgeliefert wird; eine Korrektur wirkt so sofort auf alle Zeilen. |
| 3 | `CheckPurchaseDataUnchanged` | Prozedur | Internal | Prüft, dass die Werkstatt keine der übergebenen Bestell- und Uhrendaten (Kreditor, Preis, Währung, Marke, Modell usw.) verändert, und bricht sonst mit einem Hinweis ab. |

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

### Codeunit: CXW Workshop Line Mgt. (ID: 60335)

Stellt beim Senden an die Werkstatt die Bestell- und Uhrendaten einer Werkstattzeile zusammen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FillPurchaseData` | Prozedur | Public | Übernimmt Kreditor, Lieferantenbestellnr., Währung, Variante, Beschreibung, Menge, EK-Preis und Gebrauchtware aus Bestellkopf und -zeile sowie Marke, Modell, Untermodell, Referenz, Baujahr, Zustand, Box und Zertifikat aus den Artikelattributen auf die Werkstattzeile; fehlende Attributwerte bleiben leer, ohne das Senden zu verhindern. |
| 2 | `GetCurrencyCode` | Prozedur | Internal | Liefert die Bestellwährung oder – bei einer Bestellung in Hauswährung – den Hauswährungscode aus der Finanzbuchhaltungs-Einrichtung. |
| 3 | `GetItemAttributeValue` | Prozedur | Internal | Liest den Text eines bestimmten Artikelattributs des Artikels; leer, wenn kein Wert zugeordnet ist. |
| 4 | `GetItemAttributeInteger` | Prozedur | Internal | Liest ein Artikelattribut als Zahl (für das Baujahr); ein nicht ganzzahliger Wert ergibt 0. |
| 5–12 | `BrandAttributeId` … `CertificateAttributeId` | Prozedur | Internal | [8 interne Hilfsfunktionen] Liefern die mit der Werkstatt vereinbarten Artikelattribut-IDs (1, 2, 3, 5, 8, 10, 11, 13) für Marke, Modell, Untermodell, Referenz, Baujahr, Zustand, Box und Zertifikat. |

### Codeunit: CXW Workshop Upgrade (ID: 60336)

Upgrade-Routine, die beim Einspielen der Version mit den neuen Bestelldaten bestehende Werkstattzeilen einmalig nachbefüllt.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnUpgradePerCompany` | Trigger | – | Führt je Mandant einmalig die Nachbefüllung aus und merkt sich per Upgrade-Kennzeichen, dass sie erledigt ist. |
| 2 | `FillPurchaseDataOnOpenLines` | Prozedur | Internal | Ergänzt bei allen noch nicht abgeschlossenen Werkstattzeilen (Status "Neu" und "WS geprüft") mit vorhandener Bestellzeile die Bestell- und Uhrendaten. |
| 3 | `GetWorkshopLinePurchaseDataTag` | Prozedur | Internal | Liefert den Namen des Upgrade-Kennzeichens für diese Nachbefüllung. |
| 4 | `RegisterPerCompanyTags` | Event Subscriber | Internal | Meldet das Upgrade-Kennzeichen beim Standard-Upgrade-Modul an, damit neue Mandanten die Nachbefüllung nicht unnötig ausführen. |

### Permission Set: CXW Workshop All (ID: 60301)

Berechtigt zum vollständigen internen Arbeiten mit den Workshop-Tabellen, -Seiten und der Verarbeitungslogik – inklusive der für Wareneingang, Stornierung und Artikelattribute benötigten Standardtabellen (Purchase Header/Line, Item, Item Attribute, Item Attribute Value, Item Attribute Value Mapping), damit die Job-Queue-Codeunit 60331 eigenständig lauffähig ist. Deckt zusätzlich den Kommissionsverkauf ab (Table 60341, Codeunit 60344/60345, Page 60342) inklusive des dafür benötigten Lesezugriffs auf Sales Invoice Header/Line und die Einkaufseinrichtung, die Tabellen der Webshop-Verfügbarkeit (60346–60348) sowie Lesezugriff auf die Finanzbuchhaltungs-Einrichtung und die Ausführung von Codeunit 60335 für "An Werkstatt senden".

### Permission Set: CXW Workshop API (ID: 60302)

Eigener, schlanker Berechtigungssatz speziell für den externen Werkstatt-Benutzer – gewährt Lese- und Änderungsrecht auf die Tabelle "CXW Workshop Line" (kein Einfügen/Löschen, kein Zugriff auf Einkaufsbeleg oder Artikel) sowie reinen Lesezugriff auf die Einkaufseinrichtung für das Feld `tenant`.

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

Grundeinstellungen der Verkaufspreisverwaltung: Mindestmarge, Preisstaffeln, Schwellenwerte, Export-Schalter und ausgewählte API-Schnittstelle sowie – seit Version 27.0.0.6 – maximale Anzahl Exportversuche (Standard 3), Archivland (Standard DE) und die Vorgabe "Preise inkl. MwSt." für neue Prüfzeilen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW API Interface Code – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese tatsächlich für Verkaufspreise konfiguriert ist. |

### Tabelle: CXW Sales Price Checking (ID: 60312)

Arbeitsbereich für die Prüfung und Freigabe neuer Verkaufspreise, bevor sie in den Standard-Verkaufspreisen übernommen werden.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Accept New Setup – OnValidate` | Trigger | – | Verlangt vor der Freigabe eine vorherige Validierung, sichert bei Freigabe den bisherigen Hinweistext und setzt bei Rücknahme der Freigabe den Validierungsstatus zurück. |
| 2 | `CXW Country Code – OnValidate` | Trigger | – | Prüft beim Eintragen eines Landes, dass es für Verkaufspreise aktiviert ist, und übernimmt dessen Verkaufspreiswährung in die Zeile. |
| 3 | `OnInsert` | Trigger | – | Trägt beim Anlegen einer Prüfzeile automatisch Bearbeiter und Zeitpunkt ein. |
| 4 | `OnModify` | Trigger | – | Aktualisiert Bearbeiter und Zeitpunkt bei jeder Änderung und setzt Validierung/Freigabe zurück, sobald sich die Währung ändert. |
| 5 | `OnRename` | Trigger | – | Aktualisiert Bearbeiter und Zeitpunkt, wenn der Schlüssel einer Prüfzeile geändert wird. |

### Seite: CXW Sales Price Checking List (ID: 60322)

Arbeitsliste zur Prüfung, Validierung und Freigabe neuer Verkaufspreise inklusive CSV-Import und Einplanung der Übertragung an die externe Schnittstelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FinalPrice – OnValidate` | Trigger | – | Setzt den Validierungsstatus einer Zeile zurück, sobald der Endpreis manuell geändert wird. |
| 2 | `Import CSV` | Aktion | – | Importiert eine CSV-Datei mit neuen Verkaufspreisen, sofern noch keine offenen Prüfzeilen vorhanden sind. |
| 3 | `Validate` | Aktion | – | Rundet die eingegebenen Preise und prüft alle offenen Zeilen auf Marge, Preisabweichung und Datumsplausibilität. |
| 4 | `Approve` | Aktion | – | Gibt nach Bestätigung alle validierten Zeilen zur Übernahme frei und vermerkt den freigebenden Benutzer. |
| 5 | `Add all Countries` | Aktion | – | Legt für jede importierte, freigegebene Basiszeile automatisch je für Verkaufspreise aktiviertem Land eine Preiszeile in der Währung dieses Landes an – bei gleicher Währung mit unverändertem Preis, sonst mit dem aktuellen Wechselkurs umgerechnet; die Länderpreise werden immer auf den nächsten vollen 10er aufgerundet. |
| 6 | `Release Sales Prices` | Aktion | – | Übernimmt alle freigegebenen Länderzeilen als Standard-Verkaufspreise und stellt jede in die Exportwarteschlange (die eigentliche Übertragung übernimmt die Aufgabenwarteschlange, Codeunit 60332); Basiszeilen ohne Land werden übersprungen. Fragt bei bereits eingeplanten oder gesendeten Zeilen nach, ob sie erneut freigegeben werden sollen, und meldet am Ende, wie viele von wie vielen Zeilen eingeplant wurden. |
| 7 | `OnOpenPage` | Trigger | – | Leert beim Öffnen die Arbeitsliste, damit nur die zuletzt importierten Zeilen bearbeitet werden. |
| 8 | `OnNewRecord` | Trigger | – | Übernimmt bei einer manuell angelegten Zeile die Vorgabe "Preise inkl. MwSt." aus der Einrichtung. |
| 9 | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits freigegebenen Preiszeilen. |
| 10 | `ReleaseLine` | Prozedur | Internal | Gibt eine einzelne Länderzeile fehlerisoliert frei (über Codeunit 60333); schlägt das fehl, wird nur diese Zeile auf Exportstatus "Fehler" gesetzt, die übrigen laufen weiter. |
| 11 | `fnValidate` | Prozedur | Internal | Führt die eigentliche Prüflogik aus: vergleicht mit dem bisherigen Preis, prüft die Mindestmarge und das Start-/Enddatum und trägt passende Hinweise ein. |
| 12 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Preisspanne den Nicht-Lagerpreis anhand eines hinterlegten Prozentaufschlags. |
| 13 | `fnAddAllCountries` | Prozedur | Internal | Durchläuft alle noch nicht verarbeiteten Basiszeilen ohne Land und alle aktivierten Länder, legt fehlende Länderzeilen an und markiert die Basiszeile als verarbeitet. |
| 14 | `CreateCountryLine` | Prozedur | Internal | Legt eine Preiszeile für ein Land an: übernimmt Preise bei gleicher Währung oder rechnet sie mit dem aktuellen Wechselkurs um, rundet sie auf den nächsten vollen 10er auf und kopiert Gültigkeit, Grund, Kommentar, "Preis inkl. MwSt." und Freigabe von der Basiszeile. |
| 15 | `RoundUpToTen` | Prozedur | Internal | Rundet einen Länderpreis immer auf den nächsten vollen 10er auf (z. B. 1.234,01 → 1.240); 0 bleibt 0. |

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

Übernimmt geprüfte Verkaufspreise in die Standard-Verkaufspreise, archiviert das Archivland, legt je Preis einen Exporteintrag an und versendet diesen später im NAV-kompatiblen JSON-Format an die konfigurierte externe Schnittstelle (inklusive AWS-Signaturberechnung).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `WriteBackAndArchive` | Prozedur | Public | Legt einen geprüften Preis als Standard-Verkaufspreis an oder aktualisiert ihn; nur die Zeile des Archivlandes (Standard DE) wird zusätzlich als neue Archivversion abgelegt. |
| 2 | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Preis und die webshop-spezifischen Zusatzfelder von der Prüfzeile auf den Verkaufspreis. |
| 3 | `ResolveUnitPriceLCY` | Prozedur | Internal | Ermittelt den Preis in Hauswährung anhand des hinterlegten oder des zuletzt bekannten Wechselkurses. |
| 4 | `ArchiveCheckingLine` | Prozedur | Internal | Legt eine neue, fortlaufend nummerierte Archivversion der Prüfzeile an. |
| 5 | `QueueExport` | Prozedur | Public | Hält den freigegebenen Preisstand als Verkaufspreis-Exportposten fest und legt dazu einen ChronextBC-Exporteintrag (Ziel `SALESPRICE`) im Status "Ausstehend (Verkaufspreis)" an, damit ihn nur der eigene Exportjob und nicht der allgemeine ChronextBC-Export verarbeitet. |
| 6 | `GetDestinationCode` | Prozedur | Public | Liefert das Exportziel `SALESPRICE`, an dem Job, Seiten und Aktionen die Verkaufspreis-Einträge erkennen. |
| 7 | `ExportEntry` | Prozedur | Public | Versendet einen Exporteintrag: baut die JSON-Daten beim ersten Versuch einmalig auf und speichert sie, sodass jeder Wiederholungsversuch exakt denselben Inhalt sendet. |
| 8 | `BuildPayload` | Prozedur | Internal | Sucht zum Exporteintrag den Preisstand, den Standard-Verkaufspreis und den Artikel zusammen; fehlt einer davon, bricht der Versuch mit einer verständlichen Meldung ab. |
| 9 | `BuildSalesPriceJson` | Prozedur | Internal | Erstellt die JSON-Nachricht mit dem mit dem Empfänger vereinbarten, festen Feldumfang (Artikel- und Variantenschlüssel mit den alten NAV-Nummern, Preise, Gültigkeit, Land, Währung, Grund, Kommentar, Einstandspreis, Gewinn in Prozent usw.). |
| 10 | `CalcProfitPercent` | Prozedur | Internal | Berechnet den Gewinn in Prozent aus dem Nettopreis in Hauswährung (Preis abzüglich MwSt.) und dem Einstandspreis des Artikels. |
| 11 | `GetReasonCodeName` | Prozedur | Internal | Liefert den Änderungsgrund als festen technischen Namen, unabhängig von der Sprache des Benutzers. |
| 12–14 | `FormatDate`, `FormatTime`, `FormatDateTime` | Prozedur | Internal | [3 interne Hilfsfunktionen] Wandeln Datum, Uhrzeit und Zeitstempel in das standardisierte Textformat der Nachricht um; leere Werte werden als leerer Text gesendet. |
| 15 | `SendToApiInterface` | Prozedur | Internal | Baut die HTTP-Anfrage inklusive gewählter Authentifizierung auf, sendet sie an die konfigurierte Schnittstelle, vermerkt das Ergebnis am Exporteintrag und protokolliert den Aufruf. |
| 16 | `SetAttemptResult` | Prozedur | Public | Zählt einen Versuch am Exporteintrag hoch und setzt ihn auf "Verarbeitet" oder auf "Fehler" mit Fehlermeldung. |
| 17 | `BuildSigV4Headers` | Prozedur | Internal | Berechnet die AWS-Signatur-Header für eine Anfrage nach dem AWS-Signature-V4-Verfahren. |
| 18 | `SanitizeHeaderText` | Prozedur | Internal | Entfernt aus Zugangsdaten alle Zeichen, die von .NET als ungültiger HTTP-Header abgelehnt würden (z. B. versehentlich mitkopierte Sonderzeichen). |
| 19 | `HexEncode` | Prozedur | Internal | Wandelt binäre Daten in eine hexadezimale Textdarstellung um, die für die Signaturberechnung benötigt wird. |
| 20 | `Sha256HexLower` | Prozedur | Internal | Berechnet einen SHA-256-Hash für die AWS-Signaturberechnung. |
| 21 | `HmacChainStep` | Prozedur | Internal | Führt einen einzelnen Schritt der AWS-Schlüsselableitung aus (HMAC-Verkettung). |
| 22 | `DeriveSigningKey` | Prozedur | Internal | Leitet aus dem AWS-Geheimschlüssel den tagesgültigen Signaturschlüssel ab. |
| 23 | `HmacSignatureHexLower` | Prozedur | Internal | Berechnet die endgültige AWS-Signatur einer Anfrage. |
| 24 | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt den protokollierten Anfragetext, wobei alle Zugangsdaten durch einen Platzhalter ersetzt werden. |
| 25 | `LogHttpCall` | Prozedur | Internal | Schreibt jeden Preis-Export-Aufruf (Erfolg wie Fehlschlag) mit Bezug auf den Exporteintrag in das gemeinsame HTTP-Aufrufprotokoll. |
| 26 | `GetExportItemAndVariantCode` | Prozedur | Internal | Ermittelt Artikelnummer und Variantencode für die Nachricht: die alte NAV-Artikelnummer bzw. den alten Variantencode des Artikels, falls gepflegt, sonst die BC-Artikelnummer bzw. den Variantencode des Preises (ohne Variante die Artikelnummer). |

### Tabelle: CXW Sales Price Export (ID: 60320)

Ein Datensatz je freigegebener Länderzeile: hält den übertragenen Preisstand (Preise, Preis in Hauswährung, Gültigkeit, Grund, Kommentar, Bemerkung, Änderungsinfo), den Bezug auf den Standard-Verkaufspreis und die Nummer des zugehörigen Exporteintrags; der Exportstatus wird live aus dem Exporteintrag gelesen. *Keine eigenen Prozeduren oder Trigger.*

### Seite: CXW Sales Price Export Entries (ID: 60320)

Nur-Lese-Übersicht aller freigegebenen Preise aller Länder mit dem Stand ihrer Übertragung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Data Export Entry No. – OnDrillDown` | Trigger | – | Öffnet per Klick auf die Nummer den zugehörigen Exporteintrag. |
| 2 | `Data Export Entry` | Aktion | – | Öffnet den Exporteintrag, der diesen Preis sendet. |
| 3 | `OnAfterGetRecord` | Trigger | – | Ermittelt für jede Zeile den Benutzernamen, der den Preis freigegeben hat. |
| 4 | `ShowDataExportEntry` | Prozedur | Internal | Öffnet die ChronextBC-Seite "Data Export Entries", gefiltert auf den Exporteintrag der aktuellen Zeile. |

### Codeunit: CXW Export Sales Price Job (ID: 60332)

Aufgabenwarteschlangen-Codeunit, die die eingeplanten Verkaufspreise versendet.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Sendet alle ausstehenden Verkaufspreis-Exporteinträge und wiederholt fehlgeschlagene, solange die maximale Anzahl Versuche nicht erreicht ist; ist der Export ausgeschaltet, warten die Einträge einfach auf den nächsten Lauf. |
| 2 | `ExportEntry` | Prozedur | Internal | Versendet einen einzelnen Eintrag fehlerisoliert: ein Fehler wird am Eintrag vermerkt, ohne den Joblauf abzubrechen, damit die Aufgabenwarteschlange weiterläuft. |

### Codeunit: CXW Release Sales Price Line (ID: 60333)

Gibt eine einzelne Länderzeile als geschlossene Einheit frei.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Schreibt den Preis in die Standard-Verkaufspreise, archiviert ihn bei Bedarf, legt Preisstand und Exporteintrag an und setzt den Exportstatus der Zeile auf "In Warteschlange"; schlägt ein Schritt fehl, wird alles für diese Zeile zurückgenommen. |

### Codeunit: CXW Export Sales Price Entry (ID: 60334)

Kapselt den Versand eines einzelnen Exporteintrags, damit ein Laufzeitfehler nur diesen Eintrag betrifft.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Übergibt den Exporteintrag an den Versand in Codeunit 60329. |

### Enum-Erweiterung: CXW Data Export Statuses (ID: 60300)

Ergänzt den ChronextBC-Exportstatus um den Wert "Ausstehend (Verkaufspreis)", damit wartende Verkaufspreise nicht vom allgemeinen ChronextBC-Export aufgegriffen werden. *Reine Werteliste ohne Prozeduren.*

### Seitenerweiterung: CXW Data Export Entries (ID: 60336)

Ergänzt die ChronextBC-Seite "Data Export Entries" um die Aktion "Verkaufspreis erneut in Warteschlange stellen".

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Requeue Sales Price` | Aktion | – | Setzt die markierten Verkaufspreis-Einträge im Status "Fehler" auf "Ausstehend" zurück (Versuchszähler und Fehlermeldung werden geleert), damit der Exportjob sie mit den gespeicherten Daten erneut sendet; meldet die Anzahl. |

### Enum: CXW Sales Price Reason Code (ID: 60332)

Definiert die Gründe für eine Preisänderung (Kategorie-Management, Einkauf, Marketing). *Reine Werteliste ohne Prozeduren.*

### Enum: CXW Sales Price Export Status (ID: 60334)

Definiert den Versandstatus einer freigegebenen Preiszeile (noch nicht gesendet, gesendet, Fehler, in Warteschlange). *Reine Werteliste ohne Prozeduren.*

### Tabellenerweiterung: CXW Sales Price (ID: 60319)

Ergänzt den Standard-Verkaufspreis um webshop-spezifische Zusatzfelder: Änderungsgrund, Kommentar, internen Hinweis sowie empfohlenen Verkaufspreis, Streichpreis und Preis in Hauswährung (jeweils inkl. MwSt.).

*Keine eigenen Trigger – reine Felderweiterung.*

### Seitenerweiterung: CXW Sales Prices (ID: 60326)

Zeigt auf der Standard-Verkaufspreise-Seite zusätzlich die webshop-spezifischen Felder (Änderungsgrund, empfohlener Preis, Streichpreis, Preis in Hauswährung, Hinweis, Kommentar) an.

### Seitenerweiterung: CXW Countries/Regions (ID: 60347)

Zeigt auf der Standard-Seite "Länder/Regionen" zusätzlich die Kennzeichen "Für Webshop-Verkaufspreise aktiviert" und "Webshop-Lieferzeit aktiv" sowie die Verkaufspreis-Währung an. Die Felder selbst liegen seit Version 27.0.0.4 in der Abhängigkeit ChronextBC (vorher TableExtension 60346/60347 dieser App); die früher gepflegten Werte wurden dabei nicht übernommen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Refresh Webshop Delivery Times` | Aktion | – | Berechnet für das gewählte, für Webshop-Lieferzeiten aktivierte Land die aktuellen Liefer- und Lagerzeiten aller Artikel und Varianten neu (siehe Webshop-Verfügbarkeit & Lieferzeiten). |

### Xmlport: CXW Import Sales Price (ID: 60328)

Importiert eine CSV-Datei mit neuen Verkaufspreisen in die Prüfliste.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Setzt bei jeder importierten Zeile "Preis inkl. MwSt." auf die Vorgabe aus der Einrichtung und überspringt die erste Zeile (Spaltenüberschriften). |
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

### Tabelle: CXW Sales Price Out. File (ID: 60314)

**Veraltet (seit Version 27.0.0.3 zur Entfernung vorgemerkt):** Speicherte bis Version 27.0.0.2 jede an die externe Schnittstelle gesendete Preisdatei inklusive Status und Antworttext. Wird nicht mehr beschrieben – neue Übertragungen stehen in der ChronextBC-Tabelle „Data Export Entry" (Ziel `SALESPRICE`). Bestehende Daten bleiben bis zur endgültigen Entfernung lesbar.

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

Berechtigt zum vollständigen Arbeiten mit den Verkaufspreisverwaltungs-Tabellen, -Seiten, -Codeunits und dem CSV-Import sowie dem gemeinsamen HTTP-Aufrufprotokoll und der Schnittstellen-Konfiguration; seit Version 27.0.0.6 auch mit dem Preisexport über die Aufgabenwarteschlange (Table/Page 60320, Codeunit 60332–60334) und den ChronextBC-Exporteinträgen. Der Benutzer des Aufgabenwarteschlangenpostens benötigt dieses Set.

### On-Demand-Beschaffung

Verknüpft Verkaufsauftragszeilen für wiederbeschaffbare Artikel (Artikelattribut "Wiederbeschaffbarkeit" = "ja") mit Einkaufsbestellzeilen desselben Artikels – entweder mit einer vorhandenen Bestellzeile oder durch automatische Anlage einer neuen Bestellung. Die Verknüpfung wird in beide Richtungen gespeichert und bei Löschen oder Zurücksetzen auf beiden Seiten sauber entfernt; der Beschaffungsstand (offen, freigegeben, teilweise/vollständig geliefert) ist direkt am Verkaufsauftrag sichtbar.

### Tabellenerweiterung: CXW On Demand Sales Line (ID: 60323)

Ergänzt die Standard-Verkaufszeile um die verknüpfte Einkaufsbestellnr. und Einkaufszeilennr. (Gegenstück zu den Feldern in TableExtension 60303 auf der Einkaufszeile).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnDelete` | Trigger | – | Entfernt beim Löschen einer Verkaufszeile die Verknüpfung auf der zugeordneten Einkaufszeile; die Einkaufszeile selbst bleibt bestehen. |

### Codeunit: CXW On Demand Link Mgt (ID: 60346)

Zentrale Logik der On-Demand-Beschaffung: erkennt On-Demand-Artikel und -Zeilen, verknüpft Verkaufs- und Einkaufszeilen, legt Bestellungen an und löst Verknüpfungen wieder.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `IsOnDemandItem` | Prozedur | Public | Prüft, ob ein Artikel das Artikelattribut "Wiederbeschaffbarkeit" mit dem Wert "ja" trägt. |
| 2 | `IsOnDemandSalesLine` | Prozedur | Public | Prüft, ob eine Verkaufszeile eine offene Artikelzeile eines Verkaufsauftrags für einen On-Demand-Artikel ist. |
| 3 | `SalesLineNeedsOnDemandAssignment` | Prozedur | Public | Prüft, ob eine On-Demand-Verkaufszeile noch beschafft werden muss: Auftrag nicht freigegeben und keine Reservierung vorhanden. |
| 4 | `HasReservation` | Prozedur | Public | Prüft, ob für eine Verkaufszeile bereits eine Reservierung besteht. |
| 5 | `GetPurchaseStatusText` | Prozedur | Public | Liefert den Beschaffungsstand einer verknüpften Verkaufszeile als Text: offen, freigegeben, teilweise geliefert, geliefert oder "Bestellzeile/Bestellung fehlt". |
| 6 | `LookupPurchaseLineForSalesLine` | Prozedur | Public | Öffnet eine Auswahl offener Einkaufsbestellzeilen desselben Artikels und gibt die gewählte Zeile zurück. |
| 7 | `LookupSalesLineForPurchaseLine` | Prozedur | Public | Öffnet eine Auswahl noch nicht verknüpfter On-Demand-Verkaufszeilen desselben Artikels und gibt die gewählte Zeile zurück. |
| 8 | `LinkSalesLineToPurchaseLine` | Prozedur | Public | Verknüpft eine Verkaufs- mit einer Einkaufszeile desselben Artikels; löst dabei bestehende Verknüpfungen beider Zeilen und öffnet eine freigegebene Bestellung bei Bedarf wieder. Bricht ab, wenn die Artikelnummern abweichen. |
| 9 | `ResetSalesLineLink` | Prozedur | Public | Löst die Verknüpfung einer Verkaufszeile; auf Wunsch wird die verknüpfte Einkaufszeile dabei gelöscht. |
| 10 | `ResetPurchaseLineLink` | Prozedur | Public | Löst die Verknüpfung einer Einkaufszeile auf beiden Seiten. |
| 11 | `IsOnDemandPurchaseLine` | Prozedur | Public | Prüft, ob eine Einkaufszeile eine offene Artikelzeile einer Bestellung für einen On-Demand-Artikel ist. |
| 12 | `PurchaseLineNeedsOnDemandAssignment` | Prozedur | Public | Prüft, ob eine On-Demand-Einkaufszeile noch keiner Verkaufszeile zugeordnet ist. |
| 13 | `CreatePurchaseOrderForSalesLines` | Prozedur | Public | Legt für die gewählten Verkaufszeilen eine neue Einkaufsbestellung beim angegebenen Kreditor an (je Verkaufszeile eine Bestellzeile mit offener Menge und Lagerort) und verknüpft jede neue Zeile mit ihrer Verkaufszeile. |
| 14 | `ClearLinkedPurchaseForDeletedSalesLine` | Prozedur | Public | Entfernt beim Löschen einer Verkaufszeile den Verweis auf der verknüpften Einkaufszeile. |
| 15 | `ClearLinkedSalesForDeletedPurchaseLine` | Prozedur | Public | Entfernt beim Löschen einer Einkaufszeile den Verweis auf der verknüpften Verkaufszeile. |
| 16–23 | `CreatePurchaseHeader` … `EnsurePurchaseLineDocumentOpen` | Prozedur | Internal | [8 interne Hilfsfunktionen] Legen Bestellkopf und -zeilen an, ermitteln die nächste Zeilennummer, prüfen Verkaufs- und Einkaufszeilen auf Verknüpfbarkeit (nur Auftrags-/Bestellzeilen vom Typ Artikel, On-Demand-Artikel), löschen die Verknüpfung jeweils auf einer Seite und öffnen eine freigegebene Bestellung vor einer Änderung wieder. |

### Seite: CXW On Demand Sales Lines (ID: 60341)

Arbeitsliste aller noch zu beschaffenden On-Demand-Verkaufszeilen (offen, Auftrag nicht freigegeben, ohne Reservierung) mit Beschaffungsstand.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Document No. – OnDrillDown` | Trigger | – | Öffnet per Klick den Verkaufsauftrag der Zeile. |
| 2 | `CXW Purchase Order No. – OnDrillDown` | Trigger | – | Öffnet per Klick die verknüpfte Einkaufsbestellung. |
| 3 | `Refresh` | Aktion | – | Lädt die Liste der noch zu beschaffenden On-Demand-Verkaufszeilen neu. |
| 4 | `Link Purchase Line` | Aktion | – | Verknüpft die gewählte Verkaufszeile mit einer vorhandenen Einkaufsbestellzeile desselben Artikels. |
| 5 | `Create Purchase Order` | Aktion | – | Legt für die markierten Verkaufszeilen eine neue Einkaufsbestellung beim oben gewählten Kreditor an und verknüpft die Zeilen. |
| 6 | `Show Open Purchase Lines` | Aktion | – | Öffnet die Liste offener, noch nicht zugeordneter On-Demand-Einkaufszeilen. |
| 7 | `Reset Link` | Aktion | – | Löst die Verknüpfung der markierten Verkaufszeilen; fragt nach, ob die verknüpften Einkaufszeilen ebenfalls gelöscht werden sollen. |
| 8 | `Open Sales Order` | Aktion | – | Öffnet den Verkaufsauftrag der gewählten Zeile. |
| 9 | `Open Purchase Order` | Aktion | – | Öffnet die verknüpfte Einkaufsbestellung der gewählten Zeile. |
| 10 | `OnOpenPage` | Trigger | – | Lädt beim Öffnen die aktuell zu beschaffenden Verkaufszeilen. |
| 11 | `OnAfterGetRecord` | Trigger | – | Ermittelt für jede Zeile den Beschaffungsstand. |
| 12 | `LoadLines` | Prozedur | Internal | Sammelt alle offenen Auftragszeilen, die noch On-Demand-beschafft werden müssen, in der Arbeitsliste. |
| 13–15 | `GetSelectedSalesLines`, `GetSingleSelectedSalesLine`, `SelectionContainsPurchaseLink` | Prozedur | Internal | [3 interne Hilfsfunktionen] Übernehmen die markierten Zeilen, verlangen bei Einzelaktionen genau eine Zeile und prüfen, ob die Auswahl bereits verknüpfte Zeilen enthält. |

### Seite: CXW On Demand Purch. Lookup (ID: 60343)

Auswahlliste offener Einkaufsbestellzeilen eines Artikels beim Verknüpfen einer Verkaufszeile.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterGetRecord` | Trigger | – | Zeigt je Bestellzeile den Stand an: für nicht verknüpfte Zeilen den Bestellstatus, für verknüpfte den Beschaffungsstand der zugehörigen Verkaufszeile. |

### Seite: CXW On Demand Purchase Lines (ID: 60344)

Arbeitsliste aller offenen On-Demand-Einkaufszeilen ohne zugeordnete Verkaufszeile.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Document No. – OnDrillDown` | Trigger | – | Öffnet per Klick die Einkaufsbestellung der Zeile. |
| 2 | `Refresh` | Aktion | – | Lädt die Liste der offenen, nicht zugeordneten On-Demand-Einkaufszeilen neu. |
| 3 | `Link Sales Line` | Aktion | – | Verknüpft die gewählte Einkaufszeile mit einer offenen On-Demand-Verkaufszeile desselben Artikels. |
| 4 | `Open Purchase Order` | Aktion | – | Öffnet die Einkaufsbestellung der gewählten Zeile. |
| 5 | `OnOpenPage` | Trigger | – | Lädt beim Öffnen die offenen, nicht zugeordneten Einkaufszeilen. |
| 6 | `OnAfterGetRecord` | Trigger | – | Ermittelt für jede Zeile den Bestellstatus. |
| 7 | `LoadLines` | Prozedur | Internal | Sammelt alle offenen Bestellzeilen für On-Demand-Artikel ohne Verkaufszuordnung in der Arbeitsliste. |
| 8–9 | `GetSelectedPurchaseLines`, `GetSingleSelectedPurchaseLine` | Prozedur | Internal | [2 interne Hilfsfunktionen] Übernehmen die markierten Zeilen und verlangen bei Einzelaktionen genau eine Zeile. |

### Seite: CXW On Demand Sales Lookup (ID: 60345)

Auswahlliste noch nicht verknüpfter On-Demand-Verkaufszeilen eines Artikels beim Verknüpfen einer Einkaufszeile.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnOpenPage` | Trigger | – | Lädt beim Öffnen die passenden Verkaufszeilen. |
| 2 | `SetPurchaseLineFilter` | Prozedur | Public | Schränkt die Auswahl auf den Artikel der Einkaufszeile ein, die verknüpft werden soll. |
| 3 | `GetRecord` | Prozedur | Public | Gibt die ausgewählte Verkaufszeile an den Aufrufer zurück. |
| 4 | `LoadLines` | Prozedur | Internal | Sammelt alle noch zu beschaffenden, nicht verknüpften On-Demand-Verkaufszeilen (optional nur eines Artikels). |

### Seitenerweiterung: CXW Sales Order Subform (ID: 60332)

Zeigt in den Verkaufsauftragszeilen die verknüpfte Einkaufsbestellung und den Beschaffungsstand an.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterGetRecord` | Trigger | – | Ermittelt für jede Auftragszeile den Beschaffungsstand der verknüpften Bestellzeile. |

### Seitenerweiterung: CXW Purchase Order Subform (ID: 60333)

Zeigt in den Bestellzeilen den verknüpften Verkaufsauftrag an und ergänzt Aktionen zum Verknüpfen und Lösen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `CXW Sales Order No. – OnDrillDown` | Trigger | – | Öffnet per Klick den verknüpften Verkaufsauftrag. |
| 2 | `Link Sales Line` | Aktion | – | Verknüpft die gewählte Bestellzeile mit einer offenen On-Demand-Verkaufszeile desselben Artikels. |
| 3 | `Reset On-Demand Link` | Aktion | – | Löst die Verknüpfung der markierten Bestellzeilen auf beiden Seiten. |
| 4 | `Open On-Demand Purchase Lines` | Aktion | – | Öffnet die Arbeitsliste offener On-Demand-Einkaufszeilen ohne Verkaufszuordnung. |
| 5–6 | `GetSelectedPurchaseLines`, `GetSingleSelectedPurchaseLine` | Prozedur | Internal | [2 interne Hilfsfunktionen] Übernehmen die markierten Zeilen und verlangen bei Einzelaktionen genau eine Zeile. |

### Seitenerweiterung: CXW Sales Order (ID: 60334)

Ergänzt den Verkaufsauftrag um die Aktion "On-Demand-Zeilen".

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `On Demand Lines` | Aktion | – | Öffnet die Arbeitsliste der noch zu beschaffenden On-Demand-Verkaufszeilen. |

### Seitenerweiterung: CXW Purchase Order (ID: 60335)

Ergänzt die Einkaufsbestellung um die Aktion "On-Demand-Einkaufszeilen".

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `On-Demand Purchase Lines` | Aktion | – | Öffnet die Arbeitsliste offener On-Demand-Einkaufszeilen ohne Verkaufszuordnung. |

### Permission Set: CXW On Demand All (ID: 60337)

Berechtigt zum Arbeiten mit der On-Demand-Beschaffung: Lesen der Verkaufsaufträge, Ändern der Verkaufszeilen (Verknüpfung), Anlegen und Ändern von Einkaufsbestellungen sowie Lesen von Kreditoren, Artikeln, Reservierungen und Artikelattributen; dazu die Ausführung von Codeunit 60346 und der vier On-Demand-Seiten.

### Webshop-Verfügbarkeit & Lieferzeiten

Erkennt Bestandsänderungen in den Webshop-Lagerorten (Artikelposten, Verkaufs- und Umlagerungszeilen) automatisch und sammelt sie als Verfügbarkeitsänderungsposten. Berechnet je für Webshop-Lieferzeiten aktiviertem Land die Lieferzeit (in Tagen) sowie die Lagerzeiten für Lager- und Nicht-Lagerware. Alle drei Datenarten werden über die in ChronextBC eingerichteten Schnittstellen `UPDSTOFILE`, `UPDDLT` und `UPDIN` an den Webshop übertragen – per Aufgabenwarteschlange oder manuell. Welche Lagerorte zählen, bestimmt das Kennzeichen "Hauptlagerort" am Lagerort (ersatzweise ein ChronextBC-Einrichtungswert, sonst Lagerort HL).

### Tabelle: CXW Availability Change Entry (ID: 60346)

Ein Posten je Bestandsänderung eines Artikels bzw. einer Variante in einem Webshop-Lagerort (getrennt nach Differenzbesteuerung) mit aktuell verfügbarer Menge und Exportstatus.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen den Änderungszeitpunkt ein. |

### Tabelle: CXW Availability Delivery Time (ID: 60347)

Berechnete Webshop-Lieferzeit in Tagen je Artikel/Variante und Land (−1 = derzeit nicht lieferbar) mit Exportstatus.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Trägt beim Anlegen Zeitpunkt und Benutzer ein. |
| 2 | `OnModify` | Trigger | – | Trägt bei jeder Änderung Zeitpunkt und Benutzer ein. |

### Tabelle: CXW Availability Inv. Time (ID: 60348)

Berechnete Lagerzeit in Tagen je Artikel/Variante, Land und Art (Lagerware "stock" / Nicht-Lagerware "non-stock") mit Exportstatus. *Keine eigenen Prozeduren oder Trigger.*

### Codeunit: CXW Availability Change Mgt (ID: 60348)

Erkennt Bestandsänderungen, pflegt die Verfügbarkeitsänderungsposten und berechnet Liefer- und Lagerzeiten neu.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterModifyItem` | Event Subscriber | Internal | Berechnet die Lieferzeiten eines Artikels neu, sobald sich seine zusätzliche Lieferzeit ändert. |
| 2 | `OnAfterInsertItemLedgerEntry` | Event Subscriber | Internal | Erfasst jede neue Artikelbuchung in einem Webshop-Lagerort als Verfügbarkeitsänderung. |
| 3 | `OnAfterModifySalesLine` | Event Subscriber | Internal | Erfasst Änderungen an Verkaufsauftragszeilen in Webshop-Lagerorten als Verfügbarkeitsänderung. |
| 4 | `OnAfterDeleteSalesLine` | Event Subscriber | Internal | Erfasst gelöschte Verkaufsauftragszeilen in Webshop-Lagerorten als Verfügbarkeitsänderung. |
| 5–7 | `OnAfterInsertTransferLine`, `OnAfterModifyTransferLine`, `OnAfterDeleteTransferLine` | Event Subscriber | Internal | Erfassen angelegte, geänderte und gelöschte Umlagerungszeilen von oder zu einem Webshop-Lagerort als Verfügbarkeitsänderung. |
| 8 | `QueueAvailabilityChange` | Prozedur | Internal | Legt einen neuen Verfügbarkeitsänderungsposten an oder aktualisiert einen noch nicht exportierten; macht aus einem zusammengefassten Posten einen detaillierten, sobald die zugehörige Artikelbuchung vorliegt, damit nichts doppelt gesendet wird. |
| 9 | `PrepareItemForExport` | Prozedur | Public | Bereitet einen Artikel für den vollständigen Export vor: legt je Variante Posten für normal und differenzbesteuerte Ware an, berechnet die Lieferzeiten neu und markiert alle Liefer- und Lagerzeiten zum erneuten Senden. |
| 10 | `RefreshAvailabilityChangeDetails` | Prozedur | Public | Aktualisiert an einem Posten die Differenzbesteuerung und die aktuell verfügbare Menge (offene Menge abzüglich Reservierungen, nie negativ). |
| 11 | `RefreshDeliveryTimes` | Prozedur | Public | Berechnet Liefer- und Lagerzeiten eines Artikels bzw. einer Variante für alle aktivierten Länder neu. |
| 12 | `RefreshDeliveryTimesForCountry` | Prozedur | Public | Berechnet Liefer- und Lagerzeiten aller Artikel und Varianten für ein Land neu. |
| 13 | `RefreshDeliveryTimesForActiveCountries` | Prozedur | Public | Berechnet Liefer- und Lagerzeiten für alle für Webshop-Lieferzeiten aktivierten Länder neu (Jobparameter `CALCULATE`). |
| 14–31 | `IsRelevantSalesLine` … `GetFieldRefByName` | Prozedur | Internal | [18 interne Hilfsfunktionen] Prüfen, ob eine Zeile einen Webshop-Lagerort betrifft, ermitteln die verfügbare Menge, speichern geänderte Liefer- und Lagerzeiten (nur bei tatsächlicher Änderung, dann zum Export markiert) und bestimmen die Webshop-Lagerorte über das Kennzeichen "Hauptlagerort", ersatzweise den ChronextBC-Einrichtungswert oder Lagerort HL. |

### Codeunit: CXW Availability Calculation (ID: 60349)

Berechnet Verfügbarkeit, Lieferdatum und Liefer-/Lagerzeiten eines Artikels.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `GetArticleAvailability` | Prozedur | Public | Ermittelt die Verfügbarkeit eines Artikels: Bestand in den Webshop-Lagerorten plus offene Einkaufsmengen mit gültigem Liefertermin (nur wiederbeschaffbare Artikel) und Zugänge aus Umlagerungen, abzüglich offener Verkaufs- und Umlagerungsabgänge. |
| 2 | `GetArticleAvailabilityAtLocation` | Prozedur | Public | Liefert die Verfügbarkeit nur für Webshop-Lagerorte, sonst 0. |
| 3 | `TryGetArticleDeliveryDate` | Prozedur | Public | Berechnet das Lieferdatum aus Verfügbarkeit, Standardlaufzeit (STOCK bzw. DEMAND), zusätzlicher Lieferzeit des Artikels, des Landes sowie – bei vorhandenem Bestand – des Lagerplatzes bzw. der Zone; liefert Nein, wenn der Artikel nicht lieferbar ist. |
| 4 | `TryGetArticleDeliveryDays` | Prozedur | Public | Wie das Lieferdatum, aber als Anzahl Tage ab heute. |
| 5 | `TryGetStockDeliveryDays` | Prozedur | Public | Berechnet die Lagerzeit für Lagerware (optionale STOCK-Laufzeit plus Artikel- und Landeslieferzeit). |
| 6 | `TryGetNonStockDeliveryDays` | Prozedur | Public | Berechnet die Lagerzeit für Nicht-Lagerware; nur für wiederbeschaffbare Artikel mit DEMAND-Laufzeit oder eigener Lieferzeit. |
| 7–28 | `GetInventoryAtAvailabilityLocation` … `GetFieldRefByName` | Prozedur | Internal | [22 interne Hilfsfunktionen] Ermitteln Bestand, offene Einkaufs-, Verkaufs- und Umlagerungsmengen, lesen die Laufzeiten STOCK/DEMAND aus der ChronextBC-Einrichtung, wenden Artikel-, Länder- und Lagerplatz-/Zonenlieferzeiten an und prüfen die Wiederbeschaffbarkeit über das Artikelattribut. |

### Codeunit: CXW Export Availability Change (ID: 60347)

Überträgt Verfügbarkeitsänderungen, Lieferzeiten und Lagerzeiten per HTTP an die in ChronextBC eingerichteten Webshop-Schnittstellen und hält jede Übertragung als verarbeiteten Exporteintrag fest.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `ExportOpenEntries` | Prozedur | Public | Sendet alle noch nicht exportierten Verfügbarkeitsänderungsposten. |
| 2 | `ExportItem` | Prozedur | Public | Bereitet einen Artikel vollständig vor und sendet dessen Verfügbarkeit, Lieferzeiten und Lagerzeiten; zählt erfolgreiche und fehlgeschlagene Übertragungen. |
| 3 | `ExportSelectedEntries` | Prozedur | Public | Aktualisiert die gewählten Posten (Menge, Lieferzeiten) unmittelbar vor dem Versand, sendet sie an `UPDSTOFILE` und markiert erfolgreiche als exportiert. |
| 4 | `ExportOpenDeliveryTimes` | Prozedur | Public | Sendet alle noch nicht exportierten Lieferzeiten. |
| 5 | `ExportSelectedDeliveryTimes` | Prozedur | Public | Sendet die gewählten Lieferzeiten an `UPDDLT` und markiert erfolgreiche als exportiert. |
| 6 | `ExportOpenInventoryTimes` | Prozedur | Public | Sendet alle noch nicht exportierten Lagerzeiten. |
| 7 | `ExportSelectedInventoryTimes` | Prozedur | Public | Sendet die gewählten Lagerzeiten an `UPDIN` und markiert erfolgreiche als exportiert. |
| 8–22 | `LoadDataExportApiSetup` … `LogInventoryTimeHttpCall` | Prozedur | Internal | [15 interne Hilfsfunktionen] Prüfen die Schnittstellen-Einrichtung, bauen die JSON-Nachrichten (Bestand als "full"/"diff" je Differenzbesteuerung, alte Artikel-/Variantennummern als Schlüssel), senden mit Basis-, Bearer- oder API-Schlüssel-Authentifizierung, legen verarbeitete Exporteinträge an und protokollieren jeden Aufruf ohne Zugangsdaten im HTTP-Aufrufprotokoll. |

### Codeunit: CXW Export Availability Job (ID: 60343)

Aufgabenwarteschlangen-Codeunit für die Webshop-Verfügbarkeit; der Jobparameter wählt die Aufgabe.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Sendet je nach Parameter Bestände (`UPDSTOFILE`), Lieferzeiten (`UPDDLT`), Lagerzeiten (`UPDIN`) oder alles (`ALL` bzw. leer) oder berechnet die Lieferzeiten aller aktiven Länder neu (`CALCULATE`); meldet einen Fehler, wenn Übertragungen fehlgeschlagen sind, damit der Joblauf als fehlerhaft erscheint. |

### Seite: CXWAvailabilityChange Entries (ID: 60347)

Übersicht der Verfügbarkeitsänderungsposten.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Delete Selected Entries` | Aktion | – | Löscht nach Rückfrage die markierten Posten. |
| 2 | `Export Open Entries` | Aktion | – | Sendet die markierten, noch nicht exportierten Posten an `UPDSTOFILE` und meldet Erfolge und Fehlschläge. |

### Seite: CXW Availability Delivery Time (ID: 60349)

Übersicht der berechneten Lieferzeiten je Artikel und Land.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Delete Selected Entries` | Aktion | – | Löscht nach Rückfrage die markierten Lieferzeiten. |
| 2 | `Export Open Entries` | Aktion | – | Sendet die markierten, noch nicht exportierten Lieferzeiten an `UPDDLT` und meldet Erfolge und Fehlschläge. |

### Seite: CXW Availability Inv. Times (ID: 60346)

Übersicht der berechneten Lagerzeiten je Artikel, Land und Art.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Delete Selected Entries` | Aktion | – | Löscht nach Rückfrage die markierten Lagerzeiten. |
| 2 | `Export Open Entries` | Aktion | – | Sendet die markierten, noch nicht exportierten Lagerzeiten an `UPDIN` und meldet Erfolge und Fehlschläge. |

### Seite: CXW Availability Check Dialog (ID: 60348)

Kleiner Dialog zur Eingabe von Land, Zone und Lagerplatz für die Lieferdatumsprüfung am Artikel.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1–3 | `GetCountryRegionCode`, `GetZoneCode`, `GetBinCode` | Prozedur | Public | Geben die im Dialog eingegebenen Werte an den Aufrufer zurück. |

### Seitenerweiterung: CXW Item Card (ID: 60331)

Ergänzt die Artikelkarte um den direkten Verfügbarkeitsexport und die Lieferdatumsprüfung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `Export Availability` | Aktion | – | Bereitet den Artikel samt Varianten, Liefer- und Lagerzeiten vollständig vor, sendet alles sofort und meldet Erfolge und Fehlschläge. |
| 2 | `Check Availability Date` | Aktion | – | Fragt Land, Zone und Lagerplatz ab und zeigt Verfügbarkeit und berechnetes Lieferdatum des Artikels an bzw. dass er derzeit nicht lieferbar ist. |

### Tabellenerweiterung: CXW Location Availability (ID: 60348)

Ergänzt den Lagerort um das Kennzeichen "Hauptlagerort", das festlegt, ob der Lagerort in die Webshop-Verfügbarkeit einfließt. *Keine eigenen Trigger – reine Felderweiterung.*

### Seitenerweiterung: CXW Location Card (ID: 60348)

Zeigt auf der Lagerortkarte das Kennzeichen "Hauptlagerort" an. *Keine eigenen Trigger – reine Seitenerweiterung.*

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| SellWatch als eigenständige Extension | Table 60300, 60301; TableExtension 60303, 60304; Codeunit 60305; Page 60307, 60308, 60337; PermissionSet 60300, 60310 (+ anteilig 60302/60309/60317) | Fachlich klar abgegrenzter Bereich (Uhren-Ankauf über den Partner SellWatch) mit eigenem Datenmodell und jetzt auch eigener API-Schreibschnittstelle. Bereits heute im ID-Bereich 60300–60310 (plus 60337 für die API) sauber getrennt von der Verkaufspreisverwaltung (60311–60336) — die Trennung ist im Code bereits angelegt, nur noch nicht als eigenes Deployment-Artefakt umgesetzt. |
| Workshop-Ankaufsprüfung als eigenständige Extension | Enum 60337; Table 60318; TableExtension 60321; PageExtension 60328, 60329; Page 60338, 60339, 60340; Codeunit 60331; PermissionSet 60301, 60302 | Fachlich ebenso klar abgegrenzt wie SellWatch (eigenes Datenmodell, eigene bidirektionale API, eigene Hintergrundverarbeitung) und folgt bewusst demselben Architekturmuster. Einzige Kopplung an den Rest der Extension ist die Erweiterung der Standard-Einkaufszeile/-bestellung. Seit Version 27.0.0.7 hängen zusätzlich Codeunit 60335/60336 (Bestelldaten, Upgrade) dazu. Vor einer Auslagerung klären: der App-ID-Bereich 60300–60349 ist inzwischen bei Tabellen, Codeunits und Seiten am oberen Ende vollständig belegt (u. a. 60341–60349 durch On-Demand und Verfügbarkeit), eine eigenständige Extension bräuchte einen eigenen `idRanges`-Block. |
| Kommissionsverkauf (verzögerte EK-Faktura) als eigenständige Extension | Enum 60343; Table 60341; Codeunit 60344, 60345; Page 60342; anteilig PermissionSet 60301 | Fachlich klar abgegrenzter, neuer Prozess mit eigenem Datenmodell und eigener Job-Queue-Verarbeitung. Anders als SellWatch/Workshop aber **nicht sauber isolierbar**: setzt zwingend das Artikel-Kennzeichen "Kommissionsverkauf" aus der Dependency CHX.Base voraus und reagiert auf die Standard-Verkaufsrechnungsbuchung (Subscriber auf `Sales-Post`) statt nur auf eigene Bestellobjekte – eine Auslagerung müsste diese Abhängigkeit und den Subscriber mitnehmen. |
| Webshop-Verfügbarkeit & Lieferzeiten als eigenständige Extension | Table 60346, 60347, 60348; Codeunit 60343, 60347, 60348, 60349; Page 60346–60349; PageExtension 60331, 60348; TableExtension 60348; anteilig PageExtension 60347 und PermissionSet 60301 | Mit knapp 100 Funktionen der größte Bereich der App, fachlich klar abgegrenzt (eigene Tabellen, eigener Job, eigene Schnittstellen `UPDSTOFILE`/`UPDDLT`/`UPDIN`). Hängt aber stark an ChronextBC (Exporteinstellungen, Exporteinträge, Einrichtungswerte, Länderfelder) und CHX.Base (Zusatzlieferzeiten, Differenzbesteuerung) – fachlich passt der Bereich eher **zu ChronextBC** als zu einer weiteren Einzel-Extension. Zudem ist Logik doppelt vorhanden: die Ermittlung der Webshop-Lagerorte (samt Einrichtungswert-Lesen) steht nahezu gleich in Codeunit 60348 und 60349, die Wiederbeschaffbarkeitsprüfung über das Artikelattribut in Codeunit 60349 (`IsReplenishable`) und 60346 (`IsOnDemandItem`) – vor einer Auslagerung in eine gemeinsame Hilfs-Codeunit zusammenführen. Eigene Berechtigungen fehlen: die Tabellen sind nur im Workshop-Set 60301 enthalten. |
| On-Demand-Beschaffung als eigenständige Extension | TableExtension 60323 (+ Felder in 60303); Codeunit 60346; Page 60341, 60343, 60344, 60345; PageExtension 60332, 60333, 60335 (+ Aktion in 60334); PermissionSet 60337 | Klar abgegrenzter Prozess mit eigenem Berechtigungssatz und ausschließlich öffentlichen Einstiegspunkten in Codeunit 60346 – technisch gut isolierbar. Kopplung: die Verknüpfungsfelder liegen in denselben Tabellenerweiterungen wie SellWatch-Felder (60303) und würden bei einer Auslagerung mitwandern müssen. |
| Gemeinsame HTTP-Infrastruktur (Aufrufprotokoll + Schnittstellen-Konfiguration) als Basis-Baustein | Table 60302 „CXW Http Call Log", Table 60317 „CXW API Interface Setup", Page 60309, 60324, 60325 | Wird von SellWatch UND Verkaufspreisverwaltung gleichermaßen genutzt (Authentifizierung, Protokollierung, Signaturberechnung). Sollte bei einer Aufteilung in zwei Extensions als dritter, gemeinsamer Basis-Baustein bestehen bleiben, statt dupliziert zu werden. |
| CSV-Import-Pfad der Verkaufspreisverwaltung | Codeunit 60330, Table 60315, 60316, Xmlport 60328 | Laut Code-Kommentaren aktuell nicht produktiv angebunden (unabhängiger Baustein). Eigenständig genug, um bei Bedarf separat weiterzuentwickeln oder zu entfernen, ohne den produktiven Preis-Freigabeprozess zu berühren. |
| SellWatch-JSON-Rückmeldungen ohne aktuellen Aufrufer | Codeunit 60305 (`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE`), Table 60301 (`CreateJsonObjectCheckOnline`) | Fertige Bausteine für eine Rückmeldung an SellWatch (Bestellstatus, Auszahlungsbetrag), aber im aktuellen Code nirgends aufgerufen. Vor einer Auslagerung klären, ob dieser Rückkanal noch gebraucht wird oder toter Code ist. |
