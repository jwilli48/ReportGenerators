if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else {
    $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

$TimerABC = [Diagnostics.StopWatch]::new()
$TimerABC.Start()

."$ScriptPath/LinkReport.ps1"
."$ScriptPath/MediaReport.ps1"
."$ScriptPath/A11yReport.ps1"

$course_id = Read-Host "Enter Canvas Course ID or path to course HTML files"
Write-Host "Which canvas are you using:"
$domain = Read-Host "[1] Main, [2] Test, [3] MasterCourses, [4] Directory"

Write-Host "------`nBeginning A11y Report`n------" -ForegroundColor White
Invoke-A11yReport -course_id $course_id -domain $domain
Write-Host "------`nBeginning Media Report`n------" -ForegroundColor White
MediaReport -course_id $course_id -domain $domain

#Only run link report if it is a directory
if (4 -eq $domain)
{
    Write-Host "------`nBeginning Link Report`n------" -ForegroundColor White
    LinkReport -course_id $course_id
}

."$ScriptPath/CombineReports.ps1"

CombineReports -course_id $course_id -domain $domain -time ($TimerABC.Stop().Elapsed)