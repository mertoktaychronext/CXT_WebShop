## REMOVED Requirements

### Requirement: Currency-based line generation
**Reason**: Die Aktion "Add all Currencies" wird durch "Add all Countries" ersetzt; Zeilen werden pro Land (mit Landeswährung) statt pro Währung erzeugt.
**Migration**: Länder auf "Countries/Regions" mit `"CXW Sales Price Activated"` und `"CXW Sales Price Currency Code"` einrichten und die Aktion "Add all Countries" verwenden (Capability `sales-price-country-copy`).

### Requirement: Idempotency of currency expansion
**Reason**: Ersetzt durch die Idempotenz der Länder-Expansion; `"CXW Currencies Processed"` wird zu `"CXW Countries Processed"` umbenannt.
**Migration**: Siehe Requirement "Idempotenz der Länder-Expansion" in `sales-price-country-copy`.

### Requirement: Pre-condition guards preserved
**Reason**: Die Vorbedingungen werden unverändert, aber für die neue Aktion in `sales-price-country-copy` spezifiziert.
**Migration**: Siehe Requirement "Vorbedingungen der Aktion" in `sales-price-country-copy`.

### Requirement: Field copy semantics preserved
**Reason**: Die Feldübernahme wird unverändert für die neue Aktion in `sales-price-country-copy` spezifiziert.
**Migration**: Siehe Requirement "Feldübernahme von der Quellzeile" in `sales-price-country-copy`.
