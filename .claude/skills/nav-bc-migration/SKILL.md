---
name: nav-bc-migration
description: Migration von Dynamics NAV Objekten (Tabellen, Codeunits, Pages, Reports) nach Business Central / AL. Nutze diesen Skill IMMER, wenn der Nutzer NAV-Exporte (.txt) bereitstellt und eine Übernahme, Konvertierung oder Migration nach AL/Business Central will – auch wenn nicht explizit "Skill" oder "Migration" gesagt wird, z.B. bei "übernimm mir diese Tabellen", "mach daraus eine Table Extension", "konvertiere diese Codeunits", "Option-Feld soll Enum werden". Deckt sowohl Standardobjekte (Table/Page Extensions auf Feldbereich) als auch Kundenobjekte (1:1-Übernahme unter gleicher ID) ab. Die sieben Teilaufgaben sind unabhängig voneinander aufrufbar.
---

# NAV → Business Central Migration

Migration von Dynamics NAV Datenbankobjekten in eine Business Central / AL Umgebung. Der Nutzer exportiert Objekte aus dem NAV-Vorsystem als .txt-Dateien und lässt sie hier objekttyp- und bereichsabhängig nach AL übernehmen.

## Projektweite Rahmenbedingungen (gelten für ALLE Teilaufgaben)

**Kundennummernbereich / Feldbereich: 50000–89999.** Dieser Bereich gilt sowohl für Objekt-IDs als auch für Feld-IDs.

**AL-Konformität hat oberste Priorität.** Code muss syntaktisch und stilistisch gültiges, modernes AL sein (aktuelle Object-Syntax, korrekte Attribute, keine veralteten C/AL-Konstrukte).

**Nichts geht verloren.** Wenn ein Teil eines Objekts nicht AL-konform übernommen werden kann, wird er trotzdem übernommen (z.B. auskommentiert mit Hinweis `// TODO: manuell prüfen – Grund: ...`), statt ihn wegzulassen. Der Nutzer prüft diese Stellen anschließend manuell.

**Option → Enum, projektweit.** Sobald ein Feld vom Typ `Option` vorkommt (egal in welchem Objekttyp), gilt:

1. Prüfen, ob für diese Optionsliste bereits ein passender Enum existiert (Name/Werte abgleichen).
2. Wenn nicht vorhanden: neuen Enum anlegen (Werte 1:1 aus der Optionsliste übernehmen, Reihenfolge beibehalten).
3. Das Feld selbst auf den Typ `Enum` umstellen (bzw. `Enum Extension`, falls es sich um ein Standard-Enum handelt, das erweitert wird).

**Funktionen übernehmen.** Kundenspezifische Funktionen, die zu migrierten Feldern/Objekten gehören, werden immer mit übernommen (nicht nur die Datenstruktur).

**Ablage der Quell-Exporte.** Der Nutzer legt die .txt-Exporte an einem Pfad ab und nennt diesen Pfad. Diesen Pfad zuerst einlesen/auflisten, bevor mit der Konvertierung begonnen wird.

**Teilaufgabe klären.** Der Nutzer nennt zu Beginn jeder Anfrage, welche der sieben Teilaufgaben unten gemeint ist (oder es ergibt sich eindeutig aus dem gelieferten Objekttyp). Falls unklar, kurz nachfragen, nicht raten.

## Phase 0: Abhängigkeits-Check (IMMER zuerst, vor jeder Konvertierung)

Bevor auch nur eine Zeile AL erzeugt wird, werden die Quell-Exporte auf Referenzen nach außen geprüft. Ziel: Der Nutzer soll fehlende Objekte einmalig aus dem Alt-System nachexportieren können, statt später Lücken in den .al-Dateien zu finden.

### Ablauf

