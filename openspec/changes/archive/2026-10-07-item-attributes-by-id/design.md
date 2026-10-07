## Context

Artikelattribute laufen heute über drei Stellen:

- **SellWatch** (`CreateSellWatchItem`, Codeunit 60305) legt den Artikel aus der Vorlage an und setzt nur Beschreibung/Beschreibung 2 – keine Attribute.
- **Send to Workshop** (`FillPurchaseData`/`PrefillEmptyWorkshopAttributes`, Codeunit 60335) liest Stammdaten per Attribut-ID (1, 2, 3, 5, 8, 10, 11, 13 → Momentaufnahme, nur lesend) und die zehn Prüfmerkmale per **englischem Namen** mit ChronextBC-Ersatz-ID.
- **Verarbeitung** (`ProcessGenuineLine`, Codeunit 60331) schreibt die Prüfmerkmale per Name zurück; `GetOrCreateAttributeId` legt dabei fehlende Attribute (Typ Text) an, `GetOrCreateAttributeValueId` fehlende Werte.

Laut Attributliste (Excel „Artikelattribute“) existiert keines der englischen Attribute. Die Attribute sind fast alle vom Typ Option; 8 Jahr ist Ganzzahl, 18 Gehäuse Größe Dezimalzahl. In Produktion gibt es keine englischen Attribute – keine Migration nötig.

ChronextBC ruft beim Anlegen eines Reservierungspostens `InsertAttributesFromSerialNoInformation` auf; die Prozedur ist leer und wird von keiner unserer Apps genutzt. Sie ist für diesen Change irrelevant.

## Goals / Non-Goals

**Goals:**
- SellWatch-Artikel haben nach der Anlage die von SellWatch gelieferten Attributwerte.
- Prüfmerkmale der Werkstatt lesen und schreiben dieselben, tatsächlich vorhandenen Attribute (per ID).
- Eine gemeinsame Schreiblogik für Attributwerte.

**Non-Goals:**
- Keine Bereinigung der vorhandenen Wertelisten (Dubletten wie „Rado“/„RADO“).
- Kein Abgleich unbekannter Werte gegen die Liste (Groß-/Kleinschreibung, Ähnlichkeit) – unbekannte Werte werden wie bisher angelegt.
- Keine Übernahme von SellWatch-Werten in bereits angelegte Artikel (kein Upgrade).
- Keine Änderung an der Stammdaten-Momentaufnahme der Werkstattzeile (Gruppe A, IDs 1/2/3/5/8/10/11/13).
- Features, Attribut 9, Attribut 10 bekommen in diesem Change kein Attribut.

## Decisions

**1. Mapping per ID an einer Stelle (Codeunit 60335)**
`GetWorkshopAttributeName(Index): Text` wird ersetzt durch `GetWorkshopAttributeId(Index): Integer`:

| Index | Feld | ID |
|---|---|---|
| 1 | Dial Color | 22 |
| 2 | Case Diameter | 18 |
| 3 | Bracelet Material | 23 |
| 4 | Case Material | 16 |
| 5 | Movement | 15 |
| 6 | Gender | 24 |
| 7 | Crystal | 20 |
| 8 | Features | 0 |
| 9 | Attribut 9 | 0 |
| 10 | Attribut 10 | 0 |

0 = Platzhalter: weder vorbelegen noch zurückschreiben. Später wird nur hier die ID eingetragen.
Alternative „Namen auf Deutsch umstellen“ verworfen: Namen sind änderbar und mehrdeutig (Wertelisten-Dubletten zeigen, dass Pflege nicht kontrolliert ist); die IDs werden schon für Gruppe A und in ChronextBC („Item Attribute Collection“: Feldnummer = Attribut-ID) verwendet.

Damit entfallen `GetWorkshopAttributeFallbackId`, `IsUnchangedFallbackValue`, `FindItemAttributeId`; `FillEmptyWorkshopAttributes` liest nur noch über `GetItemAttributeValue(ItemNo, Id)` (bei ID 0 nichts).

**2. Gemeinsame Schreibprozedur in Codeunit 60335**
`SetItemAttributeValue(ItemNo; AttributeId; Value)` (intern/öffentlich innerhalb der App) plus `GetOrCreateAttributeValueId(AttributeId; Value)` wandern aus Codeunit 60331 nach 60335 und arbeiten mit ID. `GetOrCreateAttributeId` (Anlage von Attributen) entfällt ersatzlos. Existiert die Attribut-ID nicht (Attribut gelöscht), wird mit Fehler abgebrochen statt ein Attribut anzulegen – bei der Werkstatt landet das über die bestehende Fehlerbehandlung als Status „Fehler“.
Der Wert wird über `ItemAttributeValue.Validate(Value, …)` angelegt; der Standard prüft dabei Ganzzahl/Dezimal und setzt den numerischen Wert. Ein nicht numerischer Wert für 18 erzeugt so den Fehler, der die Werkstattzeile auf „Fehler“ setzt (gewollt).

