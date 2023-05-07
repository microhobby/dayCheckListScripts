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

# Set variables for your app registration
$clientToken = $Env:MSG_CLIENT_TOKEN

# Set the Graph API endpoint and access token
$graphEndpoint = "https://graph.microsoft.com/v1.0"

# Set the headers for the Graph API call
$headers = @{
    "Authorization" = "Bearer $($clientToken)"
    "Content-Type" = "application/json"
}

# get lists
$uri = "$graphEndpoint/me/todo/lists"
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

# get my TODO list
$test = $response.value[1]

# get tasks
$uri = "$graphEndpoint/me/todo/lists/$($test.id)/tasks"
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

# get tasks
$response.value | ForEach-Object {
    if ($_.status -ne "completed") {
        $ret.lines.Add($_.title) | Out-Null
    }
}

if ($ret.lines.Count -gt 0) {
    $ret.code = 3
    $ret.lines.Insert(0, "-----------------------") | Out-Null
    $ret.lines.Insert(0, "TODO LIST") | Out-Null
}

# for debug purposes
#$response.value

$json = ConvertTo-Json -InputObject $ret
Write-Host $json
