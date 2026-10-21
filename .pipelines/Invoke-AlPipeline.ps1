<#
.SYNOPSIS
    Baut CHX.Webshop in einem BC-Container, führt CodeCop und UICop sowie alle Tests aus der Test-App aus.

.DESCRIPTION
    Läuft auf dem Self-hosted Agent (Windows + Docker). Lokal genauso aufrufbar, wenn Docker installiert ist:
        .\.pipelines\Invoke-AlPipeline.ps1 -Select Current -Country de

    Ordnerstruktur (relativ zum Repo-Root):
        app\                     CHX.Webshop
        test\                    CHX.Webshop Tests
        .pipelines\stubs\        Attrappe von SalLicenseCheckApp (vorkompiliert, Quelle daneben) – nur für den Container
        .pipelines\dependencies\ Salini Base App, CHX.Base und ChronextBC (.app) in den Versionen, die app\app.json verlangt
        .pipelines\previous\     (optional) zuletzt ausgelieferte CHX.Webshop für Upgrade- und Breaking-Change-Prüfung

    Lizenz: Die Salini Base App hängt von SalLicenseCheckApp ab. SalLicenseCheckApp gibt es in keinem BC-Artefakt,
    und sie erwartet einen lizenzierten Mandanten. Im Container wird deshalb die Attrappe installiert (gleiche App-ID,
    licenseCheck ohne Prüfung). Sie wird nie ausgeliefert und ist kein Bestandteil des Build-Artefakts.

    AppSourceCop ist aus: CHX.Webshop ist eine PTE ohne app\AppSourceCop.json.
#>
param(
    [ValidateSet('Current', 'Minimum', 'NextMinor', 'NextMajor')]
    [string] $Select = 'Current',

    [string] $Country = 'de',

    [string] $OutputFolder = (Join-Path $PSScriptRoot '..\.output')
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$appJson = Get-Content (Join-Path $repoRoot 'app\app.json') -Raw | ConvertFrom-Json

# --- BcContainerHelper -------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name BcContainerHelper)) {
    Install-Module BcContainerHelper -Force -AllowClobber -Scope CurrentUser
}
Import-Module BcContainerHelper -DisableNameChecking

# In BC-29-Containern stürzt WinRM ab und reißt die Session mit "An internal error occurred" ab
# (BcContainerHelper-Issue offen, BC 28.5 nicht betroffen). Mit Hyper-V-Isolation nutzt BcContainerHelper
# sonst WinRM über SSL; usePwshForBc24 allein ändert nur die PowerShell-Version, nicht die Verbindungsart.
$bcContainerHelperConfig.useWinRmSession = 'never'   # PowerShell Direct statt WinRM
$bcContainerHelperConfig.usePwshForBc24 = $false

# --- BC-Version wählen ---------------------------------------------------------------------------
$insider = $Select -in @('NextMinor', 'NextMajor')
switch ($Select) {
    'Current' {
        $artifactUrl = Get-BCArtifactUrl -type Sandbox -country $Country -select Current
    }
    'Minimum' {
        # Niedrigste unterstützte Version laut app.json ("application"), z. B. 28.0.0.0 → erster Build von 28.0
        $major = $appJson.application.Split('.')[0]
        $artifactUrl = Get-BCArtifactUrl -type Sandbox -country $Country -version "$major.0" -select First
    }
    default {
        $artifactUrl = Get-BCArtifactUrl -type Sandbox -country $Country -select $Select -accept_insiderEula
    }
}
if (-not $artifactUrl) { throw "Keine BC-Artefakte für '$Select' / '$Country' gefunden." }
Write-Host "BC-Artefakt: $artifactUrl"

# --- Lizenz-Attrappe ----------------------------------------------------------------------------
$licenseStub = @(Get-ChildItem (Join-Path $repoRoot '.pipelines\stubs') -Filter 'Salini Life GmbH_SalLicenseCheckApp_*_STUB.app' | ForEach-Object FullName)
if ($licenseStub.Count -ne 1) { throw "Genau eine SalLicenseCheckApp-Attrappe in .pipelines\stubs erwartet, gefunden: $($licenseStub.Count)." }
Write-Host "Lizenz-Attrappe: $($licenseStub[0])"

# --- Abhängigkeiten -----------------------------------------------------------------------------
# Jede Datei muss mindestens die Version haben, die app\app.json verlangt, sonst schlägt erst die Installation
# von CHX.Webshop mit einer schwer lesbaren Meldung fehl. Reihenfolge = Installationsreihenfolge:
# ChronextBC hängt von CHX.Base und Salini Base App ab, CHX.Base von Salini Base App.
function Get-DependencyFile([string] $AppName, [string] $FilePrefix) {
    $files = @(Get-ChildItem (Join-Path $repoRoot '.pipelines\dependencies') -Filter "$FilePrefix*.app")
    if ($files.Count -ne 1) {
        throw "Genau eine $AppName in .pipelines\dependencies erwartet ('$FilePrefix<Version>.app'), gefunden: $($files.Count). Siehe .pipelines\dependencies\README.md."
    }
    $dependency = $appJson.dependencies | Where-Object { $_.name -eq $AppName }
    $fileVersion = [version]($files[0].BaseName.Substring($FilePrefix.Length))
    if ($dependency -and ($fileVersion -lt [version]$dependency.version)) {
        throw "$AppName $fileVersion in .pipelines\dependencies ist älter als die Abhängigkeit $($dependency.version) in app\app.json. Siehe .pipelines\dependencies\README.md."
    }
    Write-Host "${AppName}: $($files[0].FullName)"
    return $files[0].FullName
}

$installApps = @(
    $licenseStub[0]
    (Get-DependencyFile 'Salini Base App' 'Salini Life GmbH_Salini Base App_')
    (Get-DependencyFile 'CHX.Base' 'Salini Life_CHX.Base_')
    (Get-DependencyFile 'ChronextBC' 'Default Publisher_ChronextBC_')
)

$previousApps = @()
$previousFolder = Join-Path $repoRoot '.pipelines\previous'
if (Test-Path $previousFolder) {
    $previousApps = @(Get-ChildItem $previousFolder -Filter '*.app' | ForEach-Object FullName)
}

# --- Pipeline ------------------------------------------------------------------------------------
$password = 'P' + ([guid]::NewGuid().ToString('N').Substring(0, 16)) + '!a1'
$credential = New-Object pscredential 'admin', (ConvertTo-SecureString $password -AsPlainText -Force)

$params = @{
    pipelineName         = 'CHXWebshop'
    baseFolder           = $repoRoot
    appFolders           = @('app')
    testFolders          = @('test')
    installApps          = $installApps       # vor dem Kompilieren der App installiert
    artifact             = $artifactUrl
    imageName            = 'bcbuild'          # Image-Cache auf dem Agent → schnellere Folgeläufe
    credential           = $credential
    installTestRunner    = $true
    installTestFramework = $true              # Library Assert und Any für die Test-App
    enableCodeCop        = $true
    enableUICop          = $true
    azureDevOps          = $true              # Compiler-Fehler/Warnungen erscheinen in der Build-Übersicht
    testResultsFormat    = 'JUnit'
    buildArtifactFolder  = $OutputFolder
    failOn               = 'error'
    accept_insiderEula   = $insider
}
if ($previousApps) {
    # Upgrade-Test + Breaking-Change-Prüfung gegen die zuletzt ausgelieferte Version
    $params.previousApps = $previousApps
}

Run-AlPipeline @params
