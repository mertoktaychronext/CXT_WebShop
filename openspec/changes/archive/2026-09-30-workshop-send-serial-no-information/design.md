## Context

Heutiger Ablauf von „Send to Workshop“ (`PagExt60328 "CXW Workshop Purchase Order"`, je offener Artikelzeile):

```
Confirm „Ist Artikel … angekommen?“ ── Nein ─► "CXW Not Arrived" := true
   │ Ja
   ▼
Page 60340 "CXW Serial No. Input" (StandardDialog, Text[50])
   │ Abbruch / leer ─► Fehlerliste
   ▼
PurchLine."CXW Manufacturer Serial No." := Eingabe; "CXW Sent to Workshop" := true
CreateWorkshopLine (Herstellernummer, Bestell-/Uhrendaten, Attribut-Vorbefüllung)
```

Relevante Fakten:
- CHX.Base 27.0.3.5 erweitert `Serial No. Information` (Tabelle/Page 6504) um `"CXB Manufacturer Serial No."` (Code[50]), `"CXB Box Present"`, `"CXB Papers Present"`, Bin-Codes, und den `Item Tracking Code` um Pflicht-Kennzeichen dafür. Die öffentliche Prozedur `"CXB Serial No. Bin Enforcement".CheckPresenceMandatory(ItemNo, VariantCode, SerialNo)` wirft einen Fehler, wenn Pflichtangaben fehlen.
- Codeunit 60331 bucht bei echter Uhr den Wareneingang per `Purch.-Post`; bei seriennummernpflichtigen Artikeln braucht die Einkaufszeile dafür eine Artikelverfolgung.
- Base App 28.5: `Codeunit "Create Reserv. Entry"` (`CreateReservEntryFor`, `CreateEntry`), `Codeunit "No. Series".GetNextNo`.
- Eine Werkstattzeile entspricht einer Einkaufszeile und einer Uhr.

## Goals / Non-Goals

**Goals:**
- Seriennummer je Zeile aus der Artikelverfolgung verwenden oder die nächste aus der Artikel-Nummernserie ziehen und als Artikelverfolgung anhängen.
- Herstellernummer (und Box/Papiere) auf der Standard-Seriennr.-Informationskarte erfassen; eine einzige Datenquelle statt Text nur auf EK-/Werkstattzeile.
- Wareneingang durch Codeunit 60331 für SN-Artikel ohne manuelle Artikelverfolgung ermöglichen.

**Non-Goals:**
- Zeilen mit Menge ≠ 1 (mehrere Seriennummern je Zeile).
- Chargen-/Paketverfolgung.
- BC-Seriennummer zusätzlich auf Werkstattzeile/API ausgeben (nur Herstellernummer wie bisher).
- Änderungen an Codeunit 60331, am Werkstatt-API oder an CHX.Base.
- Prüfung, ob eine gezogene Nummer bereits anderweitig verwendet wurde (Standardverhalten wie „Seriennr. zuweisen“).

## Decisions

### D1: Neuer Ablauf je Zeile

```
Confirm angekommen? ── Nein ─► Not Arrived (unverändert)
   │ Ja
   ▼
Prüfen: Menge (Basis) = 1 ─────────────── sonst ─► Fehlerliste
Prüfen: Artikelverfolgungscode mit
        "SN Purchase Inbound Tracking" ─── sonst ─► Fehlerliste
   ▼
Seriennr. in Artikelverfolgung der EK-Zeile? (Reservation Entry,
  Source Type 39 / Subtype / ID / Ref No., "Serial No." <> '')
   ├─ ja  ─► verwenden
   └─ nein ─► Item."Serial Nos." leer? ─► Fehlerliste
             GetNextNo(Item."Serial Nos.")
             Artikelverfolgung anlegen (Create Reserv. Entry, Menge 1, Überschuss)
   ▼
"Serial No. Information" (Artikel, Variante, SN) holen / anlegen
Commit()   (RunModal ist in Schreibtransaktionen nicht erlaubt, siehe D8)
Page.RunModal(Page::"Serial No. Information Card", SerialNoInfo)
   ▼
SerialNoInfo neu lesen
"CXB Manufacturer Serial No." leer? ─► Fehlerliste
CheckPresenceMandatory (in TryFunction) fehlgeschlagen? ─► Fehlerliste (Meldungstext)
   ▼
PurchLine."CXW Manufacturer Serial No." := Herstellernummer; Sent := true
CreateWorkshopLine (unverändert)
```

### D2: Artikelverfolgung vor dem Öffnen der Karte anlegen
Die gezogene Nummer wird sofort als Artikelverfolgung an die Einkaufszeile gehängt. Bricht der Benutzer ab oder lässt die Herstellernummer leer, bleiben Nummer, Artikelverfolgung und Seriennr.-Information bestehen; beim nächsten „Send to Workshop“ wird dieselbe Nummer über die Artikelverfolgung wiedergefunden (keine verschwendeten Nummern, keine verwaisten Seriennr.-Informationen).
- *Alternative:* erst nach erfolgreicher Karte anlegen → bei Abbruch verwaiste Seriennr.-Information bzw. beim Retry neue Nummer. Verworfen.

