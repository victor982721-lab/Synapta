. "$PSScriptRoot/Cortex.Common.ps1"

function Invoke-CortexArtifactDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Destination,
        [string]$RunIdOrTag,
        [string]$ArtifactName,
        [string]$Repository,
        [string]$DownloadUrl
    )

    Assert-CortexWindowsPlatform

    if (-not (Test-Path -Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    $useGh = Test-CortexCommand -Name 'gh'
    if ($useGh -and $RunIdOrTag -and $ArtifactName -and $Repository) {
        $args = @('run', 'download', $RunIdOrTag, '-n', $ArtifactName, '-R', $Repository, '-D', $Destination)
        Invoke-CortexCommand -FilePath 'gh' -Arguments $args
        return
    }

    if (-not $DownloadUrl) {
        throw 'Se requiere gh CLI o un DownloadUrl para recuperar el artefacto.'
    }

    $tempZip = Join-Path $Destination 'artifact.zip'
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $tempZip -UseBasicParsing
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $Destination, $true)
    Remove-Item -Path $tempZip -Force
}
