## Context

CHX.Webshop kauft Uhren an, die vor der Einlagerung von einer externen Werkstatt ("Workshop") auf Echtheit geprüft werden. Der Workshop ist ein externes Tool ohne BC-Zugriff auf Standardobjekte; er kommuniziert ausschließlich über eine Custom API. Aktuell existiert keine Datenstruktur, die eine Purchase Line mit ihrem Workshop-Prüfstatus verknüpft, und keine Automatisierung, die Wareneingang/Stornierung von der Werkstatt-Rückmeldung abhängig macht.

Das Projekt folgt bereits dem Muster "eingehende externe Daten über eine Zwischentabelle + Custom API + Job-Queue-Verarbeitung" (siehe `CXW SellWatch Vendor Info` / `CXW SellWatch Mgt`, Codeunit 60305). Diese Änderung wendet dasselbe Muster für den umgekehrten Fluss an (BC → Workshop → BC), mit bidirektionaler API statt reinem Insert.

Objekt-Präfix des Projekts: `CXW`. ID-Bereich laut `app.json`: 60300–60349. In AL hat jeder Objekttyp (Table, Page, Codeunit, Enum, TableExtension, PageExtension, PermissionSet, …) einen eigenen ID-Namensraum — zwei Objekte unterschiedlichen Typs können dieselbe Nummer tragen, ohne zu kollidieren. Die Belegung ist daher pro Typ zu prüfen, nicht als ein gemeinsamer Zähler über alle Typen hinweg.

## Goals / Non-Goals

**Goals:**
- Purchase-Order-Sachbearbeiter kann pro Zeile erfassen, ob der Artikel angekommen ist, und dabei die Herstellerseriennummer erfassen.
- Für jede angekommene Zeile entsteht eine nachverfolgbare "Workshop Line" mit klarem Status.
- Der Workshop kann offene Zeilen per API lesen und Prüfergebnis (Attribute, Echtheit, Status) zurückschreiben, ohne sonstigen BC-Zugriff.
- Nach positiver Prüfung wird automatisiert nur der Wareneingang gebucht (keine Rechnung) und die Attribute werden in die BC-Standard-Artikelattribute übernommen.
- Nach negativer Prüfung wird die zugehörige (noch ungebuchte) Purchase Order automatisiert storniert.
- Eine fehlerhafte Zeile darf die Verarbeitung der übrigen Zeilen nicht blockieren; Fehler sind sichtbar und nachvollziehbar.

**Non-Goals:**
- Keine Unterstützung für gemischte Purchase Orders (mehrere Zeilen, teils echt/teils nicht echt) — nur der Standardfall "eine PO = eine PL = eine Uhr" wird implementiert. Stellen, an denen das relevant wird, werden mit `// TODO:` markiert.
- Keine finale fachliche Benennung der 10 Attributfelder — Platzhalter "Attribut 1"–"Attribut 10", mit `// TODO:` markiert.
- Kein BC-Item-Tracking / keine Seriennummernbuchung — die Herstellerseriennummer bleibt ein reines Textfeld auf der Purchase Line.
- Keine Rechnungsbuchung (nur Wareneingang) — Invoice bleibt manueller Folgeschritt.
- Keine Änderung an Standardobjekten außerhalb der beschriebenen Extensions.

## Decisions

### Objekt-Zuordnung (je Objekttyp die nächste freie ID im Bereich 60300–60349)

| ID | Objekttyp | Name |
|---|---|---|
| 60337 | Enum | CXW Workshop Line Status |
| 60318 | Table | CXW Workshop Line |
| 60321 | TableExtension | CXW Workshop Purchase Line (auf Purchase Line, neue Felder ab Field-ID 60301) |
| 60328 | PageExtension | CXW Workshop Purchase Order (auf Page "Purchase Order" — Dokumentseite, für die Aktion "Send to Workshop") |
| 60329 | PageExtension | CXW Workshop Purch Order Subf (auf Page "Purchase Order Subform" — Zeilen-Subform, für neue Felder und die Editierbarkeits-Sperre) |
| 60338 | Page | CXW Workshop Lines (Liste) |
| 60339 | Page | CXW Workshop Line API (Custom API) |
| 60340 | Page | CXW Serial No. Input (StandardDialog) |
| 60331 | Codeunit | CXW Process Workshop Lines |
| 60301 | PermissionSet | CXW Workshop All (interner Vollzugriff) |
| 60302 | PermissionSet | CXW Workshop API (nur Lese-/Schreibzugriff des externen Workshop-Benutzers auf "CXW Workshop Line", analog zum bestehenden Muster "CXW Sell Watch API") |

