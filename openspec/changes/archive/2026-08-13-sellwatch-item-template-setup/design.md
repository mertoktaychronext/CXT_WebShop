## Context

Codeunit 60305 "CXW SellWatch Mgt", Prozedur `CreateSellWatchItem` (`src/Codeunits/Codeunit60305.CXWSellWatchMgt.al`, Zeile ~101–124), legt für jede SellWatch-Anfrage per `Item.TransferFields(ItemTemplate, true)` einen neuen Artikel aus einer Artikelvorlage an. Aktuell:

```al
local procedure CreateSellWatchItem(): Code[20]
var
    Item: Record Item;
    ItemTemplate: Record "Item Templ.";
    ItemUnitofMeasure: Record "Item Unit of Measure";
begin
    Item.Init();
    //TODO: Item Template einrichtenbar, Wo?; Evtl Nummernserie fuer SellWatch Artikel einrichten
    if not ItemTemplate.FindFirst() then
        Error(NoItemTemplateFoundErr);
    ...
```

`ItemTemplate.FindFirst()` ohne Filter liefert einen beliebigen (den nach Primärschlüssel ersten) Datensatz der Tabelle "Item Templ." — bei mehr als einer angelegten Artikelvorlage im System ist das Ergebnis fachlich nicht vorhersehbar und nicht steuerbar. Diese Änderung macht die zu verwendende Artikelvorlage über die Standard-Einkaufseinrichtung (`Purchases & Payables Setup`) explizit konfigurierbar.

## Goals / Non-Goals

**Goals:**
- Ein Sachbearbeiter kann in der Einkaufseinrichtung genau eine Artikelvorlage für die automatische SellWatch-Artikelanlage festlegen.
- Ist keine oder eine nicht mehr existierende Artikelvorlage konfiguriert, bricht die Verarbeitung mit einer eindeutigen, unterscheidbaren Fehlermeldung ab (kein stiller Rückfall auf eine zufällige Vorlage).
- Die Job-Queue-Ausführung von Codeunit 60305 hat die nötige Leseberechtigung auf das neue Setup-Feld.

**Non-Goals:**
- Keine eigene Nummernserie für SellWatch-Artikel (im ursprünglichen TODO als "evtl." erwähnt, aber nicht Teil dieser Anfrage) — bleibt offen für einen späteren Change.
- Keine Unterstützung mehrerer Artikelvorlagen (z. B. abhängig von Marke/Kategorie) — es wird genau eine, global gültige Artikelvorlage konfiguriert, passend zum aktuellen Umfang von `CreateSellWatchItem`.
- Keine Änderung an der übrigen Artikelanlage-Logik (Beschreibung, Basis-Mengeneinheit) — nur die Herkunft der Artikelvorlage ändert sich.

## Decisions

### Setup-Feld auf Standard-Tabelle "Purchases & Payables Setup" statt eigener CXW-Setup-Tabelle

Der Nutzer hat die Einkaufseinrichtung explizit als Ort für die neue Einrichtungsmöglichkeit benannt. Das Projekt hat zwar bereits eigene Singleton-Setup-Tabellen (z. B. "CXW General Sales Price Setup"), aber die SellWatch-Funktionalität hat aktuell keine solche eigene Setup-Tabelle — eine neue CXW-Setup-Tabelle nur für ein einzelnes Feld anzulegen wäre unverhältnismäßig gegenüber einer Table Extension auf die bereits vorhandene, fachlich passende Standard-Einkaufseinrichtung.

**Alternative verworfen**: Neue eigene Tabelle "CXW SellWatch Setup" — verworfen, da für ein einzelnes Konfigurationsfeld unnötiger Mehraufwand (eigene Karte, eigene Berechtigungen) gegenüber einer Erweiterung der ohnehin von Einkaufssachbearbeitern gepflegten Einkaufseinrichtung.

### Objekt-Zuordnung (nächste freie ID je Objekttyp im Bereich 60300–60349)

| ID | Objekttyp | Name |
|---|---|---|
| 60322 | TableExtension | CXW SW Purchases Setup (auf "Purchases & Payables Setup", neues Feld `CXW SW Item Template Code`, Field-ID 60300 — erste CXW-Erweiterung dieser Basistabelle) |
| 60330 | PageExtension | (auf Page "Purchases & Payables Setup", zeigt das neue Feld) |

Die tatsächliche Kollisionsfreiheit der Field-ID 60300 auf der Standardtabelle wird beim Kompilieren durch den AL-Compiler (idRanges-Prüfung) verbindlich bestätigt.

### Zwei getrennte Fehlermeldungen statt einer

`CreateSellWatchItem` unterscheidet jetzt zwei Fehlerfälle: (a) das Setup-Feld ist leer (Konfiguration fehlt) und (b) das Setup-Feld verweist auf eine Artikelvorlage, die nicht mehr existiert (z. B. gelöscht). Getrennte Meldungen helfen dem Anwender/Administrator, die Ursache ohne Rätselraten zu beheben, statt einer generischen "keine Artikelvorlage gefunden"-Meldung.

**Alternative verworfen**: Eine einzige generische Fehlermeldung wie bisher — verworfen, da sie nicht zwischen "nie konfiguriert" und "konfiguriert, aber ungültig geworden" unterscheidet und die Fehlersuche erschwert.

### Permission-Set-Ergänzung für den Job-Queue-Ausführungskontext

Codeunit 60305 läuft laut `OnRun`-Trigger job-queue-gesteuert; das zugehörige Permission Set "CXW SWChronWSAll" (60310) gewährt aktuell nur Zugriff auf die eigenen CXW-Tabellen, nicht auf Standard-Setup-Tabellen. Ohne explizite Ergänzung um `tabledata "Purchases & Payables Setup" = R` würde das Lesen des neuen Felds unter einem eingeschränkten Job-Queue-Benutzer fehlschlagen — genau die Art von Berechtigungsproblem, die in diesem Projekt bereits einmal konkret aufgetreten ist (Job-Queue-Berechtigungsfehler bei einem anderen Feature). Daher wird die Berechtigung proaktiv ergänzt statt erst bei einem Fehlschlag im Betrieb nachgezogen.

## Risks / Trade-offs

- **[Risiko]** Bestehende Umgebungen, in denen SellWatch bereits produktiv läuft (auf Basis der bisherigen `FindFirst()`-Logik), müssen nach dem Deployment zwingend das neue Setup-Feld befüllen, sonst bricht die Artikelanlage ab. → **Mitigation**: Klare Fehlermeldung mit Hinweis auf die Einkaufseinrichtung; README-Ergänzung zur Konfiguration nach dem Deployment (siehe Migration Plan).
- **[Trade-off]** Nur eine global gültige Artikelvorlage statt einer differenzierten Auswahl (z. B. nach Marke) — bewusst einfach gehalten, passend zum aktuellen Funktionsumfang; eine Erweiterung ist ein separater, hier nicht angefragter Schritt.

## Migration Plan

Reine Code-/Metadatenänderung ohne Datenmigration. Nach dem Deployment muss ein Sachbearbeiter in der Einkaufseinrichtung die zu verwendende Artikelvorlage einmalig auswählen — ohne diese Konfiguration bricht die nächste SellWatch-Artikelanlage kontrolliert mit Fehlermeldung ab (statt weiterhin eine zufällige Vorlage zu verwenden). Kein Rollback-Bedarf über das übliche App-Downgrade hinaus.

## Open Questions

- Eigene Nummernserie für SellWatch-Artikel (ursprünglich im TODO miterwähnt) — bleibt bewusst außerhalb dieses Changes; falls gewünscht, als separate Anfrage nachreichen.
