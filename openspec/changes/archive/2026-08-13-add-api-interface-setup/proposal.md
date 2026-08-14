## Why

Codeunit 51000 "SL Export Gateway Sales Price" baut das Verkaufspreis-JSON bereits auf, schreibt es aber nur in eine lokale Zwischenablage-Tabelle (Table 51004) — es gibt noch keinen tatsächlichen Versand an ein externes System. Außerdem soll die Konfiguration, welches System/welcher Endpunkt für den Versand genutzt wird, nicht fest im Code stehen, sondern generisch einrichtbar sein, damit künftige API-Schnittstellen (nicht nur Sales Price) dieselbe Einrichtungstabelle nutzen können, statt für jede neue Schnittstelle eine eigene Setup-Struktur zu bauen.

## What Changes

- Neue, generische Einrichtungstabelle für API-Schnittstellen: pro Zeile ein Endpunkt (URL, Authentifizierung, aktiv/inaktiv) sowie eine Angabe, welche Objektart/welcher Record über diese Schnittstelle verarbeitet wird.
- Neues Feld auf der bestehenden Tabelle "SL General Sales Price Setup" (Tab51000), das auf genau einen Eintrag dieser neuen API-Einrichtungstabelle verweist — legt fest, über welche Schnittstelle Verkaufspreise verschickt werden.
- Codeunit 51000 sendet das JSON zusätzlich zum bisherigen Schreiben in Table 51004 per HTTP an den in der referenzierten API-Einrichtung hinterlegten Endpunkt.
- Neue Seite zur Pflege der API-Einrichtungen (Liste + Karte), erreichbar über eine Navigation-Action ab der allgemeinen Verkaufspreis-Einrichtung.
- Permission Set um die neuen Objekte ergänzt.

## Capabilities

### New Capabilities
- `api-interface-setup`: Generische, wiederverwendbare Einrichtung für ausgehende API-Schnittstellen (Endpunkt-URL, Authentifizierung, Aktiv-Kennzeichen, referenzierte Objektart) — unabhängig von einem konkreten Fachbereich, damit zukünftige Schnittstellen (z.B. andere Exporte) dieselbe Tabelle nutzen können.
- `sales-price-api-export`: Verwendet eine über `api-interface-setup` konfigurierte Schnittstelle, um das von Codeunit 51000 erzeugte Verkaufspreis-JSON tatsächlich per HTTP an ein externes System zu senden, statt es nur lokal abzulegen.

### Modified Capabilities
(keine — es gibt noch keine bestehende Spezifikation für den Sales-Price-Export; `sales-price-currency-copy` bleibt unverändert)

## Impact

- **Neu:** Tabelle + Seite für API-Einrichtung (ID-Bereich 51000–51049, nächste freie IDs)
- **Geändert:** `src/Tables/Tab51000.SLGeneralSalesPriceSetup.al` (neues Referenzfeld auf API-Einrichtung)
- **Geändert:** `src/Codeunits/Codeunit51000.SLExportGatewaySalesPrice.al` (tatsächlicher HTTP-Versand ergänzt, zusätzlich zum bisherigen Schreiben in Table 51004)
- **Geändert:** `src/PermissionSets/SLChronWSAll.permissionset.al` (neue Objekte ergänzt)
- **Geändert:** `docs/funktionsregister/*`, Handbücher (nach Umsetzung, nicht Teil dieses Proposals)
