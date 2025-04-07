param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$pullRequestBody
)

$ErrorActionPreference = "Stop"

# Constants
$COMMENT_START = "<!--"
$COMMENT_END = "-->"

# This regex matches task list items in the format "- [ ] item" or "- [x] item"
# It captures the checkbox state (complete/incomplete) and the item text
# The regex also ensures that the item does not start with "~" to exclude stroked through items
$TASK_LIST_ITEM = '(?:^|\n)\s*-\s+\[([ xX])\]\s+(~?)(.*)'

# Variables
$containsChecklist = $false
$openComment = $false
$completedCount = 0
$incompleteCount = 0
$ignoredCount = 0
$allItems = @()

# Ensure $pullRequestBody is split into lines for processing
$bodyLines = $pullRequestBody -split "`n"

foreach ($line in $bodyLines) {
    if ($line -like "*$COMMENT_START*") {
        $openComment = $true
        continue
    }

    if ($line -like "*$COMMENT_END*") {
        $openComment = $false
        continue
    }

    if ($openComment -eq $false) {
        $regexMatches = [regex]::Matches($line, $TASK_LIST_ITEM)

        foreach ($match in $regexMatches) {
            $isComplete = $match.Groups[1].Value -eq "x" -or $match.Groups[1].Value -eq "X"
            $isStrokedOut = $match.Groups[2].Value -eq "~"
            $itemText = $match.Groups[3].Value.Trim()

            # Include the ~ character if the item is stroked out
            if ($isStrokedOut) {
                $itemText = "~" + $itemText
            }

            $containsChecklist = $true
            $allItems += "- [$($match.Groups[1].Value)] $itemText"

            if ($isStrokedOut) {
                $ignoredCount++
            } elseif ($isComplete) {
                $completedCount++
            } else {
                $incompleteCount++
            }
        }
    }
}

$jsonSummary = @{
    containsChecklist = $containsChecklist
    completed   = $completedCount
    incompleted = $incompleteCount
    ignored     = $ignoredCount
    items       = ($allItems -join "`n")
} | ConvertTo-Json -Depth 10 -Compress

return $jsonSummary