1. Alle .txt-Dateien am genannten Pfad einlesen und eine **Inventarliste** der enthaltenen Objekte aufbauen (Objekttyp, ID, Name).
2. Jeden Export nach Referenzen auf andere Objekte durchsuchen. Typische Fundstellen:
   - Variablendeklarationen: `Record <Tabelle>`, `Codeunit <Name>`, `Page <Name>`, `Report <Name>`, `XMLport <Name>`, `Query <Name>`
   - `TableRelation`, `CalcFormula` (Lookup/Sum/Count auf andere Tabellen), `FlowField`-Definitionen
   - `RunObject`, `RunPageLink`, `LookupPageID`, `DrillDownPageID`
   - `CODEUNIT.RUN`, `PAGE.RUN`, `PAGE.RUNMODAL`, `REPORT.RUN`, `REPORT.RUNMODAL`
   - Funktionsaufrufe auf Objekten, die nicht im Export enthalten sind
   - Enums / Optionslisten, die auf ein nicht geliefertes Objekt verweisen
   - DataItems in Reports
3. Jede gefundene Referenz gegen die Inventarliste abgleichen.
4. **Klassifizierung:**
   - **Bekannt** – Objekt liegt im Export vor. Kein Handlungsbedarf.
   - **BC-Standard** – Objekt-ID liegt außerhalb 50000–89999 und ist ein Standardobjekt (z.B. `Item`, `Sales Header`, `Customer`). Gilt als bekannt, wird NICHT gemeldet.
   - **Unbekannt** – Objekt liegt im Kundenbereich 50000–89999 (bzw. ist erkennbar kundenspezifisch) und ist **nicht** im Export enthalten. → melden.

### Verhalten bei unbekannten Objekten

Wenn mindestens ein unbekanntes Objekt gefunden wurde: **Konvertierung stoppen. Keine .al-Dateien erzeugen.** Stattdessen dem Nutzer eine Liste ausgeben:

```
Vor der Konvertierung fehlen mir folgende Objekte aus dem Alt-System.
Bitte exportiere sie und lege sie am selben Pfad ab:

| Objekttyp | ID    | Name                  | Referenziert von        | Fundstelle                    |
|-----------|-------|-----------------------|-------------------------|-------------------------------|
| Table     | 50012 | Zusatzdaten Kunde     | Cod50100 SalesMgt       | Variable "ZusatzRec", Zeile 45 |
| Codeunit  | 50200 | Preisfindung Kunde    | Tab50010 Artikelzusatz  | Aufruf BerechnePreis(), Z. 88  |
| Page      | ?     | Kunden Zusatzliste    | Cod50100 SalesMgt       | PAGE.RUNMODAL, Zeile 120       |
```

Regeln für die Liste:

- Nach Objekttyp und ID sortieren, Duplikate zusammenfassen.
- ID angeben, wenn sie aus dem Quellcode ableitbar ist; sonst `?` und den Namen so notieren, wie er im Export steht.
- Immer angeben, **wo** die Referenz herkommt (Quellobjekt + Fundstelle), damit der Nutzer sie im Alt-System wiederfindet.
- Danach explizit fragen: nachliefern oder bewusst ohne die Objekte weitermachen? Erst nach Antwort des Nutzers weiterarbeiten.
- Entscheidet der Nutzer, ohne die Objekte weiterzumachen: konvertieren und jede betroffene Stelle mit `// TODO: Objekt <Typ> <ID/Name> nicht geliefert – manuell prüfen` markieren.

Wenn **keine** unbekannten Objekte gefunden wurden: kurz bestätigen ("Alle Referenzen aufgelöst") und direkt mit der Teilaufgabe fortfahren.

## Genereller Ablauf pro Teilaufgabe

1. Quell-.txt-Datei(en) am genannten Pfad einlesen.
2. **Phase 0 (Abhängigkeits-Check) durchführen.** Erst weiter, wenn geklärt.
3. Objekte einzeln durchgehen (bei Sammel-Exports: pro Objekt ein eigenes .al-File).
4. Die spezifischen Regeln der jeweiligen Teilaufgabe (siehe unten) anwenden.
5. Enum-Handling gemäß den projektweiten Regeln durchführen (inkl. Prüfung auf bereits existierende Enums – dafür den Zielpfad/das Zielprojekt nach vorhandenen Enum-Objekten durchsuchen, sofern verfügbar).
6. Ergebnis als .al-Datei(en) ausgeben, sinnvoll benannt (z.B. `TableExt<ID>.<Name>.al`, `Cod<ID>.<Name>.al`).
7. Kurze Zusammenfassung: was wurde 1:1 übernommen, was wurde als Enum angelegt, was musste auskommentiert/manuell markiert werden, welche Objekte fehlten.