### D3: Rückgabewert der Karte wird ignoriert, Daten zählen
Page 6504 ist eine Card-Page ohne OK/Abbrechen. Entscheidend ist, was nach dem Schließen im Datensatz steht: Herstellernummer leer → nicht senden. Damit entfällt die bisherige Unterscheidung „Abbruch“ vs. „leer“ (`SerialNoInputCancelledErr` entfällt).

### D4: CHX.Base-Pflichtprüfung per TryFunction
`CheckPresenceMandatory` ist rein lesend und wirft bei fehlenden Angaben einen Fehler. Aufruf in einer lokalen `[TryFunction]`, damit der Fehler als Zeilenfehler in die Fehlerliste geht, statt die ganze Aktion abzubrechen. Da die TryFunction nichts schreibt, ist das Rollback-Verhalten unkritisch.

### D5: Logik in Codeunit 60335 „CXW Workshop Line Mgt.“
Neue Prozeduren (intern, von der Page-Extension aufgerufen):
- `FindPurchLineSerialNo(PurchLine): Code[50]`
- `AssignNextSerialNo(PurchLine): Code[50]` (GetNextNo + `Create Reserv. Entry`)
- `GetOrCreateSerialNoInformation(ItemNo, VariantCode, SerialNo; var SerialNoInfo)`
- `IsSerialNoTracked(ItemNo): Boolean`
Die Page-Extension behält Ablauf, Dialoge und Fehlerliste. So bleibt die Page schlank und die Serienlogik ist wiederverwendbar.

### D6: Artikelverfolgung per `Create Reserv. Entry`
`CreateReservEntryFor(Database::"Purchase Line", DocType, DocNo, '', 0, LineNo, QtyPerUOM, 1, 1, ForReservEntry mit "Serial No.")` + `CreateEntry(Item, Variant, Location, Description, Expected Receipt Date, 0D, 0, Status::Surplus)` – Standardweg, wie ihn auch „Seriennr. zuweisen“ nutzt. Exakte Signatur im Base App 28.5 geprüft.

### D7: Page 60340 entfernen
Wird nicht mehr benötigt; Datei und Permission-Set-Eintrag entfallen. Übersetzungseinheiten fallen beim Build aus der `.g.xlf` und werden aus `de-DE.xlf` entfernt.

## Risks / Trade-offs

- [Watch-Artikel sind heute evtl. nicht seriennummernverfolgt → nach dem Update lassen sie sich nicht mehr senden] → Vor Go-live Artikelverfolgungscode (SN beim Einkauf) und Seriennr.-Nummernserie an den Artikeln bzw. über die SellWatch-Artikelvorlagen einrichten; in Key-User-Handbuch und Release-Notiz aufnehmen.
- [Gezogene Nummer existiert bereits (z. B. manuell früher vergeben)] → wie im Standard keine Prüfung; Nummernserie sauber vom manuellen Bereich trennen.
- [CHX.Base-Enforcement feuert ggf. auch beim späteren Buchen/Validieren] → durch die Vorabprüfung (D4) fällt es schon beim Senden auf.
- [Modaler Dialog nach Schreibvorgängen: `Page.RunModal` ist in einer offenen Schreibtransaktion nicht erlaubt (im ersten Sandbox-Test aufgetreten)] → `Commit()` direkt vor dem Öffnen der Karte (D8). Die ursprüngliche Annahme, dass RunModal im Action-Trigger nach Schreibvorgängen zulässig sei, war falsch.
- [Benutzer ändert in der Karte nichts, schließt sie] → Herstellernummer leer → Zeile nicht gesendet, beim nächsten Versuch wieder dieselbe Karte.

## Migration Plan

1. Einrichtung der Watch-Artikel prüfen/ergänzen (Artikelverfolgungscode mit SN-Einkaufsverfolgung, Seriennr.-Nummernserie).
2. Deployment; keine Datenmigration. Bereits gesendete Zeilen/Werkstattzeilen bleiben unverändert.
3. Rollback: Vorversion installieren (Page 60340 kommt zurück); angelegte Artikelverfolgungen/Seriennr.-Informationen bleiben als Standarddaten bestehen und sind unschädlich.

## Open Questions

- Soll die BC-Seriennummer später zusätzlich an der Werkstattzeile/im Werkstatt-API erscheinen? (Nicht Teil dieser Änderung.)

## Nachtrag aus dem Test

### D8: `Commit()` vor dem Öffnen der Seriennr.-Informationskarte
`Page.RunModal` ist in einer offenen Schreibtransaktion nicht erlaubt (Laufzeitfehler „Form.RunModal ist in Schreibtransaktionen nicht erlaubt“). Vor dem Öffnen der Karte stehen bereits Schreibvorgänge an (gezogene Nummer, Artikelverfolgung, Seriennr.-Information, ggf. vorherige Zeilen). Deshalb wird unmittelbar vor `Page.RunModal` committet.
- Passt zu D2: Nummer, Artikelverfolgung und Seriennr.-Information sollen bei Abbruch ohnehin erhalten bleiben.
- Folge: Bereits abgeschlossene Zeilen desselben Laufs (Werkstattzeile angelegt, "Not Arrived" gesetzt) sind ebenfalls festgeschrieben; ein späterer Fehler in derselben Aktion rollt nur die aktuelle Zeile zurück. Das ist gewollt, da jede Zeile unabhängig ist.
