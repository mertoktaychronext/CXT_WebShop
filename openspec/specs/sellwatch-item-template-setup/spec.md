# sellwatch-item-template-setup

## Purpose

Konfigurierbare Auswahl der Artikelvorlage für die dynamische SellWatch-Artikelanlage über die Einkaufseinrichtung, inklusive Fehlerbehandlung bei fehlender/ungültiger Konfiguration.

## Requirements

### Requirement: Konfigurierbare Artikelvorlage für SellWatch-Artikelanlage
Die Einkaufseinrichtung SHALL ein Feld bereitstellen, über das die für die automatische SellWatch-Artikelanlage zu verwendende Artikelvorlage festgelegt wird. Die dynamische Artikelanlage für eingehende SellWatch-Ankaufsanfragen SHALL diese konfigurierte Artikelvorlage verwenden, statt eine beliebige Artikelvorlage auszuwählen.

#### Scenario: Artikelanlage mit konfigurierter Artikelvorlage
- **WHEN** eine SellWatch-Ankaufsanfrage verarbeitet wird und in der Einkaufseinrichtung eine gültige Artikelvorlage hinterlegt ist
- **THEN** wird der neue Artikel anhand genau dieser konfigurierten Artikelvorlage angelegt

### Requirement: Fehlerbehandlung bei fehlender oder ungültiger Artikelvorlagen-Konfiguration
Ist in der Einkaufseinrichtung keine Artikelvorlage hinterlegt, SHALL die Verarbeitung mit einer Fehlermeldung abbrechen, die auf die fehlende Konfiguration hinweist. Ist eine Artikelvorlage hinterlegt, die nicht mehr existiert, SHALL die Verarbeitung mit einer davon unterscheidbaren Fehlermeldung abbrechen, die auf die ungültige Artikelvorlage hinweist. In beiden Fällen SHALL kein Artikel angelegt werden.

#### Scenario: Keine Artikelvorlage konfiguriert
- **WHEN** eine SellWatch-Ankaufsanfrage verarbeitet wird und das Feld für die Artikelvorlage in der Einkaufseinrichtung leer ist
- **THEN** bricht die Verarbeitung mit einer Fehlermeldung ab, die auf die fehlende Einrichtung hinweist, und es wird kein Artikel angelegt

#### Scenario: Konfigurierte Artikelvorlage existiert nicht mehr
- **WHEN** eine SellWatch-Ankaufsanfrage verarbeitet wird und das Feld für die Artikelvorlage in der Einkaufseinrichtung eine Artikelvorlage referenziert, die nicht mehr existiert
- **THEN** bricht die Verarbeitung mit einer Fehlermeldung ab, die auf die ungültige Artikelvorlage hinweist, und es wird kein Artikel angelegt