**3. SellWatch-Übernahme in `CreateSellWatchItem`**
**Vor** `Item.Modify(true)` (der Artikel existiert nach `CreateItemFromTemplate` bereits) eine neue lokale Prozedur `SetSellWatchItemAttributes(ItemNo)` – Grund: `Item.Modify` löst in ChronextBC den Webshop-Artikelexport (`UPDITMFILE`) aus, der die Attribute sofort in die Nutzlast schreibt; Änderungen an „Item Attribute Value Mapping“ lösen dort keinen Export aus. Die Prozedur ruft für jede Zuordnung (1 Brand, 2 Model, 5 Reference, 8 Construction Year, 10 Watch Condition, 11 Box Available, 12 Taxation, 13 Paper Available, 24 Gender) die Schreibprozedur aus 60335 aufruft:
- leerer Text → überspringen;
- Box/Papiere: `true` → „ja“, `false` → „nein“ (Werte der Optionsliste);
- Baujahr: nur wenn `Evaluate(Integer, …)` gelingt, sonst überspringen – damit ein „ca. 2015“ nicht über `ProcessOfferWithErrorHandling` das ganze Angebot zurückrollt.
Die übrigen Werte werden nicht vorab geprüft: Option-Werte werden bei Bedarf angelegt, Text-Attribute nehmen jeden Wert.
Alternative „Fehler bei unbekanntem Wert“ verworfen (Entscheidung Fachbereich: unbekannte Werte anlegen wie bisher).

**4. Rückschreiben in Codeunit 60331**
Schleife über `WorkshopAttributeCount()`: ID = `GetWorkshopAttributeId(i)`; wenn ID <> 0 und Wert <> '' → `SetItemAttributeValue(Item, ID, Wert)`. Die Sonderbehandlung „unveränderter Ersatzwert“ entfällt; ein unverändert bestätigter Wert findet den bestehenden Attributwert und ändert nichts.

**5. Seriennummernverfolgung über die Artikelvorlage**
Die Standard-Tabelle „Item Templ.“ hat „Item Tracking Code“ (und „Serial Nos.“); `CreateItemFromTemplate` überträgt sie auf den Artikel. Daher keine eigene Einrichtung: `GetSellWatchItemTemplateCode` prüft nach dem Lesen der Vorlage, dass `"Item Tracking Code"` gefüllt ist und der Code `"SN Purchase Inbound Tracking"` hat – dieselbe Bedingung, die „Send to Workshop“ (`IsSerialNoTracked`, Codeunit 60335) verlangt. Sonst `Error` mit Vorlagencode → über `ProcessOfferWithErrorHandling` bleibt das Angebot mit Fehlertext offen, es wird nichts angelegt.
Alternativen verworfen: eigenes Einrichtungsfeld (doppelte Pflege neben der Vorlage), fester Code im Programm (Änderung nur per Deployment).
„Serial Nos.“ an der Vorlage wird bewusst **nicht** erzwungen (nicht gefordert); fehlt sie, meldet „Send to Workshop“ wie bisher „keine Seriennummernserie“ für die Zeile. Empfehlung an die Einrichtung: an beiden Vorlagen auch die Seriennr.-Nummernserie pflegen.

**6. Berechtigungen**
Permission Set 60310 „CXW SWChronWSAll“ (SellWatch-Verarbeitung) erhält `Item Attribute` = R, `Item Attribute Value` = RI, `Item Attribute Value Mapping` = RIM. Set 60301 bleibt (hat RIM); das I auf „Item Attribute“ wird nicht mehr gebraucht, bleibt aber unverändert, um kein Berechtigungsrisiko einzugehen.

## Risks / Trade-offs

- [Option-Wertelisten wachsen weiter durch abweichende Schreibweisen von SellWatch/Werkstatt] → bewusst akzeptiert (Fachentscheidung); Bereinigung wäre ein eigener Change.
- [Verhaltensänderung: unverändert bestätigte Werte werden jetzt geschrieben] → schreibt denselben Wert in dasselbe Attribut, also ohne Wirkung; Szenario in der Spec abgedeckt.
- [Werkstatt meldet Gehäuse Größe mit Einheit („41 mm“)] → Zeile geht auf „Fehler“ mit Meldung; Werkstatt meldet laut Fachbereich nur die Zahl.
- [Dezimaltrennzeichen bei Gehäuse Größe („41,5“ vs. „41.5“)] → `Validate` wertet sprachabhängig aus; im Test mit einem Nachkommawert prüfen und bei Bedarf in der Spec festhalten.
- [Attribut-IDs unterscheiden sich zwischen Mandanten/Umgebungen] → IDs sind laut ChronextBC global vergeben (Feldnummer = ID); im Test in jeder Zielumgebung die Excel-Liste gegenprüfen.
- [Upgrade-Codeunit 60336 `PrefillAttributesOnNewLines` nutzt die Vorbelegung] → läuft per Upgrade-Tag nur einmal und ist schon gelaufen; keine Wirkung.

## Migration Plan

Keine Datenmigration. Deployment wie üblich; Rollback = vorherige App-Version (angelegte Attributwerte bleiben bestehen und sind gültige Werte der deutschen Attribute).

## Open Questions

- Dezimaltrennzeichen für Gehäuse Größe (siehe Risiken) – im Test klären.
