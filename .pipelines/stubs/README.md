# SalLicenseCheckApp – Pipeline-Attrappe

**Nur für den Build-Container der Pipeline. Nie in einer Sandbox oder beim Kunden installieren.**

CHX.Webshop hängt (direkt und über CHX.Base) von der Salini Base App ab, diese von SalLicenseCheckApp. Die echte App ist in keinem BC-Artefakt enthalten und prüft gegen einen lizenzierten Mandanten. Die Attrappe hat dieselbe App-ID (`51c58449-a98e-453c-a8ab-5218fa77c484`) und dieselbe öffentliche Codeunit 5729367 `SLPLicenseExternalEvent` mit `licenseCheck(appId: Guid; tenantIdCheck: Guid)` – mit leerem Rumpf. Damit gilt im Container jeder Mandant als lizenziert.

Quelle: übernommen aus `CHX.Base/.pipelines/stubs` (dort aus dem Repo der Salini Base App). Abweichung: `platform` 27.0.0.0 statt 28.0.0.0, damit sie in CHX.Base auch im Lauf „Minimum“ (BC 27) installierbar ist.

`Invoke-AlPipeline.ps1` installiert die vorkompilierte Datei `Salini Life GmbH_SalLicenseCheckApp_<Version>_STUB.app` über `installApps`. Sie ist kein Teil des Build-Artefakts.

## Neu bauen

Nötig, wenn die Salini Base App eine höhere Mindestversion von SalLicenseCheckApp verlangt oder die echte App ihre Schnittstelle ändert:

1. In `SalLicenseCheckApp/app.json` die Version anheben (mindestens die Version, die die Salini Base App verlangt).
2. Signatur in `src/SLPLicenseExternalEvent.Codeunit.al` mit der echten App abgleichen.
3. Kompilieren, z. B. mit den Symbolen aus `app/.alpackages` (absolute Pfade verwenden):

   ```powershell
   alc.exe /project:"<Repo>\.pipelines\stubs\SalLicenseCheckApp" /packagecachepath:"<Repo>\app\.alpackages" `
           /out:"<Repo>\.pipelines\stubs\Salini Life GmbH_SalLicenseCheckApp_<Version>_STUB.app"
   ```

4. Alte `.app` löschen und die neue mit `git add -f` aufnehmen (`*.app` steht in `.gitignore`).
