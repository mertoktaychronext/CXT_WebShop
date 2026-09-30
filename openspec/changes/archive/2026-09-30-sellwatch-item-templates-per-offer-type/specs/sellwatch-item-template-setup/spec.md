## MODIFIED Requirements

### Requirement: Konfigurierbare Artikelvorlage für SellWatch-Artikelanlage
Die Einkaufseinrichtung SHALL zwei Felder bereitstellen, über die die für die automatische SellWatch-Artikelanlage zu verwendenden Artikelvorlagen festgelegt werden: eine Artikelvorlage für Kommissionsangebote und eine Standard-Artikelvorlage für alle anderen Angebotsarten. Die dynamische Artikelanlage für eingehende SellWatch-Ankaufsanfragen SHALL die Artikelvorlage anhand der Angebotsart des SellWatch-Eintrags auswählen: Bei Angebotsart `commission` SHALL die Kommissions-Artikelvorlage verwendet werden, bei jeder anderen Angebotsart (einschließlich leerer Angebotsart) die Standard-Artikelvorlage. Es SHALL keine beliebige Artikelvorlage ausgewählt und kein Auswahldialog angezeigt werden.

#### Scenario: Artikelanlage für Kommissionsangebot
- **WHEN** eine SellWatch-Ankaufsanfrage mit Angebotsart `commission` verarbeitet wird und in der Einkaufseinrichtung eine gültige Kommissions-Artikelvorlage hinterlegt ist
- **THEN** wird der neue Artikel anhand genau dieser Kommissions-Artikelvorlage angelegt

#### Scenario: Artikelanlage für sonstige Angebotsart
- **WHEN** eine SellWatch-Ankaufsanfrage mit einer anderen Angebotsart als `commission` (z. B. `exchange` oder leer) verarbeitet wird und in der Einkaufseinrichtung eine gültige Standard-Artikelvorlage hinterlegt ist
- **THEN** wird der neue Artikel anhand genau dieser Standard-Artikelvorlage angelegt

#### Scenario: Bestehende Konfiguration bleibt als Standard-Vorlage erhalten
- **WHEN** die Erweiterung auf die neue Version aktualisiert wird und in der Einkaufseinrichtung bereits eine SellWatch-Artikelvorlage hinterlegt war
- **THEN** ist diese Vorlage anschließend als Standard-Artikelvorlage hinterlegt, ohne dass sie neu eingerichtet werden muss

### Requirement: Fehlerbehandlung bei fehlender oder ungültiger Artikelvorlagen-Konfiguration
Ist die für die Angebotsart benötigte Artikelvorlage in der Einkaufseinrichtung nicht hinterlegt, SHALL die Verarbeitung mit einer Fehlermeldung abbrechen, die auf die fehlende Konfiguration hinweist und benennt, welche der beiden Vorlagen (Kommission oder Standard) fehlt. Ist eine Artikelvorlage hinterlegt, die nicht mehr existiert, SHALL die Verarbeitung mit einer davon unterscheidbaren Fehlermeldung abbrechen, die den Code der ungültigen Artikelvorlage nennt. Fehlt die Kommissions-Artikelvorlage, SHALL NOT auf die Standard-Artikelvorlage ausgewichen werden. In allen Fällen SHALL kein Artikel angelegt werden.

#### Scenario: Keine Kommissions-Artikelvorlage konfiguriert
- **WHEN** eine SellWatch-Ankaufsanfrage mit Angebotsart `commission` verarbeitet wird und das Feld für die Kommissions-Artikelvorlage leer ist (auch wenn eine Standard-Artikelvorlage hinterlegt ist)
- **THEN** bricht die Verarbeitung mit einer Fehlermeldung ab, die auf die fehlende Kommissions-Artikelvorlage hinweist, und es wird kein Artikel angelegt

#### Scenario: Keine Standard-Artikelvorlage konfiguriert
- **WHEN** eine SellWatch-Ankaufsanfrage mit einer anderen Angebotsart als `commission` verarbeitet wird und das Feld für die Standard-Artikelvorlage leer ist
- **THEN** bricht die Verarbeitung mit einer Fehlermeldung ab, die auf die fehlende Standard-Artikelvorlage hinweist, und es wird kein Artikel angelegt

#### Scenario: Konfigurierte Artikelvorlage existiert nicht mehr
- **WHEN** eine SellWatch-Ankaufsanfrage verarbeitet wird und die für die Angebotsart zuständige Artikelvorlage in der Einkaufseinrichtung auf eine Artikelvorlage verweist, die nicht mehr existiert
- **THEN** bricht die Verarbeitung mit einer Fehlermeldung ab, die den Code der ungültigen Artikelvorlage nennt, und es wird kein Artikel angelegt

## ADDED Requirements

### Requirement: Anwendung der Artikelvorlage über den BC-Standard
Die SellWatch-Artikelanlage SHALL den Artikel über den Business-Central-Standard für Artikelvorlagen (`Codeunit "Item Templ. Mgt."`) anlegen, statt Felder direkt aus der Vorlage zu kopieren. Dadurch SHALL gelten: Standarddimensionen der Vorlage werden auf den Artikel übertragen, die Vorlagenfelder werden validiert übernommen, die Artikeleinheit zur Basiseinheit wird angelegt, und eine an der Vorlage hinterlegte Nummernserie wird für die Artikelnummer verwendet (ohne Nummernserie an der Vorlage gilt die Artikelnummernserie der Lagereinrichtung). Die SellWatch-spezifischen Werte (Beschreibung aus Marke, Modell und Baujahr; Beschreibung 2 aus Referenz; Kennzeichen Kommissionsverkauf bei Angebotsart `commission`) SHALL nach Anwendung der Vorlage gesetzt werden und dürfen durch die Vorlage nicht überschrieben werden.

#### Scenario: Standarddimensionen der Vorlage werden übernommen
- **WHEN** an der zuständigen Artikelvorlage Standarddimensionen hinterlegt sind und eine SellWatch-Ankaufsanfrage verarbeitet wird
- **THEN** hat der neu angelegte Artikel dieselben Standarddimensionen wie die Vorlage

#### Scenario: Artikeleinheit wird genau einmal angelegt
- **WHEN** an der zuständigen Artikelvorlage eine Basiseinheit hinterlegt ist und eine SellWatch-Ankaufsanfrage verarbeitet wird
- **THEN** existiert für den neuen Artikel genau eine Artikeleinheit zur Basiseinheit mit Menge pro Einheit 1, und die Verarbeitung bricht nicht wegen einer doppelten Artikeleinheit ab

#### Scenario: Nummernserie der Vorlage wird berücksichtigt
- **WHEN** an der zuständigen Artikelvorlage eine Nummernserie hinterlegt ist
- **THEN** erhält der neue Artikel seine Nummer aus dieser Nummernserie

#### Scenario: SellWatch-Werte haben Vorrang vor Vorlagenwerten
- **WHEN** an der zuständigen Artikelvorlage eine Beschreibung hinterlegt ist und eine SellWatch-Ankaufsanfrage mit Marke, Modell, Baujahr und Referenz verarbeitet wird
- **THEN** enthält der neue Artikel als Beschreibung „Marke Modell Baujahr“ und als Beschreibung 2 die Referenz aus dem SellWatch-Eintrag

#### Scenario: Kommissionskennzeichen wird gesetzt
- **WHEN** eine SellWatch-Ankaufsanfrage mit Angebotsart `commission` verarbeitet wird
- **THEN** ist beim neuen Artikel das Kennzeichen Kommissionsverkauf gesetzt, unabhängig davon, ob die Kommissions-Artikelvorlage es bereits setzt
