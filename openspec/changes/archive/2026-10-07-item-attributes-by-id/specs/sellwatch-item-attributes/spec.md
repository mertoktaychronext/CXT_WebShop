## ADDED Requirements

### Requirement: SellWatch-Uhrendaten werden als Artikelattribute übernommen
Nach dem Anlegen des Artikels aus der Artikelvorlage SHALL die SellWatch-Artikelanlage die Uhrendaten der SellWatch-Anfrage als Artikelattribute des neuen Artikels eintragen, und zwar über die Attribut-ID:

| SellWatch-Feld | Attribut-ID | Attribut |
|---|---|---|
| `CXW Brand` | 1 | Marke |
| `CXW Model` | 2 | Modell |
| `CXW Reference` | 5 | Referenz |
| `CXW Construction Year` | 8 | Jahr |
| `CXW Watch Condition` | 10 | Zustand |
| `CXW Box Available` | 11 | Box |
| `CXW Taxation` | 12 | Besteuerung |
| `CXW Paper Available` | 13 | Zertifikat |
| `CXW Gender` | 24 | Geschlecht |

Textwerte SHALL unverändert übernommen werden. Die Ja/Nein-Felder „Box vorhanden“ und „Papiere vorhanden“ SHALL als Wert „ja“ bzw. „nein“ eingetragen werden. Ist für das Attribut bereits ein Wert am Artikel zugeordnet (z. B. durch die Vorlage), SHALL er durch den SellWatch-Wert ersetzt werden. Die bestehende Beschreibung aus Marke, Modell und Baujahr sowie Beschreibung 2 aus der Referenz SHALL unverändert weiter gesetzt werden.

#### Scenario: Uhrendaten werden eingetragen
- **WHEN** eine SellWatch-Anfrage mit Marke „Rolex“, Modell „Submariner“, Referenz „116610LN“, Baujahr „2019“, Zustand „aa“, Box vorhanden = Ja, Papiere vorhanden = Nein, Besteuerung „diff“ und Geschlecht „Herren“ verarbeitet wird
- **THEN** hat der neue Artikel die Attributwerte 1 = „Rolex“, 2 = „Submariner“, 5 = „116610LN“, 8 = 2019, 10 = „aa“, 11 = „ja“, 13 = „nein“, 12 = „diff“ und 24 = „Herren“

#### Scenario: Werte erscheinen auf der Werkstattzeile
- **WHEN** die Einkaufszeile eines so angelegten Artikels an die Werkstatt gesendet wird
- **THEN** enthält die Werkstattzeile Marke „Rolex“, Modell „Submariner“, Referenz „116610LN“, Baujahr 2019, Zustand „aa“, Box „ja“ und Zertifikat „nein“, und als vorbelegtes Prüfmerkmal Gender „Herren“

### Requirement: Unbekannte Werte werden als neuer Attributwert angelegt
Ist ein SellWatch-Wert für ein Attribut vom Typ Option nicht in dessen Werteliste vorhanden, SHALL das System ihn als neuen Attributwert anlegen und zuordnen (gleiches Verhalten wie beim Rückschreiben der Werkstatt). Es SHALL kein neues Attribut angelegt werden.

#### Scenario: Neues Modell
- **WHEN** eine SellWatch-Anfrage mit Modell „Submariner Date 41“ verarbeitet wird und dieser Wert für Attribut 2 noch nicht existiert
- **THEN** wird für Attribut 2 der Wert „Submariner Date 41“ angelegt und dem Artikel zugeordnet

### Requirement: Fehlende oder ungültige Werte brechen die Anlage nicht ab
Ein leeres SellWatch-Feld SHALL übersprungen werden; es SHALL kein leerer Attributwert angelegt oder zugeordnet werden. Ein Baujahr, das keine ganze Zahl ist, SHALL für Attribut 8 übersprungen werden. In beiden Fällen SHALL die Verarbeitung der Anfrage (Lieferant, Artikel, Einkaufsbestellung) normal fortgesetzt werden.

#### Scenario: Leeres Feld
- **WHEN** eine SellWatch-Anfrage ohne Referenz und ohne Geschlecht verarbeitet wird
- **THEN** hat der neue Artikel keinen Wert für die Attribute 5 und 24, und die Einkaufsbestellung wird angelegt

#### Scenario: Nicht numerisches Baujahr
- **WHEN** eine SellWatch-Anfrage mit Baujahr „ca. 2015“ verarbeitet wird
- **THEN** hat der neue Artikel keinen Wert für Attribut 8, alle übrigen Attribute sind eingetragen, und die Anfrage ist ohne Fehler als angelegt markiert

### Requirement: Nur die SellWatch-Anlage schreibt diese Attribute automatisch
Für Artikel, die nicht über die SellWatch-Anlage entstehen, SHALL das System die Attribute 1, 2, 5, 8, 10, 11, 12, 13 nicht automatisch befüllen; sie werden manuell gepflegt.

#### Scenario: Manuell angelegter Artikel
- **WHEN** ein Benutzer einen Artikel manuell anlegt und eine Einkaufszeile dafür an die Werkstatt sendet
- **THEN** werden die Stammdaten der Werkstattzeile nur aus den manuell gepflegten Attributen gelesen und es werden keine Attributwerte automatisch angelegt
