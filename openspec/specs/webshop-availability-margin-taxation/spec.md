# webshop-availability-margin-taxation Specification

## Purpose
Legt fest, woher Verfügbarkeitsänderungen und Echtzeitbestand die Information „differenzbesteuert" eines Artikelpostens beziehen (Salini Base App statt CHX.Base) und dass sich die Ergebnisse durch den Umstieg nicht ändern. Erstellt beim Archivieren der Change margin-taxation-salini-field.
## Requirements
### Requirement: Differenzbesteuerung aus dem Feld der Salini Base App
Verfügbarkeitsänderungen und Echtzeitbestand SHALL die Information „differenzbesteuert" eines Artikelpostens aus `"SLPSBC Margin Taxation"` (Salini Base App) lesen. Das Feld `"CXB Margin Taxation"` von CHX.Base MUST NOT mehr gelesen werden.

#### Scenario: Verfügbarkeitsänderung für einen differenzbesteuerten Posten
- **WHEN** nach dem Update ein Artikelposten mit „Differenzbesteuerung = Ja" entsteht und eine Verfügbarkeitsänderung dafür erfasst wird
- **THEN** trägt der Verfügbarkeitseintrag „Diff. Taxation Purchase = Ja"

#### Scenario: Verfügbarer Bestand je Besteuerungsart
- **WHEN** für einen Artikel offene Artikelposten mit und ohne Differenzbesteuerung am Verfügbarkeitslagerort existieren
- **THEN** wird der verfügbare Bestand je Besteuerungsart aus den Posten mit dem passenden Wert in `"SLPSBC Margin Taxation"` berechnet

#### Scenario: Echtzeitbestand
- **WHEN** ein Echtzeitbestand-Eintrag aus einem Artikelposten mit „Differenzbesteuerung = Ja" erzeugt wird
- **THEN** trägt er „Differential Taxation = Ja"

### Requirement: Gleiches Ergebnis für Posten vor dem Update
Für Artikelposten, die vor dem Update von CHX.Base 28.0.0.1 gebucht wurden, MUST das Ergebnis dasselbe sein wie vor der Umstellung, weil das CHX.Base-Upgrade die Werte 1:1 übernimmt.

#### Scenario: Bestand eines vor dem Update gebuchten Postens
- **WHEN** nach dem Update der verfügbare Bestand für einen Artikel berechnet wird, dessen offene Posten vor dem Update gebucht wurden
- **THEN** ist das Ergebnis je Besteuerungsart gleich wie vor dem Update
