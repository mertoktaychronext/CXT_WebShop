## Context

Codeunit 60331 "CXW Process Workshop Lines" verarbeitet Workshop Lines im Status `WS checked` job-queue-gesteuert. Pro Zeile kapselt `TryProcessLine` (`[TryFunction]`) die gesamte Verarbeitung (`ProcessGenuineLine`/`ProcessNonGenuineLine`); ein Fehlschlag wird von `ProcessLineWithErrorHandling` abgefangen, das den Fehlertext per `GetLastErrorText()` in `"CXW Processing Error"` schreibt und `Commit()` aufruft, bevor die nächste Zeile startet. Der Status der Zeile bleibt dabei unverändert `WS checked`.

Damit ist eine bereits gescheiterte Zeile im nächsten Lauf ununterscheidbar von einer, die noch nie verarbeitet wurde — beide haben Status `WS checked`. Der Job-Queue-Lauf versucht dauerhaft fehlerhafte Zeilen (z. B. gesperrte Buchungsperiode) bei jedem Lauf erneut, ohne dass eine Auswertung ("wie viele Zeilen sind aktuell fehlerhaft?") ohne Blick in das Fehlertextfeld möglich ist.

## Goals / Non-Goals

**Goals:**
- Fehlgeschlagene Verarbeitung einer Workshop Line ist am Status `Error` erkennbar, ohne das Fehlertextfeld lesen zu müssen.
- Der Fehlertext der zuletzt fehlgeschlagenen Verarbeitung steht in einem klar benannten Feld `"CXW Last Error"`.
- Jeder Fehler, der während der Verarbeitung einer Zeile auftritt — unabhängig davon, an welcher Stelle im Verarbeitungspfad (Buchung, Attributübernahme, PO-Stornierung) — wird abgefangen und führt zu Status `Error` + gefülltem `"CXW Last Error"`.
- Eine erfolgreiche (erneute) Verarbeitung setzt `"CXW Last Error"` zurück, damit das Feld nie einen veralteten Fehlertext einer inzwischen erfolgreich verarbeiteten Zeile zeigt.
- Der neue Status `Error` fügt sich in die bestehende Statusregression-Sperre ein, ohne den bestehenden manuellen Retry-Weg (Status manuell zurück auf `WS checked` setzen, damit der nächste Job-Queue-Lauf die Zeile erneut versucht) zu blockieren.

**Non-Goals:**
- Kein automatischer Retry-Mechanismus (z. B. Retry-Zähler, Backoff) — das manuelle Zurücksetzen auf `WS checked` bleibt der vorgesehene Weg zur erneuten Verarbeitung, wie schon im Basis-Change vorgesehen.
- Keine Änderung an der API-Feldliste oder an den bestehenden, bereits gesperrten Statusregressionen (`WS checked` → `New`, weg von `Processed`).
- Keine Benachrichtigung (E-Mail, Teams etc.) bei Fehlern — bleibt außerhalb des Scopes.

## Decisions

### Umbenennung statt Zusatzfeld: `"CXW Processing Error"` → `"CXW Last Error"`

Das bestehende Feld `"CXW Processing Error"` (Feld-ID 23) erfüllt bereits exakt den Zweck "letzter Fehlertext der Verarbeitung". Ein zusätzliches, zweites Feld `"CXW Last Error"` würde zwei Felder mit überlappender Bedeutung erzeugen und Verwirrung stiften (welches Feld ist aktuell?). Die Feld-ID bleibt 23, nur AL-Bezeichner und Caption ändern sich.

**Alternative verworfen**: Neues Feld `"CXW Last Error"` zusätzlich zu `"CXW Processing Error"` anlegen — verworfen, da redundant und ohne fachlichen Mehrwert; beide Felder hätten in der Praxis immer denselben Inhalt.

**Voraussetzung für sichere Umbenennung**: Das Feld ist nicht Teil der API-Feldliste (Page 60339 exponiert es nicht) und laut Tasks-Stand von `purchase-workshop-integration` noch nicht produktiv im Einsatz (Kompilierung/manueller Test dort als "ausstehend" markiert). Eine Umbenennung ist daher ohne Datenmigration möglich. Sollte die App zwischenzeitlich doch bereits in einer Umgebung mit Daten veröffentlicht worden sein, ist vor dem Deployment dieser Änderung zu prüfen, ob stattdessen ein Rename über eine Upgrade-Prozedur nötig ist (siehe Risks).

### Statuswechsel auf `Error` nur aus `WS checked` heraus erlaubt

Der neue Enum-Wert `Error` wird ausschließlich vom Job-Queue-Codeunit gesetzt, wenn die Verarbeitung einer Zeile im Status `WS checked` fehlschlägt. Die externe Workshop-API (Page 60339, `status` ist beschreibbar) könnte technisch versuchen, den Status direkt auf `Error` zu setzen (z. B. aus `New`), was fachlich falsch wäre, da noch keine Verarbeitung stattgefunden hat. Der bestehende `OnModify`-Trigger der Tabelle wird um eine dritte Regel erweitert: ein Wechsel auf `Error` ist nur zulässig, wenn der bisherige Status `WS checked` war; jeder andere Ausgangsstatus wird mit derselben `StatusRegressionErr`-Fehlermeldung wie die bestehenden Regeln blockiert.

