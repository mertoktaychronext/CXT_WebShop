# Funktionsregister – CHX.Webshop

**Version:** 1.0.0.1
**Publisher:** Salini Life
**Extension-ID:** 5df32934-5708-418c-ba16-44b30feb51f4
**Erstellt am:** 2026-08-11
**Abhängigkeiten:** keine

---

## Zusammenfassung

CHX.Webshop bündelt zwei weitgehend eigenständige Funktionsbereiche unter einem Dach: **SellWatch** wickelt den automatisierten Ankauf gebrauchter Uhren ab (eingehende Verkaufsanfragen, automatische Lieferanten- und Bestellanlage, Online-Sichtbarkeitsprüfung beim Partner SellWatch) und die **Verkaufspreisverwaltung** steuert die Pflege, Prüfung, Freigabe und den Export von Webshop-Verkaufspreisen an ein externes System. Beide Bereiche teilen sich ein gemeinsames HTTP-Aufrufprotokoll und eine gemeinsame Schnittstellen-Konfigurationstabelle mit austauschbarer Authentifizierung (API-Schlüssel, Basis-Authentifizierung oder AWS Signature V4). Die Verkaufspreisverwaltung bringt zusätzlich einen CSV-Importweg für Preisdaten sowie eine automatische Mehrwährungs-Ableitung mit.

---

## Objektübersicht

| Objekttyp | Anzahl |
|---|---|
| Codeunits | 3 |
| Tabellen | 10 |
| Tabellenerweiterungen | 4 |
| Seiten | 8 |
| Seitenerweiterungen | 2 |
| Xmlports | 1 |
| Enums | 7 |
| Permission Sets | 2 |
| **Gesamt Prozeduren/Trigger/Events** | **87** |

---

## Funktionsregister nach Objekt

### Codeunit: CXW SellWatch Mgt (ID: 60305)

Legt aus eingehenden SellWatch-Verkaufsanfragen automatisch Lieferanten und Einkaufsbestellungen an.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet den automatisierten Ablauf: prüft neue SellWatch-Verkäuferanfragen und legt daraus Lieferanten und Bestellungen an. |
| 2 | `ValidateAndCreateVendor` | Prozedur | Internal | Sucht alle noch nicht verarbeiteten SellWatch-Anfragen, legt bei Bedarf einen neuen Lieferanten mit Bankverbindung an (oder verwendet einen passenden bestehenden) und stößt die Bestellerstellung an. |
| 3 | `CreatePurchaseOrder` | Prozedur | Internal | Legt für eine SellWatch-Anfrage eine Einkaufsbestellung mit einer Position an (Artikel je nach Angebotsart: Kommission, Direktkauf oder Eintausch), gibt sie automatisch frei und markiert die Anfrage als erledigt. |
| 4 | `CreatePurchaseOrderinBV` | Prozedur | Internal | Legt nachträglich Bestellungen für Anfragen an, die zuvor für die Verarbeitung in einer anderen Gesellschaft vorgemerkt wurden. |
| 5 | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet je nach Angebotsart, ob die Bestellung direkt angelegt wird oder für eine andere Gesellschaft vorgemerkt wird. |
| 6 | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Erstellt aus einer Einkaufsbestellung eine Nachricht mit Bestellnummer und Sendungsverfolgungsnummer. Aktuell von keiner anderen Stelle im Code aufgerufen. |
| 7 | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Erstellt eine Statusmeldung für SellWatch mit Verkäufer-, Uhren- und Auszahlungsdaten sowie Link zur Online-Freigabe. Aktuell von keiner anderen Stelle im Code aufgerufen. |

---

### Codeunit: CXW Export Gateway Sales Price (ID: 60329)

