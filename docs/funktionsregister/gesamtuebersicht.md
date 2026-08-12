# Gesamtübersicht – AL Funktionsregister

**Erstellt am:** 2026-08-11 (Neuerstellung nach dem AWS-SigV4-Update und der Umstellung von Page 60324 auf bedingte Feldanzeige mit neuer Detailkarte Page 60325), vollständig neu erstellt am 2026-08-12 (SellWatch-API-Page 60337 ergänzt, vollständige Neuverifikation aller 39 AL-Objekte)
**Analysierte Projekte:** 1
**Gesamtanzahl Funktionen:** 89

---

## Projektübersicht

| Projekt | Version | Objekte | Prozeduren | Trigger | Events | Navigation/Actions | Gesamt |
|---|---|---|---|---|---|---|---|
| CHX.Webshop | 27.0.0.1 | 39 | 46 | 33 | 1 | 9 | 89 |
| **Gesamt** | – | **39** | **46** | **33** | **1** | **9** | **89** |

> Nur ein AL-Projekt vorhanden. Es bündelt zwei fachlich unabhängige Bereiche: **SellWatch** (Ankauf gebrauchter Uhren, ID-Bereich 60300–60310 plus 60337 für die neue API) und **SalesPrice/Verkaufspreisverwaltung** (ID-Bereich 60311–60336). Beide teilen sich ein gemeinsames HTTP-Aufrufprotokoll (Table 60302/Page 60309) und eine gemeinsame Schnittstellen-Konfigurationstabelle (Table 60317) mit austauschbarer Authentifizierung. Seit dem AWS-SigV4-Update unterstützt diese Konfiguration zusätzlich zu API-Schlüssel und Basis-Authentifizierung auch AWS Signature V4, und seit dem Conditional-Fields-Update zeigt eine Detailkarte (Page 60325) nur noch die zur gewählten Authentifizierungsart passenden Felder. Seit der jüngsten Erweiterung besitzt SellWatch zusätzlich eine eigene API-Schreibschnittstelle (Page 60337) mit eigenem, separatem Berechtigungssatz (PermissionSet 60300) für externe Systeme.
>
> **Hinweis zur Neuverifikation (2026-08-12):** Diese Ausgabe wurde durch eine vollständige Neuanalyse aller 39 AL-Dateien ersetzt (nicht nur fortgeschrieben). Die Gesamtzahl der Funktionen (89) weicht von der vorherigen Angabe (87, danach ad-hoc auf 91 nachgetragen) leicht ab, da Navigations-Aktionen ohne eigene `OnAction`-Logik (reine `RunObject`-Verknüpfungen, z. B. auf den Seiten 60321 und 60324) in dieser Neuverifikation konsequent nicht mitgezählt werden, da sie keine eigene Geschäftslogik enthalten.

---

## Alle Funktionen – Vollständige Tabelle

