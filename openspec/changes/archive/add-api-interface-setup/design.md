## Context

Codeunit 51000 "SL Export Gateway Sales Price" baut bereits ein JSON aus einem Verkaufspreis-Datensatz und schreibt es in Table 51004 "SL Sales Price Outbound File" (lokale Ablage, kein Versand). Es gibt noch keine Möglichkeit, dieses JSON tatsächlich an ein externes System zu übertragen, und keine Einrichtung dafür. Der Kunde möchte diese Einrichtung von Anfang an generisch anlegen, damit nicht für jede künftige API-Anbindung eine eigene Setup-Tabelle entsteht.

Alle neuen Objekte liegen im Kundennummernkreis 51000–51049 (siehe `app.json`, `idRanges`). Nächste freie IDs: Tabellen ab 51007, Seiten ab 51003.

## Goals / Non-Goals

**Goals:**
- Generische Tabelle, in der ein Key User beliebig viele API-Schnittstellen einrichten kann (Endpunkt, Authentifizierung, Aktiv-Kennzeichen, referenzierte Objektart).
- "SL General Sales Price Setup" bekommt ein Feld, mit dem genau eine dieser API-Einrichtungen als "die" Schnittstelle für den Verkaufspreis-Export ausgewählt wird.
- Codeunit 51000 sendet das JSON per HTTP an den in dieser Auswahl hinterlegten Endpunkt und protokolliert Erfolg/Fehler am jeweiligen Outbound-File-Eintrag (Table 51004, vorhandenes Status-Feld).
- Zugangsdaten (API-Key/Token) werden **nicht** im Klartext in einer Tabelle abgelegt, sondern in Isolated Storage.

**Non-Goals:**
- Kein generischer "API-Aufruf-Interpreter" (z. B. konfigurierbare Feldzuordnung/Mapping-Regeln per UI) — die Auswahl der Objektart dient nur der Zuordnung/Validierung, nicht der dynamischen Steuerung, *welche* Felder gesendet werden. Das JSON-Mapping bleibt Code (wie in Codeunit 51000 bereits vorhanden).
- Keine Warteschlange/Retry-Mechanik (Job Queue) für fehlgeschlagene Sendungen — passt zum bestehenden, dokumentierten Zustand, dass der dateibasierte Import/Export insgesamt noch nicht an eine Job Queue angebunden ist (siehe `docs/SCHWACHSTELLEN.md`, N3). Ein fehlgeschlagener Versand wird nur als Fehler markiert, nicht automatisch wiederholt.
- Keine OAuth2-Client-Credentials-Flows im ersten Schritt — nur "Ohne Authentifizierung" und "API-Key im Header", erweiterbar über das Enum.

## Decisions

**1. Auswahl-Mechanismus: direktes Referenzfeld statt dynamischer Tabellennummern-Suche**
`SL General Sales Price Setup` bekommt ein Feld `API Interface Code` (Code[20], `TableRelation` auf die neue Einrichtungstabelle). Codeunit 51000 liest diesen Code direkt, statt zur Laufzeit nach einer passenden Schnittstelle für Tabelle "Sales Price" zu suchen.
*Alternative verworfen:* Dynamische Suche nach einer aktiven Schnittstelle, deren "Objektart"-Feld zufällig auf "Sales Price" zeigt — mehrdeutig, sobald zwei Schnittstellen dieselbe Tabelle referenzieren, und schwerer nachvollziehbar für den Key User als eine explizite Auswahl.

**2. "Objektart" auf der Einrichtungstabelle bleibt informativ/validierend**
Das Feld `Source Table No.` (TableRelation auf `AllObjWithCaption`, gefiltert auf Objekttyp Tabelle) beschreibt, welche Tabelle diese Schnittstelle erwartet. Codeunit 51000 prüft beim Versand per `TestField`, dass die referenzierte Schnittstelle tatsächlich `Table::"Sales Price"` als Quelle deklariert — verhindert, dass eine für einen anderen Zweck eingerichtete Schnittstelle versehentlich für den Preisexport ausgewählt wird.
*Alternative verworfen:* Objektart weglassen — spart ein Feld, verliert aber genau die Fehlprüfung, die eine generische, für mehrere Zwecke nutzbare Tabelle braucht.