Übernimmt freigegebene Verkaufspreise in die Standard-Preistabelle, archiviert sie und sendet sie an eine konfigurierbare externe Schnittstelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `WriteBackAndArchive` | Prozedur | Public | Übernimmt einen geprüften und freigegebenen Preis in die Standard-Preistabelle (neu oder aktualisiert) und legt eine Archivversion an. |
| 2 | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Preis, Streichpreis, empfohlenen Verkaufspreis, Grund und Kommentar aus der Prüfzeile in den Verkaufspreis-Datensatz. |
| 3 | `ResolveUnitPriceLCY` | Prozedur | Internal | Ermittelt den Verkaufspreis in Landeswährung über den hinterlegten oder den zuletzt gültigen Wechselkurs. |
| 4 | `ArchiveCheckingLine` | Prozedur | Internal | Legt eine neue, fortlaufend nummerierte Archivversion einer geprüften Preiszeile an, damit die Preishistorie nachvollziehbar bleibt. |
| 5 | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis in eine Nachricht um, speichert sie als Ausgangsdatei und sendet sie an das konfigurierte externe System. |
| 6 | `SendToApiInterface` | Prozedur | Internal | Baut die Anfrage an die externe Schnittstelle auf (Methode, Authentifizierung, optionale Zusatz-Header), sendet sie und protokolliert Erfolg oder Fehler. |
| 7 | `BuildSigV4Headers` | Prozedur | Internal | Berechnet die digitale Signatur (AWS Signature V4), die manche besonders abgesicherte externe Endpunkte zusätzlich zum Schlüssel verlangen. |
| 8 | `SanitizeHeaderText` | Prozedur | Internal | Entfernt unsichtbare oder ungültige Zeichen aus Zugangsdaten (z. B. durch Kopieren aus Word/E-Mail entstanden), damit die Übertragung nicht an einem Formatfehler scheitert. |
| 9 | `HexEncode` | Prozedur | Internal | Technische Hilfsfunktion für die Signaturberechnung (wandelt Binärdaten in lesbare Zeichen um). |
| 10 | `Sha256HexLower` | Prozedur | Internal | Technische Hilfsfunktion für die Signaturberechnung (Prüfsumme). |
| 11 | `HmacChainStep` | Prozedur | Internal | Technische Hilfsfunktion, ein Rechenschritt der AWS-Signaturberechnung. |
| 12 | `DeriveSigningKey` | Prozedur | Internal | Technische Hilfsfunktion, leitet aus dem AWS-Zugangsschlüssel den Signaturschlüssel ab. |
| 13 | `HmacSignatureHexLower` | Prozedur | Internal | Technische Hilfsfunktion, berechnet die endgültige AWS-Signatur. |
| 14 | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine Protokollversion der gesendeten Anfrage, in der alle Zugangsdaten durch Platzhalter ersetzt sind. |
| 15 | `LogHttpCall` | Prozedur | Internal | Schreibt Erfolg/Fehlschlag, Statuscode sowie Anfrage- und Antworttext eines Sendevorgangs ins Aufrufprotokoll. |
| 16 | `AddFieldToJson` | Prozedur | Internal | Technische Hilfsfunktion, wandelt ein einzelnes Datenfeld in das passende Nachrichtenformat um. |

---

### Codeunit: CXW Import Sales Prices (ID: 60330)

Importiert Verkaufspreise aus einer hochgeladenen CSV-Datei in die Standard-Preistabelle.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnRun` | Trigger | – | Startet den Import einer hochgeladenen Preisdatei. |
| 2 | `ProcessFile` | Prozedur | Internal | Liest eine importierte Datei zeilenweise ein, prüft die Kopfzeile auf das erwartete Format und übernimmt die Preisdaten oder meldet einen Fehler. |
| 3 | `ProcessLine` | Prozedur | Internal | Liest eine einzelne Zeile der Importdatei aus und ordnet die Werte den passenden Preisfeldern zu. |
| 4 | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Kopfzeile der Importdatei genau die erwarteten Spalten in der richtigen Reihenfolge enthält. |
| 5 | `WriteProtocol` | Prozedur | Internal | Schreibt eine Fehlermeldung zu einem Importvorgang ins Importprotokoll. |
| 6 | `WriteSalesPrices` | Prozedur | Internal | Übernimmt die eingelesenen Preisdaten in die Standard-Preistabelle (neu oder aktualisiert). |
| 7 | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert anderen Erweiterungen, dass ein Verkaufspreis per Import aktualisiert wurde. |

---

### Tabelle: CXW SellWatch Vendor Info (ID: 60300)

Eingehende SellWatch-Ankaufsanfrage (Verkäufer-, Bank-, Uhren- und Angebotsdaten). Keine eigenen Prozeduren oder Trigger.

---

### Tabelle: CXW Watch Online Approval (ID: 60301)

Ergebnis der Online-Sichtbarkeitsprüfung je Artikel/Variante beim Partner SellWatch.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Check Online" – OnValidate` | Trigger | – | Setzt automatisch das Datum der ersten Online-Schaltung, sobald eine Uhr als „online" markiert wird. |
| 2 | `ReadJSONFile` | Prozedur | Internal | Leere, ungenutzte Altfunktion ohne Wirkung. |
| 3 | `CreateJsonObjectCheckOnline` | Prozedur | Public | Erstellt eine einfache Nachricht mit der laufenden Nummer eines Datensatzes. |
| 4 | `CreateEntryInexternalFile` | Prozedur | Public | Fragt bei SellWatch ab, ob eine Uhr online gestellt werden darf, und aktualisiert den Datensatz entsprechend der Antwort. |
| 5 | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt eine Protokollversion der Anfrage, in der der echte Schlüssel durch einen Platzhalter ersetzt ist. |
| 6 | `LogHttpCall` | Prozedur | Internal | Schreibt das Ergebnis der Online-Prüfung ins Aufrufprotokoll. |
| 7 | `LogHttpCallFailureTelemetry` | Prozedur | Internal | Meldet einen fehlgeschlagenen Aufruf zusätzlich an die technische Überwachung, damit Störungen auffallen. |

