## Context

Heute (`Codeunit 60305 "CXW SellWatch Mgt"`):

```
OnRun
 └─ ValidateAndCreateVendor
      SellWatchVendorInfo.SetRange("CXW Created", false)
      FindSet ── repeat ──────────────────────────────┐
         Kreditor suchen / Insert(Vendor, Bank)      │  alles in EINER
         CreatePurchaseOrder                         │  Transaktion,
           PH.Insert, CreateSellWatchItem, PL.Insert │  kein Commit
           Release, SellWatchVendorInfo.Modify       │
      until Next = 0 ────────────────────────────────┘
   Error irgendwo  ⇒  kompletter Lauf wird zurückgerollt, Job Queue = Fehler
```

Der Zustand steckt in globalen Variablen der Codeunit (`SellWatchVendorInfo`, `VendorRec`, `PHRec`, `PLRec`, …). `CreatePurchaseOrderinBV`/`CreatePurchaseOrderinGmBH` sind toter Code, rufen aber `CreatePurchaseOrder` auf.

Im Projekt gibt es zwei Fehlerbehandlungsmuster:
- `[TryFunction]` + Fehlerfeld (Codeunit 60331, 60345)
- `Commit` + `Codeunit.Run` + Fehlerfeld (Codeunit 60332 → 60334, Page 60322 → Codeunit 60333)

## Goals / Non-Goals

**Goals:**
- Pro Angebot eine eigene Transaktion mit vollständigem Rollback im Fehlerfall.
- Fehlertext und -zeitpunkt am Angebot, sichtbar in der Übersicht.
- Automatische Wiederholung beim nächsten Lauf.
- Bestehende Fachlogik (Kreditor, Bestellung, Artikel) unverändert.

**Non-Goals:**
- Fehlerhistorie (mehrere Fehler je Angebot) oder eigene Protokolltabelle.
- Telemetrie (`Session.LogMessage`) oder Benachrichtigungen bei Fehlern.
- Obergrenze für Wiederholungsversuche.
- Aufräumen des toten Codes (`CreatePurchaseOrderinBV`/`GmBH`) und Case-Insensitivität von `'commission'`.
- Cue/Kachel für fehlerhafte Angebote im Rollencenter.

## Decisions

### D1: `Codeunit.Run` statt `[TryFunction]`
Eine TryFunction rollt Datenbankschreibvorgänge **nicht** zurück. Bei SellWatch entstehen mehrere Datensätze nacheinander (Kreditor, Bankverbindung, Bestellkopf, Artikel, Artikeleinheit, Dimensionen, Bestellzeile); scheitert z. B. die Artikelanlage, blieben Kreditor und Bestellkopf ohne Zeile stehen. `Codeunit.Run` mit ausgewertetem Rückgabewert rollt alle Änderungen dieses Aufrufs zurück.
- Voraussetzung: vor jedem `Codeunit.Run` ein `Commit()` (sonst Laufzeitfehler, weil Codeunit.Run mit Rückgabewert in einer offenen Schreibtransaktion nicht erlaubt ist).
- *Alternative:* TryFunction wie in 60331/60345 → verworfen wegen fehlender Rollback-Garantie.

### D2: Neuer Worker-Codeunit, Logik bleibt in 60305
Neuer `codeunit 60351 "CXW SellWatch Process Offer"` mit `TableNo = "CXW SellWatch Vendor Info"`; `OnRun` ruft `SellWatchMgt.ProcessOffer(Rec)` auf. In 60305 wird der bisherige Schleifenrumpf von `ValidateAndCreateVendor` in die neue `internal procedure ProcessOffer(var SellWatchOffer: Record "CXW SellWatch Vendor Info")` verschoben (setzt die globale `SellWatchVendorInfo` und läuft dann Kreditorsuche/-anlage + `CreatePurchaseOrder` wie bisher).
- Jeder `Codeunit.Run` erzeugt eine frische Worker-Instanz, die wiederum eine frische 60305-Instanz nutzt → keine globalen Zustände (`VendorRec`, `PHRec`) aus dem vorherigen Angebot.
- *Alternative:* 60305 selbst `TableNo` geben → bricht den bestehenden Aufgabenwarteschlangenposten (Job Queue übergibt „Job Queue Entry“). Verworfen.
- *Alternative:* gesamte Logik in den neuen Codeunit verschieben → großer Diff, toter Code in 60305 bräche. Verworfen.
- Objekt-ID 60351: zum Zeitpunkt des Entwurfs frei (Codeunits bis 60350 belegt); vor Umsetzung gegen parallele Branches prüfen.

