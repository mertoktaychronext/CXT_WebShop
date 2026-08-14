# Dokumentation – CHX.Webshop

Diese Business-Central-Erweiterung bündelt vier Bereiche: die Verwaltung von Webshop-Verkaufspreisen (Import, Prüfung, Freigabe, Fremdwährungs-Vervielfältigung), die SellWatch-Ankaufsintegration für gebrauchte Uhren (automatisierte Lieferanten-/Bestellanlage, Statusrückmeldung, Online-Freigabeprüfung), die Workshop-Ankaufsprüfung (externe Echtheitsprüfung angekaufter Uhren über eine Werkstatt, mit automatisiertem Wareneingang bzw. Stornierung) und den Kommissionsverkauf (verzögerte, automatische EK-Faktura für auf Kommission verkaufte Uhren nach der VK-Rechnungsbuchung). Wähle das passende Handbuch:

## Handbücher

| Zielgruppe | Deutsch | English |
|---|---|---|
| 👤 Endnutzer | [user-manual-de.md](user-manual-de.md) | [user-manual-en.md](user-manual-en.md) |
| 🔑 Key User | [key-user-manual-de.md](key-user-manual-de.md) | [key-user-manual-en.md](key-user-manual-en.md) |
| 🛠️ Entwickler | [developer-manual-de.md](developer-manual-de.md) | [developer-manual-en.md](developer-manual-en.md) |

## Weitere Dokumentation

- **Funktionsregister** (alle AL-Prozeduren, Trigger und Events, für Geschäftsführung/Key User): [funktionsregister/gesamtuebersicht.md](funktionsregister/gesamtuebersicht.md), Details in [funktionsregister/funktionsregister-sl-chronext-webshop.md](funktionsregister/funktionsregister-sl-chronext-webshop.md)
- **Schwachstellen- und Cleanup-Bericht** (Senior-Dev-Review: behobene und offene Findings): [SCHWACHSTELLEN.md](SCHWACHSTELLEN.md) — bezieht sich auf den Stand vor der SellWatch-Integration (siehe Erstellungsdatum dort)
- **OpenSpec-Spezifikationen** (dauerhafte, fachliche Anforderungsdokumentation einzelner Fähigkeiten): [`../openspec/specs/`](../openspec/specs/)

---

*Erstellt am 2026-08-04, aktualisiert am 2026-08-07 (SellWatch-Ankaufsintegration ergänzt), aktualisiert am 2026-08-13 (Workshop-Ankaufsprüfung in allen drei Handbüchern ergänzt — war bislang undokumentiert, obwohl bereits im Funktionsregister erfasst), aktualisiert am 2026-08-14 (Kommissionsverkauf ergänzt — verzögerte, automatische EK-Faktura für auf Kommission verkaufte Uhren; dabei auch die SellWatch-Artikelvorlagen-Konfiguration im Entwicklerhandbuch korrigiert, die fälschlich als verworfen dokumentiert war). Handbücher/Funktionsregister durch reine Analyse (keine Codeänderungen); der Schwachstellenbericht enthält zusätzlich tatsächlich durchgeführte Code-Änderungen (siehe dort).*