---

### Tabelle: CXW Http Call Log (ID: 60302)

Gemeinsames Protokoll jedes HTTP-Aufrufs (SellWatch-Online-Check und Verkaufspreis-Export).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Vermerkt automatisch Datum und Uhrzeit beim Anlegen eines neuen Protokolleintrags. |

---

### Tabelle: CXW General Sales Price Setup (ID: 60311)

Grundeinstellungen der Verkaufspreisverwaltung (Mindestmarge, Schwellenwerte, Export-Schalter, Schnittstellenauswahl).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW API Interface Code" – OnValidate` | Trigger | – | Prüft beim Auswählen einer Schnittstelle, dass diese tatsächlich für den Versand von Verkaufspreisen vorgesehen ist. |

---

### Tabelle: CXW Sales Price Checking (ID: 60312)

Zwischenablage für Import, Prüfung und Freigabe von Verkaufspreisen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Vermerkt automatisch, wann und von wem eine Prüfzeile angelegt wurde. |
| 2 | `OnModify` | Trigger | – | Vermerkt automatisch die letzte Änderung; setzt bei Währungswechsel die Freigabe und etwaige Anmerkungen zurück. |
| 3 | `OnRename` | Trigger | – | Vermerkt automatisch, wann und von wem eine Prüfzeile umbenannt wurde. |
| 4 | `"CXW Accept New Setup" – OnValidate` | Trigger | – | Verhindert die Freigabe einer noch nicht validierten Preiszeile und sichert eine vorhandene Anmerkung beim Freigeben. |

---

### Tabelle: CXW Sales Price Archive (ID: 60313)

Historie freigegebener Verkaufspreise, versioniert je Artikel/Währung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Vermerkt automatisch, wann und von wem ein Archiveintrag angelegt wurde. |
| 2 | `OnModify` | Trigger | – | Vermerkt automatisch, wann und von wem ein Archiveintrag zuletzt geändert wurde. |

---

### Tabelle: CXW Sales Price Outbound File (ID: 60314)

Gesendete Nutzdaten mit Versandstatus und Antworttext, zur Fehleranalyse fehlgeschlagener Übertragungen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Vermerkt automatisch den Anlagezeitpunkt einer ausgehenden Datei. |

---

### Tabelle: CXW Sales Price Inbound File (ID: 60315)

Für den automatisierten CSV-Dateiimport (nicht produktiv angebunden).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Vermerkt automatisch den Anlagezeitpunkt einer eingehenden Datei. |

---

### Tabelle: CXW Price Import Protocol (ID: 60316)

