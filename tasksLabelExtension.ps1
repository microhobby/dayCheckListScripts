[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', ""
)]
param()

if ($null -eq ("Issue" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Collections;
using System.Collections.Generic;

public class Issue {
    public int id { get; set; }
}

public class Issues : ArrayList {
    public Issues() : base() {}
}
"@
}

$CHECKED = "$PSScriptRoot/../versions/taskslabelissues"

# ret object
$ret = [PSCustomObject]@{
    lines = [System.Collections.ArrayList]::new()
    linesformated = [System.Collections.ArrayList]::new()
    code = 0
    slackbot = $false
}

$get = Invoke-WebRequest `
    -Uri "https://api.github.com/repos/microhobby/vscode-tasks-label/issues?state=open"

$obj = ConvertFrom-Json $get
# how many issues we have
$count = $obj.Count

# check if we have something from ../versions
# check if the file exists
if (-not (Test-Path $CHECKED)) {
    # creat it
    # obj to json
    $json = ConvertTo-Json -InputObject (New-Object Issues)

    # save it
    $json | Out-File $CHECKED
} else {
    $_tmpIssues = $issues
    $issues = New-Object Issues

    foreach ($issue in $_tmpIssues) {
        $issues.Add([Issue]@{
            id = $issue.id
        }) | Out-Null
    }
}

# read it
$json = Get-Content $CHECKED | ConvertFrom-Json
$notCheckedIssues = [System.Collections.ArrayList]::new()
$issues = $json

if ($null -eq $issues) {
    $issues = New-Object Issues
}

# check if we have new issues
foreach ($ghIssue in $obj) {
    # check if the id exists in $issues
    $id = $ghIssue.id

    $idExists = $issues | Where-Object { $_.id -eq $id }

    if (-not $idExists) {
        $notCheckedIssues.Add($ghIssue) | Out-Null
        $issues.Add([Issue]@{
            id = $id
        }) | Out-Null
    }
}

# ok, we need to save now the checked issues
# obj to json
$json = ConvertTo-Json -InputObject $issues

# save it
$json | Out-File $CHECKED

if ($notCheckedIssues.Count -gt 0) {
    $ret.code = 1
    $ret.lines.Add("microhobby/") | Out-Null
    $ret.lines.Add("vscode-tasks-label") | Out-Null
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
