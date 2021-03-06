if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else {
    $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

."$ScriptPath/LinkReport.ps1"

$course_id = Read-Host "Enter Canvas Course ID or path to course HTML files"

LinkReport -course_id $course_id