Fehlerprotokoll zum automatisierten Preisimport.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnInsert` | Trigger | – | Vermerkt automatisch den Anlagezeitpunkt eines Protokolleintrags. |

---

### Tabelle: CXW API Interface Setup (ID: 60317)

Endpunkt-URL, Authentifizierungsart und sicher gespeicherte Zugangsdaten je externer Schnittstelle (gemeinsam genutzt von SellWatch und Verkaufspreisverwaltung).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Active" – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass Endpunkt-URL und alle für die gewählte Authentifizierungsart nötigen Zugangsdaten vollständig hinterlegt sind. |
| 2 | `SetApiKey` / `GetApiKey` | Prozedur | Public | Speichert bzw. liest den allgemeinen API-Schlüssel sicher und verschlüsselt. |
| 3 | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Technische Hilfsfunktion (interner Speicherschlüssel). |
| 4 | `SetAwsSecretAccessKey` / `GetAwsSecretAccessKey` | Prozedur | Public | Speichert bzw. liest den geheimen AWS-Zugriffsschlüssel sicher und verschlüsselt. |
| 5 | `GetAwsSecretAccessKeyIsolatedStorageKey` | Prozedur | Internal | Technische Hilfsfunktion (interner Speicherschlüssel). |
| 6 | `SetAwsSessionToken` / `GetAwsSessionToken` | Prozedur | Public | Speichert bzw. liest das temporäre AWS-Sitzungstoken sicher und verschlüsselt. |
| 7 | `GetAwsSessionTokenIsolatedStorageKey` | Prozedur | Internal | Technische Hilfsfunktion (interner Speicherschlüssel). |
| 8 | `IsApiKeyFieldRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart ein API-Schlüssel benötigt wird. |
| 9 | `IsAwsFieldsRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart die AWS-spezifischen Felder benötigt werden. |

---

### Tabellenerweiterungen

| Objekt | ID | Erweitert | Zweck | Eigene Prozeduren |
|---|---|---|---|---|
| CXW SW Purchase Line | 60303 | Purchase Line | Kennzeichnet eine Einkaufszeile als „gebrauchte Ware" (SellWatch-Ankauf). | keine |
| CXW SW Purchase Header | 60304 | Purchase Header | Trägt die Sendungsverfolgungsnummer einer SellWatch-Bestellung. | keine |
| CXW Sales Price | 60319 | Sales Price | Zusätzliche Webshop-Felder am Standard-Verkaufspreis (Grund, Kommentar, Streichpreis, empfohlener Preis, Preis in Landeswährung). | keine |
| CXWCurrency | 60320 | Currency | Kennzeichnet, ob eine Währung für den Webshop-Preisexport aktiviert ist. | keine |

---

### Seite: CXW SellWatch-Overview (ID: 60307)

Nur-Lese-Übersicht aller eingehenden SellWatch-Ankaufsanfragen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `ShowDocument` | Aktion | – | Öffnet die zur Anfrage gehörende Einkaufsbestellung. |
| 2 | `OnOpenPage` | Trigger | – | Zeigt beim Öffnen nur Anfragen mit einer gültigen SellWatch-Referenznummer. |

---

### Seite: CXW SellWatch info (ID: 60308)

Reine Anzeige-Kachel mit Uhrendetails (kein eigenes Verhalten).

---

### Seite: CXW Http Call Log (ID: 60309)

Nur-Lese-Übersicht des gemeinsamen HTTP-Aufrufprotokolls.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `DownloadRequest` | Aktion | – | Lädt den protokollierten Anfragetext als Datei herunter. |
| 2 | `DownloadResponse` | Aktion | – | Lädt den protokollierten Antworttext als Datei herunter. |

---

### Seite: CXW General Sales Price Setup (ID: 60321)

Grundeinstellungen der Verkaufspreisverwaltung.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `APIInterfaceSetup` | Aktion | – | Öffnet die Verwaltung der externen Schnittstellen. |
| 2 | `OnOpenPage` | Trigger | – | Legt beim ersten Öffnen automatisch den (einzigen) Einstellungsdatensatz an. |

---

### Seite: CXW Sales Price Checking List (ID: 60322)

Arbeitsliste für Import, Prüfung, Freigabe und Export von Verkaufspreisen.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `FinalPrice – OnValidate` | Trigger | – | Setzt die Freigabe zurück, sobald der Verkaufspreis geändert wird. |
| 2 | `GeneralSalesPriceSetup` | Aktion | – | Öffnet die Grundeinstellungen. |
| 3 | `SalesPriceArchiveNav` | Aktion | – | Öffnet die Preishistorie. |
| 4 | `Import CSV` | Aktion | – | Startet den Import einer Preisdatei, nachdem geprüft wurde, dass die Grundeinstellungen vollständig sind und keine offene Prüfliste existiert. |
| 5 | `Validate` | Aktion | – | Rundet die eingegebenen Preise und prüft jede Zeile automatisch auf Auffälligkeiten (z. B. Preis unter Mindestmarge, große Preisänderung, unplausible Zeiträume). |
| 6 | `Approve` | Aktion | – | Gibt alle geprüften und validierten Preiszeilen nach Bestätigung durch den Benutzer zur Übernahme frei. |
| 7 | `Add all Currencies` | Aktion | – | Legt für jede aktivierte Fremdwährung automatisch eine umgerechnete Preiszeile an. |
| 8 | `Upload Sales Price` | Aktion | – | Übernimmt alle freigegebenen Preiszeilen in die Standard-Preistabelle und sendet sie an die externe Schnittstelle; fragt nach, ob bereits gesendete Zeilen erneut gesendet werden sollen. |
| 9 | `OnOpenPage` | Trigger | – | Leert beim Öffnen die Arbeitsliste (reine Arbeitsansicht ohne dauerhafte Datenspeicherung). |
| 10 | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits freigegebenen Preiszeilen. |
| 11 | `fnValidate` | Prozedur | Internal | Prüft jede offene Preiszeile automatisch auf Auffälligkeiten und markiert sie als validiert. |
| 12 | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für Artikel ohne Lagerbestand einen Nichtlagerpreis anhand eines Aufschlags, abhängig vom Lagerpreis-Bereich. |

---

### Seite: CXW Sales Price Archive (ID: 60323)

Nur-Lese-Übersicht der Preishistorie. Keine Aktionen oder Trigger mit eigener Logik.

---

### Seite: CXW API Interface Setup (ID: 60324)

Übersichtsliste aller externen Schnittstellen (Code, Bezeichnung, Endpunkt, Authentifizierungsart, Aktiv-Status).

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Code" – OnDrillDown` | Trigger | – | Öffnet die Detailkarte der ausgewählten Schnittstelle. |
| 2 | `EditDetails` | Aktion | – | Öffnet die Detailkarte der aktuellen Schnittstelle. |