### D3: Schleife über vorab gesammelte Eintragsnummern
`ValidateAndCreateVendor` sammelt zuerst die `"CXW Entry No"` aller offenen Angebote in einer `List of [Integer]` und verarbeitet danach jede Nummer einzeln (`Get` → `Commit` → `ClearLastError` → `Codeunit.Run`). Damit wird nicht über ein Recordset iteriert, dessen Filterfeld (`"CXW Created"`) zwischendurch in eigenen Transaktionen geändert und committet wird.

```
foreach EntryNo in OpenEntryNos:
    Offer.Get(EntryNo)
    Commit(); ClearLastError()
    if Codeunit.Run(Codeunit::"CXW SellWatch Process Offer", Offer) then
        (Fehlerfelder wurden im Worker geleert)
    else
        Offer.Get(EntryNo)
        Offer."CXW Last Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(...))
        Offer."CXW Last Error DateTime" := CurrentDateTime()
        Offer.Modify()
    Commit()
```

### D4: Fehlerfelder auf Table 60300, im Erfolgsfall im selben Modify geleert
- `field(46; "CXW Last Error"; Text[250])`, Caption „Last Error“, `Editable = false`
- `field(47; "CXW Last Error DateTime"; DateTime)`, Caption „Last Error Date/Time“, `Editable = false`
- Geleert werden sie in `CreatePurchaseOrder` beim bestehenden `SellWatchVendorInfo.Modify()`, das `"CXW Created" := true` setzt → Erfolg und „Fehler weg“ sind atomar.
- Länge 250 analog zu `"CXW Last Error"` (Table 60318) und `"CXW Error Text"` (Table 60341).
- *Alternative:* Status-Enum (Offen/Fehler/Angelegt) → `"CXW Created"` bleibt die fachliche Wahrheit, API-Spec und Übersicht hängen daran; ein zweites Statusfeld würde Redundanz schaffen. Fehler = „Fehlertext nicht leer“.

### D5: Übersicht und API
- Page 60307: Felder „Last Error“ und „Last Error Date/Time“ ergänzen, `StyleExpr` = `Unfavorable`, wenn `"CXW Last Error" <> ''` (für SRid- und Fehlerfeld). Seite ist bereits `Editable = false`.
- Page 60337 (API) veröffentlicht die neuen Felder nicht → nicht schreib- oder lesbar von außen; keine Änderung der Spec `sellwatch-inbound-api` nötig.

### D6: Permission Set
`CXW SWChronWSAll` erhält `codeunit "CXW SellWatch Process Offer" = X`.

## Risks / Trade-offs

- [Job-Queue-Status zeigt Fehler nicht mehr an; bisher fiel ein Problem über fehlgeschlagene Aufgabenwarteschlangenposten auf] → Fehler in der Übersicht hervorheben; im Key-User-Handbuch beschreiben, wie man nach Angeboten mit Fehlertext filtert. Benachrichtigung/Cue ggf. als Folge-Change.
- [Dauerhaft fehlerhafte Angebote werden bei jedem Lauf erneut versucht] → vertretbar (je Angebot nur ein fehlschlagender Versuch pro Lauf, Fehlertext wird überschrieben, kein Datenwachstum).
- [`Commit` je Angebot ändert das Transaktionsverhalten – Aufrufer, die 60305 innerhalb einer eigenen Transaktion starten, bekämen Teil-Commits] → Laut Code gibt es keinen solchen Aufrufer; Start ausschließlich über Aufgabenwarteschlange.
- [`Message(VendorAndPOCreatedMsg)` bei manuellem Start erscheint je Angebot] → unverändert zum heutigen Verhalten.
- [Codeunit-ID-Konflikt mit parallelen Branches] → vor Umsetzung prüfen (siehe D2).

## Migration Plan

1. Deployment ohne Datenmigration (neue Felder sind leer).
2. Bestehender Aufgabenwarteschlangenposten für Codeunit 60305 bleibt unverändert.
3. Rollback: Vorversion installieren; die neuen Felder entfallen (ggf. Force-Sync), Verarbeitung läuft wieder im Alles-oder-nichts-Modus.

## Open Questions

- Soll ein Angebot nach X Fehlversuchen nicht mehr automatisch wiederholt werden? (Aktuell: nein, unbegrenzt.)
