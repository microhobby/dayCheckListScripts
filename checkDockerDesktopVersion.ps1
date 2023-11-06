[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', ""
)]
param()

$VERSION = Get-Content "$PSScriptRoot/../versions/dockerDesktop"

# for debug comment this
$WarningPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'

# use a nuget 🐥
$nuget = (Get-PackageSource -Name MyNuGet)

if ($null -eq $nuget) {
    Register-PackageSource `
        -Name MyNuGet `
        -Location https://www.nuget.org/api/v2 `
        -ProviderName NuGet `
        -Trusted | Out-Null
}

$browser = (Get-Package -Name HtmlAgilityPack -Destination $env:NUGET_DEST)

if ($null -eq $browser) {
    Install-Package `
        -Name HtmlAgilityPack `
        -ProviderName NuGet `
        -Scope CurrentUser `
        -RequiredVersion 1.11.46 `
        -Source MyNuGet `
        -SkipDependencies `
        -Destination $env:NUGET_DEST `
        -Force | Out-Null
}

# load the dll
$_dllPath = Resolve-Path "$env:NUGET_DEST/HtmlAgilityPack.1.11.46/lib/netstandard2.0/HtmlAgilityPack.dll"
[System.Reflection.Assembly]::LoadFrom($_dllPath) | Out-Null

# get the version directly from Docker page
$_url = "https://docs.docker.com/desktop/release-notes/"
$web = [HtmlAgilityPack.HtmlWeb]::new()
$html = $web.Load($_url)

$latestVersion = $html.DocumentNode.SelectSingleNode("//h2").InnerText

# remove the \nlink
$latestVersion = $latestVersion.Replace("`n", "")
$latestVersion = $latestVersion.Replace("link", "")

# ret object
$ret = [PSCustomObject]@{
    lines = [System.Collections.ArrayList]::new()
    linesformated = [System.Collections.ArrayList]::new()
    code = 0
    slackbot = $true
}

if ($latestVersion -ne $VERSION) {
    $ret.code = 3

    # printer
    $ret.lines.Add(
        "New Docker Desktop version -> $latestVersion"
    ) | Out-Null

    # bot
    $ret.linesformated.Add(
        "New Docker Desktop version -> ``$latestVersion``"
    ) | Out-Null

    $ret.linesformated.Add(
        "<https://docs.docker.com/desktop/release-notes/>"
    ) | Out-Null

    # update the version file
    $latestVersion | Out-File "$PSScriptRoot/../versions/dockerDesktop" -Force -NoNewline
}

$json = ConvertTo-Json -InputObject $ret
Write-Host $json
