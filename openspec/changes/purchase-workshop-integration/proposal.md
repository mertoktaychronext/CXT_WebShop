## Why

Uhren, die angekauft werden, müssen vor der Einlagerung von einer externen Werkstatt ("Workshop") auf Echtheit geprüft werden, die dabei auch Artikel-Attribute erfasst. Heute gibt es keine strukturierte Übergabe zwischen Purchase Order und Workshop, keine Nachverfolgung des Prüfstatus pro Zeile und keine automatisierte Anbindung, die den Wareneingang erst nach positiver Prüfung bucht bzw. bei negativer Prüfung die Bestellung storniert.

## What Changes

- Neue Tabelle "Workshop Line" (1:1 zu einer Purchase Line) mit Status-Enum (Neu / WS geprüft / Verarbeitet), 10 generischen Attributfeldern, Genuine-Flag und Fehlerprotokoll-Feld.
- Table Extension auf Purchase Line: `Manufacturer Serial No.`, `Not Arrived`, `Sent to Workshop`.
- Neue Aktion "Send to Workshop" auf der Purchase-Order-Page: fragt pro offener Zeile Ankunft ab, erfasst per modalem Dialog die Herstellerseriennummer und legt daraus eine Workshop Line an.
- Purchase-Line-Felder werden auf der Purchase-Order-Subform gesperrt (nicht mehr editierbar), sobald `Sent to Workshop = true` — verhindert nachträgliche Änderungen an einer Zeile, die bereits an den Workshop übergeben wurde.
- Neue Custom API v1.0 auf "Workshop Line" für den externen Workshop: GET zum Abholen offener Zeilen, PATCH zum Zurückschreiben von Attributen, Genuine-Flag und Status; Insert/Delete über die API gesperrt; Statusrückschritte gesperrt.
- Neue Job-Queue-fähige Codeunit "Process Workshop Lines": verarbeitet Zeilen im Status "WS geprüft" — bei Genuine=true nur Wareneingang buchen (kein Invoice) und Attribute in die BC-Standard-Artikelattribute schreiben; bei Genuine=false die zugehörige PO stornieren (löschen). Pro Zeile isolierte Fehlerbehandlung, Fehler werden auf der Workshop Line protokolliert.
- Zwei neue Permission Sets: ein interner Vollzugriff auf alle neuen Objekte und ein eingeschränktes Set für den externen Workshop-API-Benutzer (nur Lesen/Ändern auf "Workshop Line", kein Insert/Delete).
- Deutsche und englische Captions/Translations für alle neuen Objekte.
- README-Hinweis zu OAuth2-S2S-Einrichtung (Entra) für die API und zur Job-Queue-Einrichtung (Empfehlung: alle 5 Minuten).

**Bewusst nicht implementiert (nur TODO-Markierung im Code):**
- Finale Benennung der 10 Attributfelder (Platzhalter "Attribut 1"–"Attribut 10").
- Verhalten bei gemischten Purchase Orders (mehrere Zeilen, teils echt/teils nicht echt) — Standardfall ist eine PO mit genau einer Purchase Line.

## Capabilities

### New Capabilities
- `workshop-line-intake`: Erfassung angekommener Purchase-Order-Zeilen inkl. Seriennummer-Erfassung und Anlage der Workshop Line aus der Purchase-Order-Page.
- `workshop-line-api`: Externe Custom API, über die der Workshop offene Zeilen liest und Prüfergebnisse (Attribute, Echtheit, Status) zurückschreibt.
- `workshop-line-processing`: Job-Queue-gesteuerte Verarbeitung geprüfter Zeilen — Wareneingang buchen und Artikelattribute übernehmen bei Echtheit, PO-Stornierung bei Nicht-Echtheit.

### Modified Capabilities
- (keine — reine Neuentwicklung, keine bestehenden Specs betroffen)

## Impact

- **Neue Objekte** (Präfix `CXW`, jeweils nächste freie ID des jeweiligen Objekttyps im bestehenden `idRanges`-Block 60300–60349 von `CHX.Webshop`; siehe design.md für die genaue Zuordnung):
  - Enum "CXW Workshop Line Status"
  - Table "CXW Workshop Line"
  - Table Extension auf "Purchase Line" (neue, eigene Extension neben der bestehenden SellWatch-Extension)
  - Page Extension auf "Purchase Order" (Dokumentseite, Aktion "Send to Workshop")
  - Page Extension auf "Purchase Order Subform" (Zeilen-Subform, neue Felder + Editierbarkeits-Sperre)
  - Page "CXW Workshop Lines" (interne Liste)
  - Page "CXW Workshop Line API" (Custom API)
  - Page "CXW Serial No. Input" (StandardDialog für die Seriennummer-Eingabe)
  - Codeunit "CXW Process Workshop Lines" (Job-Queue-Verarbeitung)
  - Permission Set "CXW Workshop All" (interner Vollzugriff) und Permission Set "CXW Workshop API" (eingeschränkter Zugriff für den externen Workshop-Benutzer)
- **Keine Änderungen an Standardobjekten** außer den genannten Extensions.
- **Abhängigkeiten**: Standard-Item-Attribute-Tabellen (Item Attribute, Item Attribute Value, Item Attribute Value Mapping), Codeunit "Purch.-Post" für Wareneingangsbuchung, Job Queue Entry für die periodische Verarbeitung.
- **Doku**: README-Ergänzung zu OAuth2-S2S-Setup und Job-Queue-Einrichtung.