Die Purchase Line hat bereits eine Table Extension (`TabExt60303 "CXW SW Purchase Line"`, Field-ID 60300 belegt) — die neuen Felder dieser Änderung liegen in einer eigenen Table Extension mit Field-IDs ab 60301, um Namens-/Feature-Trennung zu Sellwatch zu wahren.

### Workshop Line als eigene Tabelle statt reiner Purchase-Line-Erweiterung

Der Prüf-Workflow (Status, Attribute, Genuine-Flag, Fehlerprotokoll) ist fachlich vom Einkaufsbeleg getrennt: eine Purchase Order kann storniert/gelöscht werden, während die Workshop Line als Prüfnachweis bestehen bleibt (siehe Löschverhalten unten). Eine eigene Tabelle mit PK (Document Type, Document No., Line No.) erzwingt "eine Workshop Line pro Purchase Line" ohne zusätzliche Unique-Key-Logik und hält die API-Fläche (nur Workshop-relevante Felder) getrennt von der Purchase Line.

**Alternative verworfen**: Attribute direkt auf der Purchase Line als Felder — hätte die Purchase Line unnötig aufgebläht und dem Workshop indirekt Zugriff auf ein Kernobjekt (Purchase Line) gegeben, das über Custom APIs riskanter zu exponieren ist als eine dedizierte Zwischentabelle.

### API-Zugriff nur auf die Zwischentabelle, mit gesperrtem Insert/Delete

Der Workshop erhält nur Lese-/Schreibzugriff auf "Workshop Line", nicht auf Purchase Line oder Item — über ein eigenes, schlankes Permission Set "CXW Workshop API" (nur `tabledata "CXW Workshop Line" = RM`, kein Insert/Delete, kein Zugriff auf andere Tabellen), analog zum bestehenden Muster `CXWSellWatchAPI`. `InsertAllowed = false` und `DeleteAllowed = false` auf der API-Page verhindern zusätzlich auf Seiten der Page, dass Zeilen über die API entstehen oder verschwinden — Zeilen entstehen ausschließlich aus BC heraus (Aktion "Send to Workshop"). Rückwärts-Statuswechsel (`WS geprüft` → `Neu`, oder weg von `Verarbeitet`) werden im `OnModifyRecord`-Trigger der API-Page bzw. im `OnModify`-Trigger der Tabelle geprüft und mit Error blockiert, damit der Job-Queue-Lauf nicht durch nachträgliche externe Änderungen ausgehebelt wird.

### Seriennummer-Eingabe über modale StandardDialog-Page

AL hat keinen eingebauten Text-Input-Dialog. Für die Pflichteingabe der Herstellerseriennummer wird eine kleine Page vom Typ `StandardDialog` mit einem Textfeld gebaut und per `RunModal()` aufgerufen. Abbruch (`Action::Cancel` bzw. `RunModal() <> Action::OK`) oder leere Eingabe führt zu einer Fehlermeldung für diese Zeile; die Aktion läuft für die übrigen Zeilen weiter (siehe Fehlerisolation unten).

### Fehlerisolation pro Zeile in Aktion und Job-Queue

