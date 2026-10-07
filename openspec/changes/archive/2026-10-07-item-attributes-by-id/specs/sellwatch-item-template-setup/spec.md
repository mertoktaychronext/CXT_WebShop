## ADDED Requirements

### Requirement: SellWatch-Artikel werden mit Seriennummernverfolgung angelegt
Jeder über SellWatch angelegte Artikel SHALL mit Seriennummernverfolgung angelegt werden. Der Artikelverfolgungscode SHALL an den SellWatch-Artikelvorlagen (Standard und Kommission) eingerichtet werden und wird über die Standard-Artikelanlage aus der Vorlage übernommen. Vor dem Anlegen des Artikels SHALL das System prüfen, dass die für die Angebotsart zuständige Artikelvorlage einen Artikelverfolgungscode hat und dieser Code Seriennummernverfolgung beim Einkauf („SN Purchase Inbound Tracking“) vorsieht. Ist das nicht der Fall, SHALL die Verarbeitung mit einer Fehlermeldung abbrechen, die den Code der Artikelvorlage nennt; es SHALL kein Artikel angelegt werden, und das Angebot SHALL wie bei den übrigen Konfigurationsfehlern mit Fehlertext offen bleiben.

#### Scenario: Vorlage mit Seriennummernverfolgung
- **WHEN** die zuständige Artikelvorlage den Artikelverfolgungscode „SN-UHR“ mit Seriennummernverfolgung beim Einkauf hat und eine SellWatch-Anfrage verarbeitet wird
- **THEN** hat der neue Artikel den Artikelverfolgungscode „SN-UHR“

#### Scenario: Vorlage ohne Artikelverfolgungscode
- **WHEN** an der zuständigen Artikelvorlage kein Artikelverfolgungscode eingerichtet ist und eine SellWatch-Anfrage verarbeitet wird
- **THEN** wird kein Artikel angelegt, und das Angebot bleibt mit einer Fehlermeldung offen, die die Artikelvorlage nennt und auf die fehlende Seriennummernverfolgung hinweist

#### Scenario: Artikelverfolgungscode ohne Seriennummernverfolgung
- **WHEN** die zuständige Artikelvorlage einen Artikelverfolgungscode hat, der nur Chargenverfolgung vorsieht
- **THEN** wird kein Artikel angelegt, und das Angebot bleibt mit derselben Fehlermeldung offen
