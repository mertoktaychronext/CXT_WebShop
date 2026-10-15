## Context

CHX.Webshop (27.0.0.18) hängt von CHX.Base (≥ 28.0.0.0) und ChronextBC ab, nicht direkt von der Salini Base App. Das Kennzeichen „Differenzbesteuerung" wird an vier Stellen von Artikelposten gelesen:

| Objekt | Stelle | Zweck |
|---|---|---|
| Cod. 60348 `CXW Availability Change Mgt.` | `QueueItemLedgerEntryChange` | Besteuerungsart beim Einreihen einer Verfügbarkeitsänderung |
| Cod. 60348 | Aktualisierung des Verfügbarkeitseintrags | `"CXW Diff. Taxation Purchase"` aus dem Posten |
| Cod. 60348 | `GetAvailableInventoryQuantity` | `SetRange` auf offene Posten je Besteuerungsart |
| Cod. 60350 `CXW Realtime Inventory Mgt.` | Erzeugen eines Echtzeitbestands | `"CXW Differential Taxation"` |

Mit CHX.Base 28.0.0.1 (Change `margin-taxation-to-salini-base`) wird `"CXB Margin Taxation"` (60200) `ObsoleteState = Pending` und nicht mehr gefüllt; das Upgrade kopiert alle „Ja"-Werte nach `"SLPSBC Margin Taxation"` (5729377, Salini Base App 28.0.0.13) und schaltet in der Salini Base App „Differenzbesteuerung verwenden" ein.

## Goals / Non-Goals

**Goals:**
- Webshop-Bestände je Besteuerungsart bleiben nach dem Umstieg korrekt.
- Kein eigener Upgrade-Code, keine Schema-Änderung.

**Non-Goals:**
- Änderung der Berechnung oder der Webshop-Schnittstelle.
- Kennzeichnung von Einkaufs-Artikelposten (heute weder durch CHX.Base noch durch die Salini Base App; offene Frage in beiden Changes).

## Decisions

### D1 – Direkter Feldtausch
Die vier Zugriffe lesen `"SLPSBC Margin Taxation"` statt `"CXB Margin Taxation"`. Keine Umschaltlogik („altes Feld, falls neues leer"), weil das CHX.Base-Upgrade alle Werte vorab übernimmt und beide Apps gemeinsam ausgeliefert werden.
*Alternative:* Übergangsweise beide Felder per `or` lesen – verworfen: würde nach dem Upgrade nichts zusätzlich liefern, aber bei einem späteren Ausschalten der Differenzbesteuerung in der Base App alte Werte unkontrolliert weiterverwenden.

### D2 – Direkte Abhängigkeit auf die Salini Base App
`app.json`: Salini Base App (`bea6c3c4-7d98-4740-ba0c-1a3c7e1ff49a`, Publisher „Salini Life GmbH") ≥ 28.0.0.13; CHX.Base ≥ 28.0.0.1. Felder einer nur transitiv erreichbaren App sind in AL nicht sichtbar.
*Hinweis:* CHX.Webshop steht auf `application` 26.0, die Salini Base App auf 27.0. Beim Herunterladen der Symbole prüfen; falls der Compiler die Kombination ablehnt, `application`/`platform` auf 27.0.0.0 anheben.

### D3 – Gemeinsame Auslieferung
CHX.Webshop 27.0.0.26 wird im selben Wartungsfenster wie CHX.Base 28.0.0.1 installiert. Die Abhängigkeit auf CHX.Base ≥ 28.0.0.1 erzwingt die Reihenfolge.

## Risks / Trade-offs

- [Webshop vor CHX.Base installiert] → durch die Mindestversion CHX.Base 28.0.0.1 ausgeschlossen.
- [„Differenzbesteuerung verwenden" in der Base App später ausgeschaltet] → neue Posten tragen „Nein", Webshop meldet sie als regelbesteuert. → Hinweis im Key-User-Handbuch der Salini Base App; das CHX.Base-Upgrade schaltet den Schalter ein.
- [Bereits eingereihte Verfügbarkeitsänderungen] → enthalten den Wert zum Zeitpunkt des Einreihens; bei der Aktualisierung wird er aus dem Posten neu gelesen (jetzt aus dem Base-App-Feld, nach dem Upgrade identisch).

## Migration Plan

1. Mit CHX.Base 28.0.0.1 im selben Wartungsfenster installieren (siehe Migration Plan der CHX.Base-Change).
2. Nach dem Update: Verfügbarkeitsänderung und Echtzeitbestand für einen bekannten differenzbesteuerten und einen regelbesteuerten Artikel prüfen.

**Rollback:** nur zusammen mit CHX.Base; vorgesehen ist Korrektur nach vorn.

## Open Questions

- Sollen Einkaufs-Artikelposten das Kennzeichen erhalten? `GetAvailableInventoryQuantity` filtert offene (meist Zugangs-)Posten nach dem Kennzeichen; heute sind Einkaufsposten immer „Nein", Zugänge aus dem Artikel Buch.-Blatt dagegen gekennzeichnet. Klärung in der Salini Base App.