Sowohl "Send to Workshop" als auch "Process Workshop Lines" verarbeiten mehrere Datensätze in einer Schleife. Damit eine fehlerhafte Zeile (z. B. leere Seriennummer, fehlgeschlagene Buchung) nicht den gesamten Lauf abbricht:
- In der Aktion: Fehler pro PL werden gesammelt (z. B. via `TryFunction`) und am Ende als Sammel-Meldung angezeigt; erfolgreiche Zeilen bleiben committed.
- In der Job-Queue-Codeunit: pro Workshop Line wird die Verarbeitung über eine `[TryFunction]`-Prozedur gekapselt; bei Fehlschlag wird `GetLastErrorText()` in `Processing Error` geschrieben, ein `Commit()` sichert bereits erfolgreich verarbeitete Zeilen, bevor die nächste Zeile startet.

### Attribut-Mapping über eine zentrale Prozedur mit Konstanten

Die Zuordnung "Workshop-Line-Feld → Item-Attribute-Name" erfolgt in einer einzigen Prozedur (z. B. `GetAttributeMapping`) mit den zehn Platzhalternamen als Konstanten/Labels, klar mit `// TODO: Finale Attributnamen einsetzen (Platzhalter!)` markiert. Fehlende `Item Attribute`/`Item Attribute Value`-Einträge werden automatisch angelegt (Typ Text); leere Workshop-Line-Attributfelder werden übersprungen. Diese Zentralisierung stellt sicher, dass die spätere Umbenennung der Attribute an genau einer Stelle erfolgt.

### Wareneingang ohne Rechnung über Codeunit "Purch.-Post"

`Qty. to Receive` wird auf die Bestellmenge gesetzt, danach `Codeunit."Purch.-Post"` mit `Receive = true, Invoice = false` aufgerufen (Standard-BC-Muster, kein Custom-Posting-Code). Die Rechnung bleibt bewusst ein manueller Folgeschritt außerhalb dieser Änderung.

### Sperrung der Purchase Line nach Übertragung an den Workshop

Sobald `Sent to Workshop = true` ist, werden die Felder der betroffenen Purchase Line auf der Purchase-Order-Subform nicht mehr editierbar. Die eigentlichen Zeilenfelder (Type, No., Description, Quantity, Direct Unit Cost, Location Code, Unit of Measure Code, Variant Code) liegen technisch nicht auf der Dokumentseite "Purchase Order" selbst, sondern auf der eingebetteten Subform-Page "Purchase Order Subform" — dafür ist eine zweite, eigene Page Extension nötig (siehe Objekt-Zuordnung: 60328 für die Aktion auf der Dokumentseite, 60329 für Felder/Sperre auf der Subform). Umgesetzt wird die Sperre in PageExtension 60329 über eine im `OnAfterGetRecord`-Trigger berechnete globale Variable (`LineEditable := not Rec."CXW Sent to Workshop"`), die per `modify(<Control>) { Editable = LineEditable; }` an die bestehenden Zeilenfelder gebunden wird. Die Control-Namen wurden gegen den tatsächlichen Microsoft-Base-App-Quellcode (Page 54 "Purchase Order Subform") verifiziert, nicht geraten. Damit ist ausgeschlossen, dass eine bereits an den Workshop übergebene Zeile (Menge, Artikel, Preis) nachträglich über die UI verändert wird, während die Workshop Line noch auf Basis der ursprünglichen Daten läuft — die interne Verarbeitung (Job-Queue-Codeunit) setzt `Qty. to Receive` weiterhin direkt über den Tabellenzugriff, unabhängig von dieser UI-Sperre.

**Alternative verworfen**: Sperrung nur auf Tabellenebene (`OnModify`-Trigger der Purchase Line mit Error bei `Sent to Workshop = true`) — hätte den Nutzer erst nach Eingabe und Verlassen des Feldes mit einer Fehlermeldung konfrontiert statt die Bearbeitung von vornherein zu verhindern. Die UI-seitige Sperre (Editable = false) ist die bessere Nutzererfahrung und wird bevorzugt; eine zusätzliche serverseitige Absicherung ist hier nicht vorgesehen, da Zeilen ausschließlich über die Purchase-Order-Page bearbeitet werden.