**3. Zugangsdaten in Isolated Storage, nicht als Tabellenfeld**
Die Einrichtungstabelle speichert nur einen internen Schlüssel (`Entry No.` als Basis für den Isolated-Storage-Key); der eigentliche API-Key/Token wird über `IsolatedStorage.Set(...)` mit `DataScope::Module` abgelegt und nie im Klartext auf der Karte angezeigt (Eingabe über ein `ExtendedDatatype = Masked`-Dialogfeld, das direkt in Isolated Storage schreibt statt in ein normales Tabellenfeld). Dieselbe Begründung wie bei den bereits dokumentierten Sicherheits-Findings dieses Projekts (`docs/SCHWACHSTELLEN.md`): Zugangsdaten gehören nicht in normale, für alle Leser mit Tabellenzugriff sichtbare Felder.
*Alternative verworfen:* Klartextfeld `Text` für den API-Key — einfacher umzusetzen, aber ein Sicherheitsproblem (jeder mit Lesezugriff auf die Tabelle sieht den Schlüssel, inkl. in Backups/Exports).

**4. HTTP-Versand synchron in Codeunit 51000, kein neues Warteschlangen-Konzept**
Der Versand erfolgt synchron im Rahmen der bestehenden Aufrufe (Action "Upload Sales Price", EventSubscriber auf `OnAfterSalesPriceModify`) über `HttpClient`/`HttpRequestMessage`/`HttpContent` (natives AL, kein DotNet). Bei Fehlschlag wird der Outbound-File-Eintrag (Table 51004) auf Status `Error` gesetzt; die eigentliche Preisfreigabe/-verarbeitung wird dadurch **nicht** rückgängig gemacht oder blockiert (Versandfehler ist kein Grund, die fachliche Freigabe zu verwerfen).
*Alternative verworfen:* Asynchroner Versand über Job Queue — konsistenter mit "richtig" gelöster Integration, aber deutlich größerer Umfang und hängt von der noch offenen generellen Job-Queue-Anbindung dieses Projekts ab (siehe Non-Goals).

## Risks / Trade-offs

- **[Risiko] Synchroner HTTP-Call blockiert die UI-Aktion bei langsamem/nicht erreichbarem Zielsystem** → Mitigation: Timeout auf dem `HttpClient` explizit setzen (z. B. 30s) und einen verständlichen Fehler anzeigen statt eines undefinierten Hängers.
- **[Risiko] Kein Retry bei transienten Netzwerkfehlern** → Mitigation: bewusst akzeptiert für den ersten Schritt (siehe Non-Goals); Status `Error` auf Table 51004 und auf dem Enum-Feld "Export Status" (Table 51001) macht fehlgeschlagene Sendungen sichtbar. "Upload Sales Price" verarbeitet Zeilen mit Status `Not Sent`/`Error` automatisch erneut; bereits erfolgreich versendete Zeilen (`Sent`) werden nur nach ausdrücklicher Bestätigung erneut gesendet (siehe Open Questions).
- **[Trade-off] Kein UI-Mapping-Editor** → bewusst nicht gebaut (siehe Non-Goals), hält die generische Tabelle schlank statt sie zu einem eigenen kleinen Integrations-Framework auszubauen.

## Migration Plan

Rein additiv: neue Tabelle, neue Seite, ein neues optionales Feld auf Tab51000 (leer = kein Versand konfiguriert, bestehende "Upload Sales Price"-Funktion bliebe dann ohne HTTP-Versand nutzbar oder bricht kontrolliert mit `TestField`-Fehler ab, siehe Tasks). Kein Rollback-Bedarf über das Entfernen der neuen Objekte hinaus.

## Open Questions

Beide Fragen wurden geklärt:

- **Export-Status statt Boolean (entschieden):** Das bisherige Boolean-Feld "Export Processed" auf Table 51001 wurde bereits durch das Enum-Feld "Export Status" (`Not Sent` / `Sent` / `Error`) ersetzt (Enum 51003 "SL Sales Price Export Status", umgesetzt außerhalb dieses Changes, da das Feld schon vor diesem Proposal existierte). Die Aktion "Upload Sales Price" verarbeitet automatisch alle Zeilen mit Status `Not Sent` oder `Error`; bei mindestens einer bereits mit `Sent` markierten Zeile fragt eine `Confirm`-Abfrage einmalig, ob diese erneut gesendet werden sollen, statt sie stillschweigend zu überspringen oder erneut zu senden. Damit ist Codeunit 51000 (Task 4.3/4.4) so anzubinden, dass es dieses bestehende Enum nutzt statt ein neues Statuskonzept auf Table 51001 einzuführen.
- **Authentifizierungsarten (entschieden):** Es ist noch nicht bekannt, welche Authentifizierung das konkrete Zielsystem benötigt. Das Enum "SL API Auth Type" wird daher von Anfang an mit **beiden** gängigen Varianten angelegt (kein Auth, API-Key im Header, Basic Auth) statt nur einer — die tatsächliche Auswahl erfolgt später pro Schnittstellen-Einrichtung durch den Key User, nicht im Code.
