# purchase-workshop-integration

Ankaufsprozess für Uhren mit externer Workshop-Prüfung: Purchase-Order-Zeile → Workshop-Prüfung per API → automatisierter Wareneingang oder Stornierung. Siehe proposal.md/design.md für Details.

## Konfiguration nach dem Deployment

### 1. OAuth2 S2S (Entra) für die Workshop-API einrichten

Die Custom API `page "CXW Workshop Line API"` (Endpunkt-Muster `.../api/saliniLife/workshop/v1.0/companies({companyId})/workshopLines`) verwendet Standard-BC-API-Authentifizierung — keine eigene Auth-Logik im AL-Code:

1. In Microsoft Entra ID eine App-Registrierung für den Workshop-Dienst anlegen (Client Credentials Flow, kein interaktiver Login).
2. Der App-Registrierung Zugriff auf die Business-Central-API erteilen (Business Central Admin Center → API-Zugriff, bzw. Azure AD App-Berechtigung `Dynamics 365 Business Central`).
3. In Business Central einen dedizierten Benutzer für den Workshop-Dienst anlegen und ihm **ausschließlich** das Permission Set `"CXW Workshop API"` zuweisen (kein Zugriff auf Purchase Line, Item oder andere Tabellen).
4. Client-ID, Client-Secret und Tenant-ID an den Workshop-Dienstbetreiber übergeben.

### 2. Job-Queue-Eintrag für die Verarbeitung anlegen

Codeunit `"CXW Process Workshop Lines"` (ID 60331) verarbeitet alle Workshop Lines im Status "WS geprüft" (Wareneingang buchen bzw. PO stornieren, siehe design.md).

1. Job-Queue-Einträge → Neu.
2. Objekttyp: Codeunit, Objekt-ID: 60331 ("CXW Process Workshop Lines").
3. Empfohlene Wiederholung: alle 5 Minuten.
4. Der ausführende Benutzer benötigt das Permission Set `"CXW Workshop All"` sowie die Standard-Einkaufs-/Lager-Berechtigungen für Wareneingangsbuchung (`Codeunit "Purch.-Post"`) und Item-Attribute-Pflege.

## Bekannte Einschränkungen (siehe design.md)

- Nur der Standardfall "eine Purchase Order = eine Purchase Line" ist implementiert; gemischte Purchase Orders sind als `// TODO:` markiert, nicht implementiert.
- Die zehn Attributfelder tragen Platzhalter-Captions "Attribut 1"–"Attribut 10"; die finale Benennung ist offen.
