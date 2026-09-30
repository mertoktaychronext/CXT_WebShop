## Why

`Codeunit 60305 "CXW SellWatch Mgt"` verarbeitet alle offenen SellWatch-Angebote in einer einzigen Transaktion ohne `Commit`. Scheitert ein einzelnes Angebot (z. B. fehlende Artikelvorlage, ungültige Buchungsgruppe, doppelte Bankverbindung), wird der gesamte Job-Queue-Lauf zurückgerollt – auch alle bereits erfolgreich verarbeiteten Angebote – und im Angebot selbst ist nicht erkennbar, warum es nicht verarbeitet wurde. Ein einziges fehlerhaftes Angebot blockiert damit dauerhaft alle anderen.

## What Changes

- Jedes offene Angebot wird in einer eigenen Transaktion über `Codeunit.Run` verarbeitet. Scheitert es, werden nur die Änderungen dieses Angebots zurückgerollt (kein halb angelegter Kreditor, keine Bestellung ohne Zeile, kein verwaister Artikel); die übrigen Angebote werden weiterverarbeitet.
- Neuer Worker-Codeunit (`TableNo = "CXW SellWatch Vendor Info"`), der genau ein Angebot verarbeitet; die bestehende Logik (Kreditor, Bestellung, Artikel) bleibt in Codeunit 60305 und wird über eine interne Prozedur aufgerufen.
- Neue Fehlerfelder auf Table 60300: letzter Fehlertext und Zeitpunkt des letzten Fehlers. Bei Fehlschlag werden sie gesetzt, bei erfolgreicher Verarbeitung geleert.
- Fehlgeschlagene Angebote bleiben offen (`"CXW Created" = false`) und werden beim nächsten Lauf automatisch erneut versucht – nach Korrektur der Ursache (z. B. Vorlage eingerichtet) ist kein manueller Eingriff am Angebot nötig.
- Die SellWatch-Übersicht (Page 60307) zeigt die Fehlerfelder an und hebt fehlerhafte Angebote hervor.
- Die Fehlerfelder sind über die Inbound-API nicht beschreibbar.
- Permission Set `CXW SWChronWSAll` um den neuen Codeunit ergänzt.

## Capabilities

### New Capabilities
- `sellwatch-offer-processing`: Einzelverarbeitung jedes offenen SellWatch-Angebots in eigener Transaktion, Fehlerprotokollierung am Angebot, automatische Wiederholung beim nächsten Lauf.

### Modified Capabilities
<!-- keine: sellwatch-item-template-setup bleibt fachlich gleich (Fehler bricht die Verarbeitung dieses Angebots ab, kein Artikel wird angelegt); sellwatch-inbound-api wird nicht geändert, die neuen Felder werden auf der API-Seite schlicht nicht veröffentlicht. -->

## Impact

- `src/Codeunits/Codeunit60305.CXWSellWatchMgt.al` – Schleife in `ValidateAndCreateVendor` auf Einzelverarbeitung mit `Commit` + `Codeunit.Run` umbauen, neue interne Prozedur für ein Angebot
- neuer Codeunit (ID 60351) „CXW SellWatch Process Offer“
- `src/Tables/Tab60300.CXWSellWatchVendorInfo.al` – neue Felder 46/47
- `src/Pages/Pag60307.CXWSellWatchOverview.al` – Fehlerfelder, Hervorhebung
- `src/PermissionSets/CXWSWChronWSAll.permissionset.al`
- `Translations/*.xlf`, `docs/` (Entwickler-/Key-User-Handbuch, Funktionsregister)
- Verhalten im Betrieb: der Job-Queue-Eintrag endet nicht mehr mit Fehler, wenn einzelne Angebote scheitern – Überwachung erfolgt über die Fehlerfelder in der SellWatch-Übersicht statt über den Job-Queue-Status