| Projekt | Objekt | Objekttyp | Funktion | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|---|---|
| CHX.Webshop | CXW Watch Online Approval | Tabelle | `CXW Check Online – OnValidate` | Trigger | – | Trägt beim Aktivieren der Online-Freigabe automatisch das heutige Datum als "Erstes Online-Datum" ein. |
| CHX.Webshop | CXW Watch Online Approval | Tabelle | `ReadJSONFile` | Prozedur | Internal | Leere Hilfsfunktion ohne aktuelle Funktion – technischer Rest aus der Migration. |
| CHX.Webshop | CXW Watch Online Approval | Tabelle | `CreateJsonObjectCheckOnline` | Prozedur | Public | Baut ein minimales JSON-Objekt mit der Eintragsnummer, aktuell ohne Aufrufer im Code. |
| CHX.Webshop | CXW Watch Online Approval | Tabelle | `CreateEntryInexternalFile` | Prozedur | Public | Fragt beim Partner SellWatch per HTTP ab, ob eine Uhr online gehen darf, und setzt je nach Antwort die Online-Freigabe oder einen Hinweistext. |
| CHX.Webshop | CXW Watch Online Approval | Tabelle | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt den protokollierten Anfragetext, wobei der API-Schlüssel durch einen Platzhalter ersetzt wird. |
| CHX.Webshop | CXW Watch Online Approval | Tabelle | `LogHttpCall` | Prozedur | Internal | Schreibt jeden Sichtbarkeits-Aufruf (Erfolg wie Fehlschlag) in das gemeinsame HTTP-Aufrufprotokoll. |
| CHX.Webshop | CXW Watch Online Approval | Tabelle | `LogHttpCallFailureTelemetry` | Prozedur | Internal | Meldet einen fehlgeschlagenen Sichtbarkeits-Aufruf zusätzlich an die technische Telemetrie. |
| CHX.Webshop | CXW SellWatch Mgt | Codeunit | `OnRun` | Trigger | – | Startet die Verarbeitung aller noch nicht angelegten SellWatch-Anfragen. |
| CHX.Webshop | CXW SellWatch Mgt | Codeunit | `ValidateAndCreateVendor` | Prozedur | Internal | Sucht für jede offene Anfrage einen passenden Lieferanten oder legt einen neuen samt Bankverbindung an. |
| CHX.Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrder` | Prozedur | Internal | Legt zu einer Anfrage eine Einkaufsbestellung an, ordnet den passenden Artikel zu und gibt die Bestellung frei. |
| CHX.Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrderinBV` | Prozedur | Internal | Verarbeitet nachträglich alle Anfragen, die für die niederländische Gesellschaft vorgemerkt wurden. |
| CHX.Webshop | CXW SellWatch Mgt | Codeunit | `CreatePurchaseOrderinGmBH` | Prozedur | Internal | Entscheidet je nach Angebotsart, ob die Bestellung direkt angelegt oder für die niederländische Gesellschaft vorgemerkt wird. |
| CHX.Webshop | CXW SellWatch Mgt | Codeunit | `CreateSourceFilePurchaseRequest` | Prozedur | Public | Baut eine JSON-Rückmeldung mit Referenznummer, Bestellnummer und Sendungsverfolgungsnummer; aktuell ohne Aufrufer. |
| CHX.Webshop | CXW SellWatch Mgt | Codeunit | `CreateSourceFileOrderStatusSE` | Prozedur | Public | Baut eine ausführliche JSON-Statusrückmeldung für eine SellWatch-Anfrage; aktuell ohne Aufrufer. |
| CHX.Webshop | CXW SellWatch-Overview | Seite | `ShowDocument` | Aktion | – | Öffnet die zur Anfrage gehörende Einkaufsbestellung. |
| CHX.Webshop | CXW SellWatch-Overview | Seite | `OnOpenPage` | Trigger | – | Zeigt beim Öffnen nur Anfragen mit gültiger SellWatch-Referenznummer. |
| CHX.Webshop | CXW SellWatch API | Seite | `OnInsertRecord` | Trigger | – | Setzt beim Anlegen über die API das Erstellt-Kennzeichen sowie Bestell- und Lieferantennummer zurück, prüft Pflichtfelder und lehnt doppelte SellWatch-Referenznummern ab. |
| CHX.Webshop | CXW SellWatch API | Seite | `OnModifyRecord` | Trigger | – | Verhindert bei Änderungen über die API, dass das Erstellt-Kennzeichen sowie Bestell- und Lieferantennummer überschrieben werden, und lehnt eine Änderung der Referenznummer auf einen bereits vergebenen Wert ab. |
| CHX.Webshop | CXW SellWatch API | Seite | `ValidateRequiredFields` | Prozedur | Internal | Stellt sicher, dass Referenznummer, Marke, Modell und Angebotspreis beim Anlegen oder Ändern über die API ausgefüllt sind. |
| CHX.Webshop | CXW SellWatch API | Seite | `CheckDuplicateSRid` | Prozedur | Internal | Lehnt eine Neuanlage oder Änderung ab, wenn bereits eine andere Anfrage mit derselben SellWatch-Referenznummer existiert. |
| CHX.Webshop | CXW Http Call Log | Tabelle | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den aktuellen Zeitpunkt ein. |
| CHX.Webshop | CXW Http Call Log | Seite | `DownloadRequest` | Aktion | – | Lädt den protokollierten Anfragetext als Datei herunter. |
| CHX.Webshop | CXW Http Call Log | Seite | `DownloadResponse` | Aktion | – | Lädt den protokollierten Antworttext als Datei herunter. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `CXW Active – OnValidate` | Trigger | – | Prüft beim Aktivieren einer Schnittstelle, dass Endpunkt-URL und passende Zugangsdaten vollständig hinterlegt sind. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `SetApiKey` | Prozedur | Public | Speichert einen API-Schlüssel sicher im Isolated Storage. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `GetApiKey` | Prozedur | Public | Liest den gespeicherten API-Schlüssel für den Versand einer Anfrage aus. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `GetApiKeyIsolatedStorageKey` | Prozedur | Internal | Baut den internen Speicherschlüssel für den API-Schlüssel dieser Schnittstelle. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `SetAwsSecretAccessKey` | Prozedur | Public | Speichert den AWS Secret Access Key sicher im Isolated Storage. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `GetAwsSecretAccessKey` | Prozedur | Public | Liest den gespeicherten AWS Secret Access Key für die Signaturberechnung aus. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `GetAwsSecretAccessKeyIsolatedStorageKey` | Prozedur | Internal | Baut den internen Speicherschlüssel für den AWS Secret Access Key. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `SetAwsSessionToken` | Prozedur | Public | Speichert ein temporäres AWS Session Token sicher im Isolated Storage. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `GetAwsSessionToken` | Prozedur | Public | Liest das gespeicherte AWS Session Token für die Signaturberechnung aus. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `GetAwsSessionTokenIsolatedStorageKey` | Prozedur | Internal | Baut den internen Speicherschlüssel für das AWS Session Token. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `IsApiKeyFieldRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart ein API-Schlüssel-Feld angezeigt werden muss. |
| CHX.Webshop | CXW API Interface Setup | Tabelle | `IsAwsFieldsRelevant` | Prozedur | Public | Ermittelt, ob für die gewählte Authentifizierungsart die AWS-Felder benötigt werden. |
| CHX.Webshop | CXW API Interface Setup | Seite | `CXW Code – OnDrillDown` | Trigger | – | Öffnet beim Klick auf den Code die Detailkarte der Schnittstelle. |
| CHX.Webshop | CXW API Interface Setup Card | Seite | `CXW Auth Type – OnValidate` | Trigger | – | Blendet beim Wechsel der Authentifizierungsart die passenden Eingabefelder ein oder aus. |
| CHX.Webshop | CXW API Interface Setup Card | Seite | `ApiKey – OnValidate` | Trigger | – | Speichert den eingegebenen API-Schlüssel sicher und löscht ihn aus dem Eingabefeld. |
| CHX.Webshop | CXW API Interface Setup Card | Seite | `AwsSecretAccessKey – OnValidate` | Trigger | – | Speichert den eingegebenen AWS Secret Access Key sicher und löscht ihn aus dem Eingabefeld. |
| CHX.Webshop | CXW API Interface Setup Card | Seite | `AwsSessionToken – OnValidate` | Trigger | – | Speichert das eingegebene AWS Session Token sicher und löscht es aus dem Eingabefeld. |
| CHX.Webshop | CXW API Interface Setup Card | Seite | `OnAfterGetCurrRecord` | Trigger | – | Legt beim Anzeigen eines Datensatzes fest, welche Authentifizierungsfelder sichtbar sind. |
| CHX.Webshop | CXW General Sales Price Setup | Tabelle | `CXW API Interface Code – OnValidate` | Trigger | – | Prüft beim Auswählen einer API-Schnittstelle, dass diese für Verkaufspreise konfiguriert ist. |
| CHX.Webshop | CXW General Sales Price Setup | Seite | `OnOpenPage` | Trigger | – | Legt beim ersten Öffnen automatisch den einzigen Einstellungsdatensatz an, falls er fehlt. |
| CHX.Webshop | CXW Sales Price Checking | Tabelle | `CXW Accept New Setup – OnValidate` | Trigger | – | Verlangt vor der Freigabe eine vorherige Validierung und sichert bzw. löscht den Hinweistext passend zum Freigabestatus. |
| CHX.Webshop | CXW Sales Price Checking | Tabelle | `OnInsert` | Trigger | – | Trägt beim Anlegen einer Prüfzeile automatisch Bearbeiter und Zeitpunkt ein. |
| CHX.Webshop | CXW Sales Price Checking | Tabelle | `OnModify` | Trigger | – | Aktualisiert Bearbeiter/Zeitpunkt und setzt Validierung/Freigabe zurück, sobald sich die Währung ändert. |
| CHX.Webshop | CXW Sales Price Checking | Tabelle | `OnRename` | Trigger | – | Aktualisiert Bearbeiter und Zeitpunkt, wenn der Schlüssel einer Prüfzeile geändert wird. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `FinalPrice – OnValidate` | Trigger | – | Setzt den Validierungsstatus einer Zeile zurück, sobald der Endpreis manuell geändert wird. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `Import CSV` | Aktion | – | Importiert eine CSV-Datei mit neuen Verkaufspreisen, sofern keine offenen Prüfzeilen vorhanden sind. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `Validate` | Aktion | – | Rundet die eingegebenen Preise und prüft alle offenen Zeilen auf Marge, Preisabweichung und Datumsplausibilität. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `Approve` | Aktion | – | Gibt nach Bestätigung alle validierten Zeilen zur Übernahme frei und vermerkt den freigebenden Benutzer. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `Add all Currencies` | Aktion | – | Legt für eine freigegebene Zeile automatisch Preise in allen weiteren aktivierten Währungen anhand des Wechselkurses an. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `OnOpenPage` | Trigger | – | Leert beim Öffnen die Arbeitsliste, damit nur zuletzt importierte Zeilen bearbeitet werden. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `OnModifyRecord` | Trigger | – | Verhindert nachträgliche Änderungen an bereits freigegebenen Preiszeilen. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `fnValidate` | Prozedur | Internal | Führt die Prüflogik aus: vergleicht mit dem bisherigen Preis, prüft Mindestmarge und Datumsplausibilität. |
| CHX.Webshop | CXW Sales Price Checking List | Seite | `fnCalcNonStockPrice` | Prozedur | Public | Berechnet für eine Preisspanne den Nicht-Lagerpreis anhand eines hinterlegten Prozentaufschlags. |
| CHX.Webshop | CXW Sales Price Archive | Tabelle | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Archiveintrags automatisch Bearbeiter und Zeitpunkt ein. |
| CHX.Webshop | CXW Sales Price Archive | Tabelle | `OnModify` | Trigger | – | Aktualisiert Bearbeiter und Zeitpunkt bei jeder nachträglichen Änderung eines Archiveintrags. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `WriteBackAndArchive` | Prozedur | Public | Legt einen geprüften Preis als Standard-Verkaufspreis an/aktualisiert ihn und archiviert die Prüfzeile. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `UpdateSalesPriceFields` | Prozedur | Internal | Überträgt Währung, Preis und Zusatzfelder von der Prüfzeile auf den Verkaufspreis. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `ResolveUnitPriceLCY` | Prozedur | Internal | Ermittelt den Preis in Hauswährung anhand des Wechselkurses. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `ArchiveCheckingLine` | Prozedur | Internal | Legt eine neue, fortlaufend nummerierte Archivversion der Prüfzeile an. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `CreateExternalInterfaceFile` | Prozedur | Public | Wandelt einen Verkaufspreis in JSON um, legt ihn als Ausgangsdatei ab und sendet ihn an die externe Schnittstelle. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `SendToApiInterface` | Prozedur | Internal | Baut die HTTP-Anfrage inkl. Authentifizierung auf, sendet sie und protokolliert das Ergebnis. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `BuildSigV4Headers` | Prozedur | Internal | Berechnet die AWS-Signatur-Header nach dem AWS-Signature-V4-Verfahren. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `SanitizeHeaderText` | Prozedur | Internal | Entfernt aus Zugangsdaten Zeichen, die als ungültiger HTTP-Header abgelehnt würden. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `HexEncode` | Prozedur | Internal | Wandelt binäre Daten in eine hexadezimale Textdarstellung um. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `Sha256HexLower` | Prozedur | Internal | Berechnet einen SHA-256-Hash für die AWS-Signaturberechnung. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `HmacChainStep` | Prozedur | Internal | Führt einen Schritt der AWS-Schlüsselableitung aus. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `DeriveSigningKey` | Prozedur | Internal | Leitet aus dem AWS-Geheimschlüssel den tagesgültigen Signaturschlüssel ab. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `HmacSignatureHexLower` | Prozedur | Internal | Berechnet die endgültige AWS-Signatur einer Anfrage. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `BuildRedactedRequestText` | Prozedur | Internal | Erstellt den protokollierten Anfragetext mit Platzhalter statt Zugangsdaten. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `LogHttpCall` | Prozedur | Internal | Schreibt jeden Preis-Export-Aufruf in das gemeinsame HTTP-Aufrufprotokoll. |
| CHX.Webshop | CXW Export Gateway Sales Price | Codeunit | `AddFieldToJson` | Prozedur | Internal | Fügt ein Datenfeld typgerecht einem JSON-Objekt hinzu. |
| CHX.Webshop | CXW Import Sales Price | Xmlport | `OnAfterInitRecord` | Trigger | – | Überspringt beim Import die erste Zeile (Spaltenüberschriften). |
| CHX.Webshop | CXW Import Sales Price | Xmlport | `OnAfterInsertRecord` | Trigger | – | Leerer technischer Trigger ohne zusätzliche Logik. |
| CHX.Webshop | CXW Import Sales Price | Xmlport | `OnOpenPage (Anfrageseite)` | Trigger | – | Setzt beim Öffnen des Importdialogs die Länder-Option zurück auf Nein. |
| CHX.Webshop | CXW Import Sales Price | Xmlport | `OnPreXmlPort` | Trigger | – | Bereitet den Import vor, indem die Kopfzeilen-Erkennung aktiviert wird. |
| CHX.Webshop | CXW Import Sales Price | Xmlport | `OnPostXmlPort` | Trigger | – | Zeigt nach abgeschlossenem Import eine Bestätigungsmeldung an. |
| CHX.Webshop | CXW Import Sales Prices | Codeunit | `OnRun` | Trigger | – | Startet die Verarbeitung einer hochgeladenen Preisdatei. |
| CHX.Webshop | CXW Import Sales Prices | Codeunit | `ProcessFile` | Prozedur | Internal | Liest die Datei zeilenweise ein, prüft die Kopfzeile und übergibt jede Zeile zur Verarbeitung. |
| CHX.Webshop | CXW Import Sales Prices | Codeunit | `ProcessLine` | Prozedur | Internal | Wandelt eine einzelne CSV-Zeile in einen temporären Verkaufspreis-Datensatz um. |
| CHX.Webshop | CXW Import Sales Prices | Codeunit | `EvaluateHeaderRow` | Prozedur | Internal | Prüft, ob die Kopfzeile der Datei den erwarteten Spaltennamen entspricht. |
| CHX.Webshop | CXW Import Sales Prices | Codeunit | `WriteProtocol` | Prozedur | Internal | Schreibt eine Fehlermeldung zu einer Importdatei in das Importprotokoll. |
| CHX.Webshop | CXW Import Sales Prices | Codeunit | `WriteSalesPrices` | Prozedur | Internal | Legt die eingelesenen Preise als neue Verkaufspreise an oder aktualisiert bestehende. |
| CHX.Webshop | CXW Import Sales Prices | Codeunit | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert nach der Aktualisierung eines bestehenden Verkaufspreises. |
| CHX.Webshop | CXW Sales Price Outbound File | Tabelle | `OnInsert` | Trigger | – | Trägt beim Anlegen einer Ausgangsdatei automatisch den Erstellungszeitpunkt ein. |
| CHX.Webshop | CXW Sales Price Inbound File | Tabelle | `OnInsert` | Trigger | – | Trägt beim Hochladen einer Datei automatisch den Zeitpunkt ein. |
| CHX.Webshop | CXW Price Import Protokoll | Tabelle | `OnInsert` | Trigger | – | Trägt beim Anlegen eines Protokolleintrags automatisch den Zeitpunkt ein. |

> Die Tabelle ist nach Funktionsbereich (SellWatch → gemeinsame HTTP-Infrastruktur → Verkaufspreisverwaltung) und darin nach Objekt-ID sortiert. Für Details und die reinen Datentabellen/Erweiterungen ohne eigene Prozeduren (Table 60300, TableExtension 60303/60304/60319/60320, PageExtension 60326/60327, Page 60308/60323, alle Enums, alle Permission Sets) siehe die Einzeldatei im selben Ordner.

---

## Funktionsbereiche im Vergleich

| Funktionsbereich | Objekte | Anzahl Funktionen | Hinweis |
|---|---|---|---|
| HTTP-Aufruf-Protokollierung (`LogHttpCall`-Muster) | Table 60301, Codeunit 60329 | 2 nahezu identische Implementierungen | Beide Codeunits schreiben eigenständig in Table 60302 "CXW Http Call Log" mit fast identischem Muster (Init, Felder befüllen, Blob-Streams schreiben, Insert). Guter Kandidat für eine gemeinsame Hilfsprozedur in einem Basis-Baustein. |
| Redigierte Anfragetext-Erstellung (`BuildRedactedRequestText`) | Table 60301, Codeunit 60329 | 2 unabhängige Implementierungen | Beide bauen einen für das Protokoll sicheren Anfragetext ohne Zugangsdaten, mit leicht unterschiedlichem Funktionsumfang (Codeunit 60329 deckt mehr Auth-Arten ab). Bei Konsolidierung der HTTP-Infrastruktur zusammenführen. |
| Isolated-Storage-Zugriffsmuster (Set/Get/Key) | Table 60317 (API-Schlüssel, AWS Secret, AWS Session Token) | 9 Prozeduren nach identischem Muster | Dreimal dasselbe Set/Get/InternalKey-Dreiergespann für unterschiedliche Geheimnisse. Ließe sich mit einem generischen `SetSecret(SecretName; Value)`/`GetSecret(SecretName): Text` auf 2 Prozeduren reduzieren. |
| Inbound-API-Schreibzugriff | Page 60337 (SellWatch) | 4 Funktionen | Bisher einzige `PageType = API`-Schnittstelle im Projekt; alle anderen Integrationen sind entweder ausgehend (Codeunit 60329, Table 60301) oder datei-/importbasiert (Codeunit 60330, Xmlport 60328). Als Vorlage für künftige API-Pages geeignet. |

---

## Empfehlungen zur Extension-Auslagerung

### Hohe Priorität
| Funktionsbereich | Betroffene Objekte | Empfehlung |
|---|---|---|
| SellWatch als eigenständige Extension | Table 60300/60301, TableExtension 60303/60304, Codeunit 60305, Page 60307/60308/60337, PermissionSet 60300/60310 | Fachlich vollständig unabhängig vom Preisexport; ID-Bereich bereits sauber getrennt (60300–60310, plus Page 60337 als API-Schreibzugang und PermissionSet 60300 als eigener API-Berechtigungssatz). Auslagerung wäre überwiegend eine Verschiebe-Operation, kein Umbau. |

### Mittlere Priorität
| Funktionsbereich | Betroffene Objekte | Empfehlung |
|---|---|---|
| Gemeinsame HTTP-Infrastruktur als dritter Basis-Baustein | Table 60302/60317, Page 60309/60324/60325 | Sollte bei einer Aufteilung nicht in eine der beiden Fach-Extensions wandern, sondern als gemeinsame Abhängigkeit bestehen bleiben; dabei die doppelten `LogHttpCall`/`BuildRedactedRequestText`-Implementierungen konsolidieren. |
| Isolated-Storage-Zugriff auf Table 60317 vereinheitlichen | Table 60317 | Die neun Set/Get/Key-Prozeduren auf ein generisches Paar reduzieren, bevor die Tabelle in einen gemeinsamen Basis-Baustein wandert. |

### Niedrige Priorität
| Funktionsbereich | Betroffene Objekte | Empfehlung |
|---|---|---|
| Toten bzw. unaufgerufenen Code klären | Codeunit 60305 (`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE`), Table 60301 (`CreateJsonObjectCheckOnline`, `ReadJSONFile`) | Vor jeder Auslagerung mit dem Fachbereich klären, ob diese JSON-Rückmeldungen an SellWatch noch benötigt werden oder entfernt werden können. |
| CSV-Import-Pfad der Verkaufspreisverwaltung separat betrachten | Codeunit 60330, Table 60315/60316, Xmlport 60328 | Laut Code-Kommentaren aktuell nicht produktiv angebunden; eigenständig genug für eine spätere, unabhängige Entscheidung. |

---

## Projektabhängigkeiten

Nur ein Projekt vorhanden (CHX.Webshop), daher keine Abhängigkeiten zwischen mehreren AL-Projekten in diesem Repository. Laut `app.json` hängt CHX.Webshop von **CHX.Base** (27.0.1.1) ab; die Grenze zu diesem Basis-Modul wurde in dieser Analyse nicht mituntersucht (separates Repository).
