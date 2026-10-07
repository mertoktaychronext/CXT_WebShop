# Gesamtübersicht – Events

**Stand:** 2026-10-06 (aus `gesamtuebersicht.md` gefiltert, CHX.Webshop 27.0.0.16)

Alle Event-Subscriber und Event-Publisher. Subscriber zeigen, an welchen Stellen CHX.Webshop in Standardprozesse von Business Central oder anderer Apps eingreift; diese Stellen müssen bei einer Auslagerung mitwandern.

| Projekt | Objekt | Objekttyp | Funktion | Typ | Sichtbarkeit | Beschreibung |
|---|---|---|---|---|---|---|
| CHX.Webshop | CXW Workshop Upgrade (60336) | Codeunit | `RegisterPerCompanyTags` | Event Subscriber | Internal | Meldet die Upgrade-Kennzeichen beim Standard-Upgrade-Modul an, damit neue Mandanten die Nachbearbeitungen nicht unnötig ausführen. |
| CHX.Webshop | CXW Consignment Sale Detection (60344) | Codeunit | `OnAfterPostSalesDocCreateConsignmentEntries` | Event Subscriber | Internal | Reagiert auf jede gebuchte Verkaufsrechnung (nicht bei reiner Lieferung oder Buchungsvorschau) und legt für jede Zeile eines Kommissionsartikels einen Kommissions-Buchungseintrag an, ohne die Rechnungsbuchung selbst jemals zu gefährden. |
| CHX.Webshop | CXW Import Sales Prices (60330) | Codeunit | `OnAfterSalesPriceModify` | Event Publisher | Public | Signalisiert nach der Aktualisierung eines bestehenden Verkaufspreises, damit andere Erweiterungen darauf reagieren können. |
| CHX.Webshop | CXW Availability Change Mgt (60348) | Codeunit | `OnAfterModifyItem` | Event Subscriber | Internal | Berechnet die Lieferzeiten eines Artikels neu, sobald sich seine zusätzliche Lieferzeit ändert. |
| CHX.Webshop | CXW Availability Change Mgt (60348) | Codeunit | `OnAfterInsertItemLedgerEntry` | Event Subscriber | Internal | Erfasst jede neue Artikelbuchung in einem Webshop-Lagerort als Verfügbarkeitsänderung. |
| CHX.Webshop | CXW Availability Change Mgt (60348) | Codeunit | `OnAfterModifySalesLine` | Event Subscriber | Internal | Erfasst Änderungen an Verkaufsauftragszeilen in Webshop-Lagerorten als Verfügbarkeitsänderung. |
| CHX.Webshop | CXW Availability Change Mgt (60348) | Codeunit | `OnAfterDeleteSalesLine` | Event Subscriber | Internal | Erfasst gelöschte Verkaufsauftragszeilen in Webshop-Lagerorten als Verfügbarkeitsänderung. |
| CHX.Webshop | CXW Availability Change Mgt (60348) | Codeunit | `OnAfterInsertTransferLine`, `OnAfterModifyTransferLine`, `OnAfterDeleteTransferLine` | Event Subscriber | Internal | Erfassen angelegte, geänderte und gelöschte Umlagerungszeilen von oder zu einem Webshop-Lagerort als Verfügbarkeitsänderung. |

> 10 Events (9 Subscriber, 1 Publisher); zusammengehörige Subscriber stehen in einer Sammelzeile. Vollständige Liste: `gesamtuebersicht.md`.