Der Rückweg von `Error` zurück auf `WS checked` bleibt explizit erlaubt (kein neuer Guard dafür) — das ist der vorgesehene manuelle Retry-Pfad.

**Alternative verworfen**: Keine Einschränkung, jeder Status kann auf `Error` wechseln — verworfen, da dies der externen API erlauben würde, einen Verarbeitungsfehler vorzutäuschen, der nie stattgefunden hat, was die Aussagekraft des Status für die interne Nachverfolgung untergräbt.

### Fehlerbehandlung im Codeunit: Status- und Feldsetzung zentral in `ProcessLineWithErrorHandling`

Die bestehende Struktur (äußere `[TryFunction]` `TryProcessLine`, die die gesamte Verarbeitung einer Zeile kapselt) bleibt unverändert — sie fängt bereits jeden Laufzeitfehler im gesamten Verarbeitungspfad ab (Buchung via `Codeunit.Run(Codeunit::"Purch.-Post", ...)`, Attributübernahme, PO-Stornierung), da AL-`TryFunction`s Fehler aus dem gesamten aufgerufenen Prozedurbaum abfangen. Es ist keine zusätzliche Try-Kapselung an weiteren Stellen nötig, um "alle Fehler" abzufangen — das leistet die bestehende äußere `TryFunction` bereits vollständig.

Geändert wird nur der Fehlerfall in `ProcessLineWithErrorHandling`: zusätzlich zum bisherigen Schreiben von `GetLastErrorText()` wird `"CXW Status" := "CXW Status"::Error` gesetzt, bevor `Modify()` + `Commit()` erfolgt. Da innerhalb der fehlgeschlagenen `TryFunction` alle Datenbankänderungen seit dem letzten `Commit()` automatisch zurückgerollt werden (u. a. ein evtl. bereits erfolgter `WorkshopLine.Modify()` in `ProcessNonGenuineLine`, der Status probeweise auf `Processed` setzt, bevor die PO gelöscht wird), ist der Zustand der Zeile beim erneuten `Get()` in `ProcessLineWithErrorHandling` konsistent auf dem Stand vor dem fehlgeschlagenen Versuch.

Im Erfolgsfall (`TryProcessLine` liefert `true`) wird `"CXW Last Error"` zurückgesetzt: `ProcessGenuineLine` und `ProcessNonGenuineLine` setzen beide unmittelbar vor ihrem abschließenden `Modify()` (Status := Processed) zusätzlich `"CXW Last Error" := ''`, damit eine erfolgreich (re-)verarbeitete Zeile nie einen veralteten Fehlertext zeigt.

### Keine Änderung an der API-Feldliste

`"CXW Last Error"` wird — wie zuvor `"CXW Processing Error"` — nicht in Page 60339 exponiert. Der neue Statuswert `Error` ist über das bestehende Feld `status` automatisch sichtbar, ohne Page-Änderung.

## Risks / Trade-offs

- **[Risiko]** Falls `"CXW Processing Error"` in der Zwischenzeit bereits in einer Umgebung mit Bestandsdaten veröffentlicht wurde, führt eine reine Umbenennung im AL-Code ohne Rename-Handling zu Datenverlust in diesem Feld (neue Spalte statt Rename). → **Mitigation**: Vor dem Deployment dieser Änderung `git log`/Deployment-Historie der Basis-Änderung prüfen; falls bereits produktiv, `RenameField`-Upgrade-Schritt ergänzen statt direkter Umbenennung.
- **[Risiko]** Die neue Statusregel ("Error nur aus WS checked") könnte künftige, heute nicht vorgesehene Workflows blockieren, in denen der Status direkt auf Error gesetzt werden soll (z. B. manuelle Fehlermarkierung durch einen Sachbearbeiter). → **Mitigation**: Out of Scope; falls ein solcher Bedarf entsteht, kann die Regel in einem späteren Change gelockert werden.
- **[Trade-off]** Kein automatischer Retry/Backoff — dauerhaft fehlerhafte Zeilen bleiben im Status `Error`, bis jemand sie manuell auf `WS checked` zurücksetzt. Das ist bewusst so gewählt, um keine Endlosschleife wiederholt scheiternder Buchungen im Job-Queue-Lauf zu erzeugen.

## Migration Plan

Reine Code-/Metadatenänderung ohne Datenmigration (unter der Annahme aus Risks, dass noch keine Produktivdaten im Feld `"CXW Processing Error"` existieren). Deployment über den normalen App-Publish-Zyklus zusammen mit oder nach `purchase-workshop-integration`. Kein Rollback-Bedarf über das übliche App-Downgrade hinaus.

## Open Questions

- Ist `purchase-workshop-integration` bereits in einer Umgebung mit Bestandsdaten veröffentlicht? Falls ja, ist vor der Umsetzung ein Rename-Upgrade-Schritt statt einer direkten Umbenennung nötig (siehe Risks).
