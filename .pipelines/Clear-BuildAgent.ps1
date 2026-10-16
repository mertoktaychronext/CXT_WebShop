<#
.SYNOPSIS
    Räumt den Build-Container von CHX.Base auf dem Agent ab und zeigt, wer den Speicher belegt.

.DESCRIPTION
    Run-AlPipeline entfernt den Container am Ende selbst – aber nicht, wenn der Lauf abgebrochen wird
    (Cancel, Timeout, Agent-Neustart). Dann läuft die Hyper-V-VM des Containers mit 8 GB weiter und fehlt
    dem nächsten Lauf. Dieses Skript läuft deshalb vor und nach Run-AlPipeline:
      - entfernt den Container dieser Pipeline, falls er noch existiert
      - entfernt beendete Container dieser Pipeline (kein Zugriff auf Container anderer Pipelines)
      - schreibt freien Speicher und laufende Container ins Log, damit Engpässe erkennbar sind
#>
param(
    # Derselbe Wert wie pipelineName in Invoke-AlPipeline.ps1
    [Parameter(Mandatory)]
    [string] $PipelineName
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

Write-Host "##[group]Build-Agent aufräumen"
Write-MemoryInfo 'Vorher'

Write-Host 'Laufende Container auf dem Host:'
docker ps --format '  {{.Names}}  ({{.Image}}, seit {{.RunningFor}})'

$existing = docker ps -a --filter "name=^/$ContainerName$" --format '{{.Names}}'
if ($existing) {
    Write-Host "Container $ContainerName existiert noch (abgebrochener Lauf?) – wird entfernt."
    Import-Module BcContainerHelper -DisableNameChecking
    Remove-BcContainer -containerName $ContainerName   # entfernt auch Hosts-Einträge und Session
}
else {
    Write-Host "Kein Container $ContainerName vorhanden."
}

Write-MemoryInfo 'Nachher'
Write-Host "##[endgroup]"
exit 0
