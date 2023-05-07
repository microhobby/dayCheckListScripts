[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', ""
)]
param()

$VERSION = Get-Content "$PSScriptRoot/versions/linuxKernel"

# ret object
$ret = [PSCustomObject]@{
    lines = [System.Collections.ArrayList]::new()
    linesformated = [System.Collections.ArrayList]::new()
    code = 0
    slackbot = $false
}

$get = Invoke-WebRequest `
    -Uri "https://api.github.com/repos/torvalds/linux/git/matching-refs/tags/v6"

$obj = ConvertFrom-Json $get
# latest release
$latestVersion = $obj[$obj.Count -1].ref

if ($latestVersion -ne $VERSION) {
    $ret.code = 3
    $ret.lines.Add("New Kernel Linux version released -> $latestVersion") | Out-Null

    # update the version file
    $latestVersion | Out-File ./versions/linuxKernel -Force -NoNewline
}

$json = ConvertTo-Json -InputObject $ret
Write-Host $json
