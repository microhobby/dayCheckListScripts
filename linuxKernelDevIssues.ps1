[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', ""
)]
param()

# ret object
$ret = [PSCustomObject]@{
    lines = [System.Collections.ArrayList]::new()
    linesformated = [System.Collections.ArrayList]::new()
    code = 0
    slackbot = $false
}

$get = Invoke-WebRequest `
    -Uri "https://api.github.com/repos/microhobby/linuxkerneldev/issues?state=open"

$obj = ConvertFrom-Json $get
# how many issues we have
$count = $obj.Count

if ($count -gt 0) {
    $ret.code = 1
    $ret.lines.Add("microhobby/") | Out-Null
    $ret.lines.Add("linuxkerneldev") | Out-Null
    $ret.lines.Add("-----------------------") | Out-Null
    $ret.lines.Add("OPEN ISSUES: $count") | Out-Null

    foreach ($issue in $obj) {
        $id = $issue.number
        $title = $issue.title
        $ret.lines.Add("-----------------------") | Out-Null
        $ret.lines.Add("($id) :: $title") | Out-Null
    }
}

$json = ConvertTo-Json -InputObject $ret
Write-Host $json
