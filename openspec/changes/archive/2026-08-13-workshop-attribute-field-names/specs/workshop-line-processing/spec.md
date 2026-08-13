## ADDED Requirements

### Requirement: Aussagekräftige interne Feldbezeichner für Attributfelder
Die internen AL-Feldbezeichner der Attributfelder 1–8 auf der Workshop Line SHALL ihre fachliche Bedeutung widerspiegeln (z. B. `CXW Dial Color` statt `CXW Attribute 1`), statt nur über die Caption erkennbar zu sein. Die externe API-Vertragsfläche (OData-Eigenschaftsnamen `attribute1`–`attribute10` auf der Workshop-Line-API) SHALL von dieser internen Umbenennung unberührt bleiben.

#### Scenario: Feldbezeichner spiegelt die fachliche Bedeutung wider
- **WHEN** der Quellcode, der ein Attributfeld 1–8 der Workshop Line referenziert, gelesen wird
- **THEN** ist anhand des Feldbezeichners selbst erkennbar, welches Attribut gemeint ist (z. B. `"CXW Dial Color"`), ohne die Caption nachschlagen zu müssen

#### Scenario: Externer API-Vertrag bleibt trotz interner Umbenennung stabil
- **WHEN** der externe Workshop über die Workshop-Line-API Werte in den Eigenschaften `attribute1`–`attribute8` liest oder schreibt
- **THEN** funktioniert dies unverändert, unabhängig davon, wie das dahinterliegende AL-Feld intern benannt ist