---

### Seite: CXW API Interface Setup Card (ID: 60325)

Detailkarte einer einzelnen Schnittstelle; zeigt nur die zur gewählten Authentifizierungsart passenden Felder.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `"CXW Auth Type" – OnValidate` | Trigger | – | Blendet beim Wechsel der Authentifizierungsart sofort die passenden Felder ein bzw. aus, ohne dass gespeichert werden muss. |
| 2 | `ApiKey – OnValidate` | Trigger | – | Speichert den eingegebenen API-Schlüssel sicher und verschlüsselt. |
| 3 | `AwsSecretAccessKey – OnValidate` | Trigger | – | Speichert den eingegebenen geheimen AWS-Zugriffsschlüssel sicher und verschlüsselt. |
| 4 | `AwsSessionToken – OnValidate` | Trigger | – | Speichert das eingegebene AWS-Sitzungstoken sicher und verschlüsselt. |
| 5 | `OnAfterGetCurrRecord` | Trigger | – | Blendet beim Öffnen bzw. Wechseln einer Schnittstelle die zur gewählten Authentifizierungsart passenden Felder ein bzw. aus. |

---

### Seitenerweiterungen

| Objekt | ID | Erweitert | Zweck | Eigene Logik |
|---|---|---|---|---|
| CXW Sales Prices | 60326 | Sales Prices | Zeigt die zusätzlichen Webshop-Felder (Grund, Preise, Kommentar) auf der Standard-Verkaufspreisseite an. | keine |
| CXWCurrencies | 60327 | Currencies | Zeigt das Aktivierungs-Kennzeichen für den Webshop-Preisexport auf der Standard-Währungsseite an. | keine |

---

### Xmlport: CXW Import Sales Price (ID: 60328)

Importiert Verkaufspreise aus einer XML-/Textdatei in die Prüfliste.