**Scope-Grenze**: Nur die *Editierbarkeit* der Zeile wird gesperrt. Das *Löschen* der Zeile über die Standard-Delete-Aktion der Purchase Order bleibt technisch möglich und wird durch diese Änderung nicht zusätzlich unterbunden (siehe Löschverhalten unten für die Workshop-Line-Seite dieses Falls). `// TODO: Klären, ob das Löschen einer bereits an den Workshop gesendeten Purchase Line ebenfalls verhindert werden soll.`

### Löschverhalten Workshop Line bei PO-/PL-Löschung

- Storno-Fall (Genuine = false): Die PO wird gelöscht (ggf. vorher Reopen), die zugehörige Workshop Line bleibt als Prüfnachweis mit Status `Verarbeitet` bestehen (kein Cascade-Delete).
- Allgemein (`OnDelete`-Trigger der Purchase Line via Table Extension/Event-Subscriber): Workshop Lines im Status `Verarbeitet` dürfen nicht mitgelöscht werden (Error, falls ein Löschversuch das beträfe). Workshop Lines im Status `Neu` oder `WS geprüft` werden beim Löschen der zugehörigen Purchase Line automatisch mitgelöscht, damit keine verwaisten, nie verarbeiteten Datensätze zurückbleiben.

## Risks / Trade-offs

- **[Risiko]** Gemischte Purchase Orders (mehrere Zeilen, teils echt/teils nicht echt) werden fachlich nicht abgedeckt; würde ein solcher Fall auftreten, storniert die Job-Queue-Codeunit aktuell die *gesamte* PO auch bei nur einer nicht-echten Zeile. → **Mitigation**: `// TODO:`-Kommentar an der Stornierungsstelle, Verhalten bewusst auf den Standardfall beschränkt (siehe Non-Goals).
- **[Risiko]** Die API erlaubt dem Workshop, Attribute und Genuine-Flag beliebig zu setzen, solange die Zeile im Status `Neu` ist; es gibt keine serverseitige Plausibilitätsprüfung der Attributinhalte. → **Mitigation**: Out of Scope für diesen Change; Attributwerte sind Freitext und werden 1:1 übernommen.
- **[Risiko]** `Codeunit."Purch.-Post"` kann fehlschlagen (z. B. gesperrte Buchungsperiode, fehlende Lagerortangabe). → **Mitigation**: Fehlerisolation pro Zeile (siehe Decisions) verhindert, dass ein Fehlschlag andere Zeilen blockiert; Fehlertext landet in `Processing Error` zur manuellen Nachbearbeitung.
- **[Trade-off]** Die Workshop Line dupliziert `Item No.` aus der Purchase Line statt es zur Laufzeit nachzuschlagen. Das vereinfacht die API-Antwort für den Workshop (kein Join nötig), riskiert aber ein Auseinanderlaufen, falls sich die Purchase Line nach dem Anlegen der Workshop Line noch ändert (im Standardfall unwahrscheinlich, da `Sent to Workshop` weitere Übertragungen blockiert, aber die Zeile selbst bleibt editierbar).

## Migration Plan

Reine Neuentwicklung ohne Datenmigration. Deployment über normalen App-Publish-Zyklus. Nach dem Deployment:
1. Permission Set "CXW Workshop All" den internen Sachbearbeitern zuweisen; Permission Set "CXW Workshop API" ausschließlich dem externen Workshop-API-Benutzer.
2. Entra-App-Registrierung für OAuth2-S2S gemäß README einrichten und dem Workshop übergeben.
3. Job-Queue-Eintrag für "CXW Process Workshop Lines" gemäß README anlegen (Empfehlung: alle 5 Minuten).

Kein Rollback-Bedarf über das übliche App-Downgrade hinaus, da keine Bestandsdaten migriert werden.

## Open Questions

- Finale Namen der 10 Attributfelder (fachlich zu klären, aktuell Platzhalter).
- Zielverhalten für gemischte Purchase Orders (mehrere Zeilen, teils echt/teils nicht echt) — aktuell nicht implementiert.
- Soll das Löschen einer bereits an den Workshop gesendeten Purchase Line ebenfalls verhindert werden, oder reicht die Sperre der Editierbarkeit aus?
