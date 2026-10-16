# Abhängigkeiten für den Build-Container

Die Pipeline installiert diese Apps vor CHX.Webshop im Container, in dieser Reihenfolge. Von jeder App liegt hier genau **eine** Datei:

| App | Dateiname | Mindestversion | Aktueller Stand |
|---|---|---|---|
| Salini Base App | `Salini Life GmbH_Salini Base App_<Version>.app` | laut `app/app.json` | 28.0.0.13, aus `CHX.Base/.pipelines/dependencies` |
| CHX.Base | `Salini Life_CHX.Base_<Version>.app` | laut `app/app.json` | 28.0.0.1, lokaler Build aus dem CHX.Base-Repo |
| ChronextBC | `Default Publisher_ChronextBC_<Version>.app` | laut `app/app.json` | 1.0.1.17, lokal aus dem Hersteller-Quellcode kompiliert (`app.json` ohne `build`-Abschnitt) |

Heruntergeladene Symbole aus `.alpackages` reichen nicht, es muss jeweils die vollständige, veröffentlichbare App sein.

`Invoke-AlPipeline.ps1` bricht ab, wenn eine Datei fehlt, mehrfach vorhanden ist oder älter ist als die Abhängigkeit in `app/app.json`.

ChronextBC 1.0.1.17 verlangt selbst CHX.Base ≥ 27.0.3.8 und Salini Base App ≥ 28.0.0.13 sowie BC 28. Darum gibt es keinen Lauf „Minimum“.

## Aktualisieren

1. Die freigegebene `.app` besorgen: Pipeline-Artefakt der jeweiligen App (`CHXBase-de`, `SaliniBaseApp-de`) oder die ausgelieferte Datei. ChronextBC kommt vom Hersteller bzw. aus dessen Repo.
2. Alte Datei löschen, neue hier ablegen und mit `git add -f` aufnehmen (`*.app` steht in `.gitignore`).