| Nr. | Prozedur / Trigger / Event | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|
| 1 | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import automatisch die Kopfzeile der Datei. |
| 2 | `OnAfterInsertRecord` | Trigger | – | Ungenutzt, ohne zusätzliche Wirkung. |
| 3 | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor (merkt sich, dass die nächste Zeile die Kopfzeile ist). |
| 4 | `OnPostXmlPort` | Trigger | – | Zeigt nach Abschluss des Imports eine Bestätigungsmeldung. |
| 5 | `requestpage – OnOpenPage` | Trigger | – | Setzt beim Öffnen des Importdialogs eine interne Option zurück. |

---

### Enums (reine Werte, keine Prozeduren)

| Objekt | ID | Werte | Zweck |
|---|---|---|---|
| CXW SW Order Status | 60306 | 7 Werte | Status einer SellWatch-Statusmeldung (z. B. „Watch Arrived", „Watch is Sold"). |
| CXW Taxation Type | 60331 | 4 Werte | Besteuerungsart (Voll-/Differenzbesteuerung). Aktuell nur informativ. |
| CXW Sales Price Reason Code | 60332 | 3 Werte | Grund für eine Preisänderung (CatMan, Purchasing, Marketing). |
| CXW Ext Interface File Status | 60333 | 7 Werte | Status einer Import-/Export-Datei. |
| CXW Sales Price Export Status | 60334 | 3 Werte | Versandstatus einer Preiszeile (Nicht gesendet/Gesendet/Fehler). |
| CXW API Auth Type | 60335 | 4 Werte | Authentifizierungsart einer externen Schnittstelle (Keine/API-Schlüssel/Basis-Auth/AWS Signature V4). |
| CXW Http Method | 60336 | 5 Werte | HTTP-Methode einer externen Schnittstelle (POST/PATCH/PUT/GET/DELETE). |

---

### Permission Sets (keine Prozeduren)

| Objekt | ID | Deckt ab |
|---|---|---|
| CXWSWChronWSAll | 60310 | SellWatch-Tabellen/-Seiten/-Codeunit sowie das gemeinsame Aufrufprotokoll. |
| CXWChronWSAll | 60336 | Verkaufspreisverwaltungs-Tabellen/-Seiten/-Codeunits/-Xmlport sowie das gemeinsame Aufrufprotokoll. |

---

## Auslagerungs-Kandidaten

| Kandidat | Objekte | Begründung |
|---|---|---|
| SellWatch als eigenständige Extension | Table 60300, 60301; TableExtension 60303, 60304; Codeunit 60305; Page 60307, 60308 (+ anteilig 60302/60309/60317) | Fachlich klar abgegrenzter Bereich (Uhren-Ankauf über den Partner SellWatch) mit eigenem Datenmodell. Bereits heute im ID-Bereich 60300–60310 sauber getrennt von der Verkaufspreisverwaltung (60311–60336) — die Trennung ist im Code bereits angelegt, nur noch nicht als eigenes Deployment-Artefakt umgesetzt. |
| Gemeinsame HTTP-Infrastruktur (Aufrufprotokoll + Schnittstellen-Konfiguration) als Basis-Baustein | Table 60302 „CXW Http Call Log", Table 60317 „CXW API Interface Setup", Page 60309, 60324, 60325 | Wird von SellWatch UND Verkaufspreisverwaltung gleichermaßen genutzt (Authentifizierung, Protokollierung, Signaturberechnung). Sollte bei einer Aufteilung in zwei Extensions als dritter, gemeinsamer Basis-Baustein bestehen bleiben, statt dupliziert zu werden. |
| CSV-Import-Pfad der Verkaufspreisverwaltung | Codeunit 60330, Table 60315, 60316, Xmlport 60328 | Laut Code-Kommentaren aktuell nicht produktiv angebunden (unabhängiger Baustein). Eigenständig genug, um bei Bedarf separat weiterzuentwickeln oder zu entfernen, ohne den produktiven Preis-Freigabeprozess zu berühren. |

**Hinweis:** Zwei JSON-Aufbaufunktionen in Codeunit 60305 (`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE`) sowie die Online-Check-Funktion in Table 60301 (`CreateEntryInexternalFile`, wird aktuell nirgends automatisch aufgerufen) wirken wie vorbereitete, aber noch nicht angebundene Rückmeldungen an SellWatch — vor einer Auslagerung sollte geklärt werden, ob diese noch benötigt werden.
