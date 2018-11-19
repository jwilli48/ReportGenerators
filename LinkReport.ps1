function LinkReport
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $course_id
    )

    #Import needed functions
    ."$PSScriptRoot/PoshCanvas.ps1"
    ."$PSScriptRoot/SetUp.ps1"
    ."$PSScriptRoot/Util.ps1"
    ."$PSScriptRoot/SearchCourse.ps1"
    ."$PSScriptRoot/ProcessLink.ps1"
    ."$PSScriptRoot/LinkExcel.ps1"

    #To time how long the program will run, will be output with desktop notification at end of script
    $StopWatch = [Diagnostics.StopWatch]::new()
    $StopWatch.start()

    #Make sure modules are available
    Get-Modules

    #Make sure it is a valid directory
    if (-not (Test-Path $course_id))
    {
        Write-Host "$course_id must be a valid directory for this link report generator"
    }
    else
    {
        #Need to change protocol to make sure we don't have any (or not as many) false negatives
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        #Search the directory
        Search-CourseDirectory $course_id "LinkCheck"
        #Format-LinkExcel
        Write-Host "Report Generated" -ForegroundColor Green
        $StopWatch.stop()
        #Send-EndNotification
    }
}