## Teilaufgabe 1: Standardtabellen migrieren

**Input:** NAV-Export (.txt) von Standardtabellen.

**Regeln:**

- Nur Felder im Bereich 50000–89999 berücksichtigen.
- Für jede betroffene Standardtabelle eine Table Extension anlegen (nicht die Standardtabelle selbst verändern).
- Option-Felder in diesem Bereich → Enum-Handling gemäß den projektweiten Regeln.
- Zugehörige kundenspezifische Funktionen in die Table Extension übernehmen.

## Teilaufgabe 2: Kundentabellen migrieren

**Input:** NAV-Export (.txt) von Tabellen im Kundenbereich (ID 50000–89999).

**Regeln:**

- 1:1-Übernahme als eigenständige AL-Tabelle unter derselben ID.
- Option-Felder → Enum-Handling wie oben (inkl. Prüfung auf bereits bestehende Enums, bevor ein neuer angelegt wird).
- Alle Funktionen der Tabelle übernehmen.

## Teilaufgabe 3: Codeunits im Kundenbereich migrieren

**Input:** NAV-Export (.txt) von Codeunits im Bereich 50000–89999.

**Regeln:**

- So AL-konform wie möglich importieren (ID beibehalten).
- Teile, die sich nicht AL-konform übersetzen lassen, trotzdem übernehmen (auskommentiert + Hinweis) statt sie wegzulassen – zur späteren manuellen Prüfung durch den Nutzer.
- Wird im Code ein Feld vom Typ Option verwendet → Enum-Handling wie oben anwenden.

## Teilaufgabe 4: Standard-Codeunits mit Kundenanpassungen migrieren

**Input:** NAV-Export (.txt) von Standard-Codeunits, die kundenseitig verändert wurden.

**Regeln:**

- Zunächst prüfen, ob im Export tatsächlich Kundenanpassungen gegenüber dem Standardverhalten vorhanden sind (z.B. zusätzliche/geänderte Logik, die nicht Teil des BC-Standards ist).
- Falls Kundenanpassungen vorhanden sind: Diese **NICHT** durch Verändern des Standardobjekts umsetzen, sondern als Event Subscriber in einer neuen Codeunit im Kundenbereich (ID 50000–89999) nachbauen. Dazu:
  - Passendes Standard-Event identifizieren (z.B. `OnBeforeInsertEvent`, `OnAfterValidateEvent` o.ä. – je nach Art der Anpassung), falls vorhanden.
  - Wenn kein passendes Standard-Event existiert, dies explizit kennzeichnen (`// TODO: kein passendes Event gefunden, manuell prüfen`) statt die Anpassung zu verwerfen.
- Falls keine Kundenanpassung erkennbar ist (reiner Standard): keine Codeunit erzeugen, sondern kurz zurückmelden, dass hier keine Anpassung gefunden wurde.

## Teilaufgabe 5: Standard-Pages migrieren

**Input:** NAV-Export (.txt) von Standard-Pages.

**Regeln:**

- Nur sichtbare Felder im Bereich 50000–89999 berücksichtigen.
- Diese als Page Extension anlegen (nicht die Standard-Page selbst verändern).
- Enum-Handling wie oben, falls betroffene Felder Option-Felder sind.

## Teilaufgabe 6: Kundenpages migrieren

**Input:** NAV-Export (.txt) von Pages im Kundenbereich.

**Regeln:**

- AL-konforme 1:1-Übernahme unter derselben ID.
- Nicht konvertierbare Teile trotzdem übernehmen (z.B. auskommentiert), damit nichts verlorengeht.

## Teilaufgabe 7: Reports migrieren

**Input:** NAV-Export (.txt) von Reports im Kundenbereich.

**Regeln:**

- Gleiches Prinzip wie bei Teilaufgabe 6 (Kundenpages): AL-konforme Übernahme, nicht Konvertierbares auskommentiert übernehmen.
- Es ist mit deutlich mehr manueller Nacharbeit zu rechnen (Reports lassen sich in AL oft nur teilweise automatisch übersetzen, insbesondere Layouts/DataItems) – das dem Nutzer in der Zusammenfassung explizit mitteilen.
