param (
    [string]$pullRequestTitle,
    [string[]]$jiraProjects
)

$ErrorActionPreference = "Stop"

foreach ($project in $jiraProjects) {
    $pattern = "^$project-[0-9]+"
    if ($pullRequestTitle -match $pattern) {
        Write-Host "Valid Jira ticket found at beginning of string: $($matches[0])"
        return $matches[0]
    }
}

return ""