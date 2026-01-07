[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', ""
)]
param()

# check if the file exists, if not touch it
$VERSION = ""
if (-not (Test-Path "$PSScriptRoot/../versions/vscodeDocker")) {
    New-Item -Path "$PSScriptRoot/../versions/vscodeDocker" -ItemType File -Force | Out-Null
} else {
    $VERSION = Get-Content "$PSScriptRoot/../versions/vscodeDocker"
}

# ret object
$ret = [PSCustomObject]@{
    lines = [System.Collections.ArrayList]::new()
    linesformated = [System.Collections.ArrayList]::new()
    code = 0
    slackbot = $true
}

$get = Invoke-WebRequest `
    -Uri "https://api.github.com/repos/microsoft/vscode-containers/releases"

$obj = ConvertFrom-Json $get
# latest release
$latestVersion = $obj[0].tag_name

if ($latestVersion -ne $VERSION) {
    $ret.code = 3

    # printer
    $ret.lines.Add(
        "New VS Code Docker Extension version released -> $latestVersion"
    ) | Out-Null

    # bot
    $ret.linesformated.Add(
        "New VS Code Docker Extension version released -> ``$latestVersion``"
    ) | Out-Null
    $url = $obj[0].html_url
    $ret.linesformated.Add(
        "<$url>"
    ) | Out-Null

    # update the version file
    $latestVersion | Out-File "$PSScriptRoot/../versions/vscodeDocker" -Force -NoNewline
}

$json = ConvertTo-Json -InputObject $ret
Write-Host $json
