[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', ""
)]
param()

$VERSION = Get-Content "$PSScriptRoot/versions/vscodeDocker"

# ret object
$ret = [PSCustomObject]@{
    lines = [System.Collections.ArrayList]::new()
    linesformated = [System.Collections.ArrayList]::new()
    code = 0
    slackbot = $true
}

$get = Invoke-WebRequest `
    -Uri "https://api.github.com/repos/microsoft/vscode-docker/releases"

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
    $latestVersion | Out-File "$PSScriptRoot/versions/vscodeDocker" -Force -NoNewline
}

$json = ConvertTo-Json -InputObject $ret
Write-Host $json
