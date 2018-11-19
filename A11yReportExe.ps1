if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else {
    $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

."$ScriptPath\A11yReport.ps1"

$course_id = Read-Host "Enter Canvas Course ID or path to course HTML files"

Invoke-A11yReport -course_id $course_id