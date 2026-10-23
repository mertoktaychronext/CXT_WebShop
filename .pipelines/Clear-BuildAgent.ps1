<#
.SYNOPSIS
    Räumt den Build-Container von CHX.Base auf dem Agent ab und zeigt, wer den Speicher belegt.

.DESCRIPTION
    Run-AlPipeline entfernt den Container am Ende selbst – aber nicht, wenn der Lauf abgebrochen wird
    (Cancel, Timeout, Agent-Neustart). Dann läuft die Hyper-V-VM des Containers mit 8 GB weiter und fehlt
    dem nächsten Lauf. Dieses Skript läuft deshalb vor und nach Run-AlPipeline:
      - entfernt den Container dieser Pipeline, falls er noch existiert
      - entfernt beendete Container dieser Pipeline (kein Zugriff auf Container anderer Pipelines)
      - löscht BC-Artefakte und bcbuild-Images, die seit KeepDays nicht mehr benutzt wurden
        (pro BC-Version ein Image mit 15–25 GB – mit Current, Minimum, NextMinor und NextMajor und
        monatlichen BC-Updates läuft C:\ sonst voll)
      - löscht bei weniger als MinFreePercent freiem Platz alle Artefakte und Images, die gerade kein
        Container nutzt – der nächste Lauf lädt sie dann neu
      - schreibt freien Speicher, Plattenplatz und laufende Container ins Log, damit Engpässe erkennbar sind
#>
param(
    # Derselbe Wert wie pipelineName in Invoke-AlPipeline.ps1
    [Parameter(Mandatory)]
    [string] $PipelineName,

    # Artefakte und Images, die so lange nicht benutzt wurden, werden gelöscht
    [int] $KeepDays = 7,

    # Darunter wird alles Ungenutzte gelöscht, auch was jünger als KeepDays ist
    [int] $MinFreePercent = 20
)

$ErrorActionPreference = 'Continue'   # Aufräumen darf den Build nie selbst scheitern lassen

# Gleiche Ableitung wie in Run-AlPipeline: 'CHXBase' → 'chxbase-bld'
$ContainerName = "$($PipelineName.Replace('.', '-') -replace '[^a-zA-Z0-9-]', '')-bld".ToLower()

function Write-MemoryInfo([string] $title) {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $freeGb = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    Write-Host "$title – Arbeitsspeicher Host: $freeGb GB frei von $totalGb GB"
}

function Get-FreeDiskPercent {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    return [math]::Round($disk.FreeSpace / $disk.Size * 100, 1)
}

function Write-DiskInfo([string] $title) {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $totalGb = [math]::Round($disk.Size / 1GB, 1)
    $freeGb = [math]::Round($disk.FreeSpace / 1GB, 1)
    Write-Host "$title – Platte C:\: $freeGb GB frei von $totalGb GB ($(Get-FreeDiskPercent) %)"
}

Write-Host "##[group]Build-Agent aufräumen"
Write-MemoryInfo 'Vorher'
Write-DiskInfo 'Vorher'

Write-Host 'Laufende Container auf dem Host:'
docker ps --format '  {{.Names}}  ({{.Image}}, seit {{.RunningFor}})'

# Entfernt BC-Images, die kein Container nutzt und deren Artefakte nicht mehr im Cache liegen –
# dieselbe Regel wie Flush-ContainerHelperCache -cache images. Das kann nicht selbst aufgerufen werden:
# BcContainerHelper läuft mit StrictMode, und ein Image ohne Umgebungsvariablen bricht die Funktion
# mit "Die Eigenschaft "Env" wurde für dieses Objekt nicht gefunden" ab (6.1.19).
function Remove-UnusedBcImages {
    $cacheFolder = $bcContainerHelperConfig.bcartifactsCacheFolder
    $usedImages = @(docker ps -a --no-trunc --format '{{.Image}}')
    foreach ($line in @(docker images --no-trunc --format '{{.Repository}}:{{.Tag}}|{{.ID}}')) {
        $imageName, $imageId = $line.Split('|')
        if ($usedImages -contains $imageName -or $usedImages -contains $imageId) { continue }
        $artifactUrl = @(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' $imageId) |
            Where-Object { $_ -like 'artifactUrl=*' } | Select-Object -First 1
        if (-not $artifactUrl) { continue }   # kein auf Artefakten gebautes Image – nicht anfassen
        # artifactUrl=https://<host>/sandbox/28.0.12345.0/de?... → <cache>\sandbox\28.0.12345.0\de
        $artifactPath = ([uri]$artifactUrl.Substring('artifactUrl='.Length).Split('?')[0]).AbsolutePath.TrimStart('/')
        if (-not (Test-Path (Join-Path $cacheFolder $artifactPath))) {
            Write-Host "Image $imageName ($artifactPath) – Artefakte nicht mehr im Cache, wird entfernt."
            docker rmi --force $imageId | Out-Null
        }
    }
    docker image prune -f | Out-Null   # verwaiste Zwischen-Layer
}

try {
    Import-Module BcContainerHelper -DisableNameChecking

    $existing = docker ps -a --filter "name=^/$ContainerName$" --format '{{.Names}}'
    if ($existing) {
        Write-Host "Container $ContainerName existiert noch (abgebrochener Lauf?) – wird entfernt."
        Remove-BcContainer -containerName $ContainerName   # entfernt auch Hosts-Einträge und Session
    }
    else {
        Write-Host "Kein Container $ContainerName vorhanden."
    }

    # Cache-Namen kleingeschrieben angeben, BcContainerHelper vergleicht sie nach ToLowerInvariant() case-sensitiv.
    Write-Host "Artefakte und Images entfernen, die seit $KeepDays Tagen nicht benutzt wurden."
    Flush-ContainerHelperCache -cache 'bcartifacts' -keepDays $KeepDays
    Remove-UnusedBcImages

    if ((Get-FreeDiskPercent) -lt $MinFreePercent) {
        Write-Host "##[warning]Weniger als $MinFreePercent % frei auf C:\ – alle ungenutzten Artefakte und Images werden entfernt."
        Flush-ContainerHelperCache -cache 'bcartifacts' -keepDays 0
        Remove-UnusedBcImages
    }
}
catch {
    # Aufräumen darf den Build nie scheitern lassen – terminierende Fehler aus BcContainerHelper hier abfangen
    Write-Host "##[warning]Aufräumen unvollständig: $($_.Exception.Message)"
}

Write-Host 'Docker-Speicher:'
docker system df

Write-MemoryInfo 'Nachher'
Write-DiskInfo 'Nachher'
Write-Host "##[endgroup]"
exit 0
