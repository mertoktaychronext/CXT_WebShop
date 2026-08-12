## 1. Datenmodell

- [x] 1.1 Enum 60337 "CXW Workshop Line Status" anlegen mit Werten `Neu` (0), `WS geprüft` (1), `Verarbeitet` (2); Captions DE/EN.
- [x] 1.2 Tabelle 60318 "CXW Workshop Line" anlegen: PK (Document Type, Document No., Line No.), Felder Item No., Manufacturer Serial No. (Pflicht), Status (Init = Neu), Genuine, Attribute 1–10 (Text[250], Captions "Attribut 1"–"Attribut 10", `// TODO: Attributnamen final klären`), Created At (DateTime, alternativ SystemCreatedAt nutzen), Checked At (DateTime), Processing Error (Text[250]).
- [x] 1.3 `OnModify`-Trigger/Event auf "CXW Workshop Line": bei Statuswechsel auf `WS geprüft` `Checked At` := CurrentDateTime setzen; Statuswechsel `WS geprüft` → `Neu` und weg von `Verarbeitet` mit Error blockieren (unabhängig davon, ob die Änderung über API oder intern erfolgt).
- [x] 1.4 Page 60338 "CXW Workshop Lines" (Liste, rein informativ, keine Felder editierbar) mit Status-Filter anlegen.
- [x] 1.5 Table Extension 60321 "CXW Workshop Purchase Line" auf "Purchase Line": Felder `Manufacturer Serial No.` (Text[50]), `Not Arrived` (Boolean), `Sent to Workshop` (Boolean) ergänzen, Field-IDs ab 60301 (Field-ID 60300 ist bereits durch TabExt60303 "CXW SW Purchase Line" belegt).
- [x] 1.6 Löschverhalten umsetzen: beim Löschen einer Purchase Line mit zugehöriger "CXW Workshop Line" im Status `Neu`/`WS geprüft` die Workshop Line mitlöschen; im Status `Verarbeitet` das Löschen der Workshop Line verhindern (Error) bzw. sie unangetastet lassen.

## 2. Erfassung im Einkauf (Send to Workshop)

- [x] 2.1 Page 60340 "CXW Serial No. Input" vom Typ `StandardDialog` mit einem Pflicht-Textfeld für die Herstellerseriennummer anlegen.
- [x] 2.2 Page Extension 60329 "CXW Workshop Purch Order Subf" auf Page "Purchase Order Subform" (Zeilen-Subform, nicht die Dokumentseite): neue Felder `CXW Manufacturer Serial No.` und `CXW Sent to Workshop` sichtbar machen (Editable = false).
- [x] 2.3 Aktion "Send to Workshop" auf Page Extension 60328 "CXW Workshop Purchase Order" (Dokumentseite "Purchase Order") implementiert: Iteration über Zeilen mit Type = Item, Quantity <> 0, Sent to Workshop = false.
- [x] 2.4 Je Zeile: Confirm-Dialog "Ist Artikel {Item No.} {Description} wirklich angekommen?" — bei "Nein" `Not Arrived` := true setzen und Zeile überspringen (kein Fehler, kein Abbruch der Schleife); bei erneutem Lauf mit "Ja" `Not Arrived` zurücksetzen.
- [x] 2.5 Je Zeile bei "Ja": "CXW Serial No. Input" modal aufrufen; bei leerer Eingabe oder Abbruch Fehler für diese Zeile sammeln/anzeigen und mit der nächsten Zeile fortfahren statt die gesamte Aktion abzubrechen.
- [x] 2.6 Bei gültiger Eingabe: Seriennummer in Purchase Line speichern, `Sent to Workshop` := true, `Not Arrived` := false, "CXW Workshop Line" mit PL-Schlüsseln, Item No., Manufacturer Serial No., Status = Neu anlegen.
- [x] 2.7 Labels statt Hardcoded Strings für alle Dialogtexte und Fehlermeldungen verwenden.
- [x] 2.8 Auf Page Extension 60329: Zeilenfelder (Type, No., Variant Code, Description, Location Code, Quantity, Unit of Measure Code, Direct Unit Cost) über eine im `OnAfterGetRecord` berechnete Variable (`LineEditable := not Rec."CXW Sent to Workshop"`) und `modify(<Control>) { Editable = LineEditable; }` gesperrt, sobald `Sent to Workshop = true` ist. Control-Namen gegen den tatsächlichen Microsoft-Base-App-Quellcode (Page 54 "Purchase Order Subform") verifiziert.

## 3. API für den Workshop

- [x] 3.1 Page 60339 "CXW Workshop Line API" (PageType = API) auf "CXW Workshop Line" angelegt: APIPublisher = 'saliniLife' (Projektkonvention, siehe Pag60337), APIGroup = 'workshop', APIVersion = 'v1.0', EntityName 'workshopLine', EntitySetName 'workshopLines', ODataKeyFields = SystemId, DelayedInsert = true, InsertAllowed = false, DeleteAllowed = false.
- [x] 3.2 Felder exponiert: Keys (documentType, documentNo, lineNo), itemNo, manufacturerSerialNo, status, genuine, attribute1–attribute10, systemId.
- [x] 3.3 `OnModifyRecord`: nur attribute1–attribute10, genuine, status beschreibbar (Schlüssel-/Systemfelder per Editable=false + explizitem Vergleich in OnModifyRecord geschützt); Statusrückschritte (WS geprüft → Neu, weg von Verarbeitet) werden von der in Task 1.3 implementierten Tabellen-Sperre abgefangen (feuert auch bei API-Modify).
- [x] 3.4 Permission Set "CXW Workshop API" (Abschnitt 6) gewährt dem API-Benutzer ausschließlich `tabledata "CXW Workshop Line" = RM` (kein Insert/Delete, kein Zugriff auf Purchase Line oder Item).

