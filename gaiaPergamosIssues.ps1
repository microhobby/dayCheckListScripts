[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', ""
)]
param()

$repoGroup = "gaiaBuildSystem"
$repoName = "Pergamos"
$CHECKED = "$PSScriptRoot/../versions/$repoName"

if ($null -eq ("Issue" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Collections;
using System.Collections.Generic;

public class Issue {
    public Int64 id { get; set; }
}

public class Issues : ArrayList {
    public Issues() : base() {}
}
"@
}

# make sure the versions folder exists
New-Item -Path "$PSScriptRoot/../versions" -ItemType Directory -Force | Out-Null
# make sure the ../versions/$repoName file exists
if (-not (Test-Path "$PSScriptRoot/../versions/$repoName")) {
    [Issues]::new() | `
        ConvertTo-Json | Out-File "$PSScriptRoot/../versions/$repoName"
}

# ret object
$ret = [PSCustomObject]@{
    lines = [System.Collections.ArrayList]::new()
    linesformated = [System.Collections.ArrayList]::new()
    code = 0
    slackbot = $false
}

$get = Invoke-WebRequest `
    -Uri "https://api.github.com/repos/$repoGroup/$repoName/issues?state=open"

$obj = ConvertFrom-Json $get
# how many issues we have
$count = $obj.Count

# check if we have something from ../versions/linuxkerneldev
# check if the file exists
if (-not (Test-Path $CHECKED)) {
    # creat it
    # obj to json
    $json = ConvertTo-Json -InputObject (New-Object Issues)

    # save it
    $json | Out-File "$PSScriptRoot/../versions/$repoName"
}

# read it
$json = Get-Content "$CHECKED" | ConvertFrom-Json
$notCheckedIssues = [System.Collections.ArrayList]::new()
$issues = $json

if ($null -eq $issues) {
    $issues = New-Object Issues
} else {
    $_tmpIssues = $issues
    $issues = New-Object Issues

    foreach ($issue in $_tmpIssues) {
        $_newIssue = [Issue]::new()
        $_newIssue.id = $issue.id
        $issues.Add($_newIssue) | Out-Null
    }
}

# check if we have new issues
foreach ($ghIssue in $obj) {
    # check if the id exists in $issues
    $id = $ghIssue.id

    $idExists = $issues | Where-Object { $_.id -eq $id }

    if (-not $idExists) {
        $notCheckedIssues.Add($ghIssue) | Out-Null
         $_newIssue = [Issue]::new()
        $_newIssue.id = [Int64]$id
        $issues.Add($_newIssue) | Out-Null
    }
}

# ok, we need to save now the checked issues
# obj to json
$json = ConvertTo-Json -InputObject $issues

# save it
$json | Out-File "$PSScriptRoot/../versions/$repoName"

if ($notCheckedIssues.Count -gt 0) {
    $ret.code = 1
    $ret.lines.Add("$repoGroup/") | Out-Null
    $ret.lines.Add("$repoName") | Out-Null
    $ret.lines.Add("-----------------------") | Out-Null
    $ret.lines.Add("OPEN ISSUES: $count") | Out-Null

    foreach ($issue in $notCheckedIssues) {
        $id = $issue.number
        $title = $issue.title
        $ret.lines.Add("-----------------------") | Out-Null
        $ret.lines.Add("($id) :: $title") | Out-Null
    }
}

$json = ConvertTo-Json -InputObject $ret
Write-Host $json
