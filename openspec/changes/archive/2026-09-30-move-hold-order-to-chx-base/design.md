## Context

"Auftrag halten" wurde am 2026-09-29 in CHX.Webshop umgesetzt (Change `sales-order-hold-flag`, archiviert): TableExtension 60300 "CXW Sales Header" mit Feld 60300 "CXW Hold Order", Anzeige über PageExtension 60334 "CXW Sales Order" (Gruppe General, nur bei Status Offen bearbeitbar) und PageExtension 60337 "CXW Sales Order List". Das Feld soll in die Basis-Extension CHX.Base.

CHX.Base (Repository `CHX.Base`, Branch `02-DEV/development`, Version 27.0.3.4, ID-Bereich 60200–60249) erweitert bisher weder "Sales Header" noch die Seiten "Sales Order"/"Sales Order List". Konventionen dort: Namespace `CHX.Base`, Präfix `CXB`, Objektnamen "CXB … Ext.", Dateinamen `CXB<Name>Ext.TableExt.al` bzw. `.PageExt.al` in `src/tableext` und `src/pageext`, Feldnummern ab 60200, `DataClassification = CustomerContent`, ToolTip am Tabellenfeld. CHX.Webshop hängt bereits von CHX.Base ab (≥ 27.0.3.4); CHX.Base hat keine Abhängigkeiten.

Abstimmung vom 2026-09-30: Werte des bisherigen Felds müssen nicht übernommen werden.

## Goals / Non-Goals

**Goals:**
- Feld und Anzeige vollständig in CHX.Base, mit unverändertem Verhalten.
- CHX.Webshop enthält danach keinerlei Bezug mehr auf "Auftrag halten".

**Non-Goals:**
- Keine Datenübernahme vom alten ins neue Feld.
- Keine Verhaltensänderung (weiterhin reines Kennzeichen, nur manuell, nur im Status Offen änderbar).

## Decisions

**1. Objekte in CHX.Base**

| Objekt | ID | Name | Datei |
|---|---|---|---|
| TableExtension auf "Sales Header" | 60212 | "CXB Sales Header Ext." | `src/tableext/CXBSalesHeaderExt.TableExt.al` |
| PageExtension auf "Sales Order" | 60217 | "CXB Sales Order Ext." | `src/pageext/CXBSalesOrderExt.PageExt.al` |
| PageExtension auf "Sales Order List" | 60218 | "CXB Sales Order List Ext." | `src/pageext/CXBSalesOrderListExt.PageExt.al` |

Feld 60200 **"CXB Hold Order"** (Boolean, Caption `Hold Order`, ToolTip am Feld, `DataClassification = CustomerContent`). IDs 60212/60217/60218 sind die nächsten freien Nummern der jeweiligen Objekttypen.
*Alternative:* den Feldnamen "CXW Hold Order" beibehalten – verworfen, weil CHX.Base durchgängig das Präfix `CXB` nutzt und ein fremdes Präfix dort irreführend wäre. Da keine Werte übernommen werden, bringt der alte Name keinen Vorteil.

**2. Verhalten 1:1 übernehmen**
`OnValidate`: `if Rec."CXB Hold Order" <> xRec."CXB Hold Order" then TestField(Status, Status::Open);` – wie der zuletzt freigegebene Stand in CHX.Webshop. Seite "Sales Order": `addlast(General)`, `Editable = Rec.Status = Rec.Status::Open`. Seite "Sales Order List": Spalte per `addlast(Control1)`. Der ToolTip steht in CHX.Base am Tabellenfeld (Konvention dort), die Seitenfelder brauchen dann keinen eigenen.

**3. Entfernen aus CHX.Webshop ohne Obsolete-Zwischenschritt**
TableExtension 60300 und PageExtension 60337 werden gelöscht, das Feld aus PageExtension 60334 entfernt. Ein zweistufiges Vorgehen mit `ObsoleteState = Pending` und Upgrade-Codeunit wäre nur für eine Datenübernahme nötig, die laut Abstimmung entfällt.
*Folge:* Beim Veröffentlichen der neuen CHX.Webshop-Version in einer Umgebung, in der 27.0.0.8/27.0.0.9 installiert ist, verlangt BC wegen des entfernten Felds eine Schema-Synchronisation mit **ForceSync**; die Werte des alten Felds gehen dabei verloren (gewollt).

**4. Versionen und Abhängigkeit**
CHX.Base 27.0.3.4 → 27.0.3.5. CHX.Webshop 27.0.0.9 → 27.0.0.10 und Abhängigkeit CHX.Base auf mindestens 27.0.3.5 – so kann die neue Webshop-Version nur zusammen mit der CHX.Base-Version installiert werden, die das Feld bereitstellt, und beide zeigen das Feld nie doppelt an.

**5. OpenSpec in beiden Repositories**
Dieser Change liegt in CHX.Webshop und entfernt die Capability `sales-order-hold-flag` (REMOVED). In CHX.Base wird bei der Umsetzung die Spec `openspec/specs/sales-order-hold-flag/spec.md` mit den neuen Objektnamen angelegt, damit die Anforderungen dort nachvollziehbar bleiben.

## Risks / Trade-offs

- [Beide Apps zeigen das Feld kurzzeitig doppelt, wenn nur CHX.Base aktualisiert wird] → Tritt nur zwischen den beiden Deployments auf; Reihenfolge CHX.Base → CHX.Webshop direkt hintereinander ausführen.
- [ForceSync beim Webshop-Deployment übersehen] → Im Deployment-Hinweis bzw. Release-Notes ausdrücklich vermerken.
- [Gesetzte Haken in Test-/Sandbox-Umgebungen gehen verloren] → Laut Abstimmung akzeptiert; bei Bedarf nach dem Deployment manuell neu setzen.
- [CHX.Webshop-Branch] → Der Arbeitsstand in CHX.Webshop steht derzeit auf `02-DEV/SPJsonVariant`; die Umsetzung muss auf Basis von `02-DEV/development` erfolgen (siehe tasks.md, 0.1).

## Migration Plan

1. CHX.Base 27.0.3.5 veröffentlichen (fügt Feld und Seitenerweiterungen hinzu).
2. Direkt danach CHX.Webshop 27.0.0.10 veröffentlichen, Schema-Synchronisation mit ForceSync.
3. Rollback: beide Apps auf die Vorversion zurücksetzen (CHX.Webshop zuerst, dann CHX.Base); das Feld liegt dann wieder in CHX.Webshop, Werte des CXB-Felds gehen dabei verloren.

## Open Questions

- (keine)