## 4. Job-Queue-Verarbeitung

- [x] 4.1 Codeunit 60331 "CXW Process Workshop Lines" angelegt (parameterloses OnRun, Job-Queue-fähig analog Codeunit60305), verarbeitet alle "CXW Workshop Line" mit Status = WS geprüft.
- [x] 4.2 Pro Zeile Verarbeitung über `[TryFunction]`-Prozedur `TryProcessLine` gekapselt; bei Fehlschlag `GetLastErrorText()` in `Processing Error` geschrieben, `Commit()` nach jeder Zeile.
- [x] 4.3 Fall Genuine = true: Purchase Line/Header gelesen (Standardfall: eine PL = eine PO), `Qty. to Receive` = Menge gesetzt, `Codeunit.Run(Codeunit::"Purch.-Post", PurchHeader)` mit Receive = true, Invoice = false aufgerufen.
- [x] 4.4 Zentrale Prozedur `GetAttributeMapping` (WL-Feld → Item-Attribute-Name) mit Platzhalter-Konstanten "Attribut 1"–"Attribut 10" implementiert, markiert mit `// TODO: Finale Attributnamen einsetzen (Platzhalter!)`.
- [x] 4.5 Für jedes befüllte Attributfeld: fehlende Item Attribute / Item Attribute Value automatisch angelegt (Typ Text) und Item Attribute Value Mapping auf den Artikel geschrieben; leere Attributfelder übersprungen.
- [x] 4.6 Nach erfolgreicher Verarbeitung: Workshop-Line-Status := Verarbeitet.
- [x] 4.7 Fall Genuine = false: zugehörige Purchase Order storniert (Reopen falls nötig, dann Delete); `// TODO: Verhalten für gemischte POs ...` als Kommentar hinterlegt.
- [x] 4.8 Workshop-Line-Status wird bewusst **vor** dem PO-Löschen auf Verarbeitet gesetzt, damit der Cascade-Delete-Schutz in TabExt60321 beim Löschen der Purchase Line greift und die Workshop Line bestehen bleibt.

## 5. Doku und Konfiguration

- [x] 5.1 README.md im Change-Ordner: OAuth2-S2S-Einrichtung (Entra App-Registrierung) für die Workshop-API — Konfigurationshinweis, kein Code.
- [x] 5.2 README.md im Change-Ordner: Anlage des Job-Queue-Eintrags für "CXW Process Workshop Lines" (Empfehlung: alle 5 Minuten).

## 6. Berechtigungen und Übersetzungen

- [x] 6.1 Permission Set 60301 "CXW Workshop All" für alle neuen Objekte (Tabelle, Pages, Codeunit) angelegt, analog zum bestehenden Muster (z. B. CXWSWChronWSAll).
- [x] 6.2 Permission Set 60302 "CXW Workshop API" nur mit `tabledata "CXW Workshop Line" = RM` angelegt, analog zum bestehenden schlanken Muster CXWSellWatchAPI.
- [ ] 6.3 Alle neuen Captions/Labels in DE und EN pflegen (.xlf synchronisieren) — **nicht durchführbar in dieser Umgebung**: `.g.xlf` wird vom AL-Compiler generiert, der hier nicht verfügbar ist. Nach dem ersten Kompilieren in VS Code den `managing-bc-translations`-Skill bzw. den Projekt-Workflow ausführen. Für die deutsche Übersetzung von `ArrivedQst` (PagExt60328) explizit den wörtlich vorgegebenen Text "Ist Artikel %1 %2 wirklich angekommen?" verwenden.

## 7. Prüfung

- [ ] 7.1 AL-Extension kompiliert fehlerfrei — **nicht durchführbar in dieser Umgebung** (kein AL-Compiler/CLI verfügbar); bitte in VS Code mit der AL-Extension kompilieren, bevor der Change als fertig gilt. Objekt-IDs wurden je Objekttyp gegen den bestehenden Code geprüft (kollisionsfrei), Control-Namen der Purchase-Order-Subform gegen den echten Microsoft-Base-App-Quellcode verifiziert.
- [ ] 7.2 Manueller Testlauf: Send to Workshop (Ja/Nein-Pfad, Seriennummer-Pflicht, Fehlerisolation, Zeilensperre nach Übertragung), API GET/PATCH inkl. gesperrter Insert/Delete/Statusrückschritte, Job-Queue-Lauf für Genuine = true und Genuine = false inkl. Fehlerprotokollierung — **ausstehend**, benötigt eine laufende BC-Umgebung.
- [ ] 7.3 al-funktionsregister für die geänderten/neuen Projekte aktualisieren (neue öffentliche Prozeduren/Objekte vorhanden) — **ausstehend**, auf Wunsch als separater Skill-Aufruf nach erfolgreicher Kompilierung.
