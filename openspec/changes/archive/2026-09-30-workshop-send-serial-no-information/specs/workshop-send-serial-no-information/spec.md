## ADDED Requirements

### Requirement: Seriennummer der Einkaufszeile ermitteln oder vergeben
Bei „Send to Workshop“ SHALL das System für jede bestätigt angekommene Einkaufszeile die Seriennummer aus der Artikelverfolgung der Einkaufszeile ermitteln. Ist dort bereits eine Seriennummer vorhanden, SHALL diese verwendet werden. Ist keine vorhanden, SHALL das System die nächste Nummer aus der Seriennr.-Nummernserie des Artikels ziehen und sie als Artikelverfolgung (Menge 1) an die Einkaufszeile hängen. Für die verwendete Seriennummer SHALL ein Datensatz „Serial No. Information“ (Artikel, Variante, Seriennummer) existieren; fehlt er, SHALL er angelegt werden.

#### Scenario: Einkaufszeile hat noch keine Seriennummer
- **WHEN** der Benutzer „Send to Workshop“ ausführt, die Ankunft einer Zeile bestätigt und die Einkaufszeile keine Seriennummer in der Artikelverfolgung hat
- **THEN** wird die nächste Nummer aus der Seriennr.-Nummernserie des Artikels gezogen, als Artikelverfolgung an die Einkaufszeile gehängt und ein Datensatz „Serial No. Information“ dafür angelegt

#### Scenario: Einkaufszeile hat bereits eine Seriennummer
- **WHEN** die Einkaufszeile bereits eine Seriennummer in der Artikelverfolgung hat
- **THEN** wird diese Seriennummer verwendet und keine neue Nummer gezogen

#### Scenario: Wiederholung nach abgebrochenem Versand verwendet dieselbe Nummer
- **WHEN** eine Zeile in einem früheren Versuch eine gezogene Seriennummer erhalten hat, aber nicht gesendet wurde, und der Benutzer „Send to Workshop“ erneut ausführt
- **THEN** wird dieselbe Seriennummer erneut verwendet

### Requirement: Herstellernummer über die Seriennr.-Informationskarte erfassen
Nach Ermittlung der Seriennummer SHALL das System die Seriennr.-Informationskarte (Page 6504) für Artikel, Variante und Seriennummer der Einkaufszeile modal öffnen. Nach dem Schließen SHALL das System die Herstellernummer (`"CXB Manufacturer Serial No."`) aus dem Datensatz „Serial No. Information“ lesen und in die Einkaufszeile (`"CXW Manufacturer Serial No."`) sowie in die neu angelegte Werkstattzeile übernehmen. Der bisherige Eingabedialog (Page 60340) SHALL NOT mehr verwendet werden.

#### Scenario: Herstellernummer wird übernommen
- **WHEN** der Benutzer in der geöffneten Seriennr.-Informationskarte die Herstellernummer „ABC123“ einträgt und die Karte schließt
- **THEN** enthalten Einkaufszeile und neue Werkstattzeile die Herstellernummer „ABC123“, und die Einkaufszeile ist als „an die Werkstatt gesendet“ markiert

#### Scenario: Karte zeigt vorbelegte Seriennummer
- **WHEN** für die Zeile eine neue Seriennummer gezogen wurde
- **THEN** öffnet sich die Seriennr.-Informationskarte mit genau dieser Seriennummer, dem Artikel und der Variante der Einkaufszeile

### Requirement: Zeile wird bei fehlenden Angaben nicht gesendet
Das System SHALL eine Zeile nicht an die Werkstatt senden (keine Werkstattzeile, „CXW Sent to Workshop“ bleibt falsch) und sie mit Begründung in der bestehenden Fehlerliste melden, wenn nach dem Schließen der Karte die Herstellernummer leer ist oder die in CHX.Base für den Artikelverfolgungscode verpflichtenden Angaben (Herstellernummer, Box vorhanden, Papiere vorhanden) fehlen. Die gezogene Seriennummer samt Artikelverfolgung und Seriennr.-Information SHALL dabei erhalten bleiben.

#### Scenario: Herstellernummer bleibt leer
- **WHEN** der Benutzer die Seriennr.-Informationskarte schließt, ohne eine Herstellernummer einzutragen
- **THEN** wird für diese Zeile keine Werkstattzeile angelegt und die Fehlerliste enthält die Zeile mit dem Hinweis, dass die Herstellernummer erforderlich ist

#### Scenario: Pflichtangabe aus CHX.Base fehlt
- **WHEN** der Artikelverfolgungscode des Artikels „Box vorhanden“ verpflichtend macht und der Benutzer die Karte mit Herstellernummer, aber ohne Angabe zu „Box vorhanden“ schließt
- **THEN** wird für diese Zeile keine Werkstattzeile angelegt und die Fehlerliste enthält die Zeile mit der Meldung zu den fehlenden Angaben

### Requirement: Nicht unterstützte Zeilen werden gemeldet
Das System SHALL eine Zeile nicht senden und sie mit Begründung in der Fehlerliste melden, wenn der Artikel keine Seriennummernverfolgung beim Einkauf hat, wenn keine Seriennummer vorhanden ist und der Artikel keine Seriennr.-Nummernserie hat, oder wenn die Menge der Einkaufszeile (Basis) ungleich 1 ist. In diesen Fällen SHALL keine Seriennummer gezogen und keine Karte geöffnet werden.

#### Scenario: Artikel ohne Seriennummernverfolgung
- **WHEN** der Benutzer die Ankunft einer Zeile bestätigt, deren Artikel keinen Artikelverfolgungscode mit Seriennummernverfolgung beim Einkauf hat
- **THEN** wird keine Karte geöffnet, keine Werkstattzeile angelegt und die Fehlerliste enthält die Zeile mit dem Hinweis auf fehlende Seriennummernverfolgung

#### Scenario: Keine Seriennr.-Nummernserie am Artikel
- **WHEN** die Einkaufszeile keine Seriennummer hat und am Artikel keine Seriennr.-Nummernserie hinterlegt ist
- **THEN** wird keine Nummer gezogen, keine Karte geöffnet und die Fehlerliste enthält die Zeile mit dem Hinweis auf die fehlende Nummernserie

#### Scenario: Menge ungleich 1
- **WHEN** die Einkaufszeile eine Menge (Basis) von 2 hat
- **THEN** wird keine Karte geöffnet, keine Werkstattzeile angelegt und die Fehlerliste enthält die Zeile mit dem Hinweis, dass nur Zeilen mit Menge 1 unterstützt werden
