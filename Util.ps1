function Format-TransposeData 
{
    param(
        [String[]]$Names,
        [Object[][]]$Data
    )
    for ($i = 0; ; ++$i) {
        $Props = [ordered]@{}
        for ($j = 0; $j -lt $Data.Length; ++$j) {
            if ($i -lt $Data[$j].Length) {
                $Props.Add($Names[$j], $Data[$j][$i])
            }
        }
        if (!$Props.get_Count()) {
            break
        }
        [PSCustomObject]$Props
    }
}

function Get-TranscriptAvailable {
    param(
        [string]$item
    )
    #Split page into lines
    $check = $page_body.split("`n")
    #Run while loop to get to the line that the iframe / whatever input is on
    $i = 0
    while (-not $check[$i].contains($item)) {$i++}
    #Make sure next line exists
    if ($NULL -ne $check[$i + 1]) {
        #Check if it has a transcript
        if ($check[$i + 1].contains('Transcript')) {
            return "Yes"
        }
    }
    #Check if line before has a transcript
    elseif ($check[$i - 1].contains('Transcript')) {
        return "Yes"
    }
    #Check if Transcript is within two lines of item
    elseif ($NULL -ne $check[$i + 2] -and $check[$i + 2].contains('Transcript')) {
        return "Yes"
    }
    else {
        return "No"
    }
}

function Send-EndNotification {
    <#
  .DESCRIPTION

  Sends a desktop notification with the name of the course, time it took, and a button to open the report.
  #>
    $ButtonContent = @{
        Content   = "Open Report"
        Arguments = $ExcelReport
    }
    $Button = New-BTButton @ButtonContent

    $NotificationContent = @{
        Text   = "Report for $courseName Generated", "Time taken: $($StopWatch.Elapsed.ToString('hh\:mm\:ss'))"
        Button = $Button
    }
    New-BurntToastNotification @NotificationContent
}