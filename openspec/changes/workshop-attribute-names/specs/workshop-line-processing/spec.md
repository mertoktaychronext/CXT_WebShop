## MODIFIED Requirements

### Requirement: Übernahme der Attribute in Standard-Artikelattribute
Bei `Genuine = true` SHALL die Verarbeitung befüllte Attributfelder der Workshop Line in die BC-Standard-Artikelattribute des zugehörigen Artikels übernehmen, über eine zentrale, austauschbare Zuordnung Attributfeld → Attributname. Für die Attributfelder 1–8 SHALL diese Zuordnung die folgenden fachlichen Attributnamen liefern: Attribut 1 → "Dial Color", Attribut 2 → "Case Diameter", Attribut 3 → "Bracelet Material", Attribut 4 → "Case Material", Attribut 5 → "Movement", Attribut 6 → "Gender", Attribut 7 → "Crystal", Attribut 8 → "Features". Für die Attributfelder 9 und 10 SHALL die Zuordnung weiterhin die Platzhalternamen "Attribut 9" bzw. "Attribut 10" liefern, bis eine fachliche Bezeichnung vorliegt.

#### Scenario: Übernahme befüllter Attribute
- **WHEN** eine Workshop Line mit `Genuine = true` verarbeitet wird und `Attribute 1` einen Wert enthält
- **THEN** wird für den zugehörigen Artikel ein Item-Attribute-Value-Mapping mit dem zugeordneten Attributnamen und dem Wert von `Attribute 1` angelegt oder aktualisiert; fehlende Item-Attribute oder -Values werden dabei automatisch als Typ Text angelegt

#### Scenario: Leere Attributfelder werden übersprungen
- **WHEN** eine Workshop Line mit `Genuine = true` verarbeitet wird und `Attribute 5` leer ist
- **THEN** wird für `Attribute 5` kein Item-Attribute-Value-Mapping angelegt oder verändert

#### Scenario: Fachliche Attributnamen für Attribut 1–8
- **WHEN** eine Workshop Line mit `Genuine = true` verarbeitet wird und `Attribute 2` den Wert "42mm" enthält
- **THEN** wird für den zugehörigen Artikel ein Item-Attribute-Value-Mapping mit dem Attributnamen "Case Diameter" und dem Wert "42mm" angelegt oder aktualisiert

#### Scenario: Attribut 9 und 10 bleiben Platzhalter
- **WHEN** eine Workshop Line mit `Genuine = true` verarbeitet wird und `Attribute 9` einen Wert enthält
- **THEN** wird für den zugehörigen Artikel ein Item-Attribute-Value-Mapping mit dem Attributnamen "Attribut 9" angelegt oder aktualisiert
