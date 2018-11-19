function Invoke-A11yReport
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $course_id,
        $domain = $NULL
    )
    #Make sure files are not blocked
    Get-ChildItem -Recurse -Path "$PSScriptRoot" | Unblock-File

    #Load needed functions
    ."$PSScriptRoot\ProcessA11y.ps1"
    ."$PSScriptRoot\PoshCanvas.ps1"
    ."$PSScriptRoot\Util.ps1"
    ."$PSScriptRoot\A11yExcel.ps1"
    ."$PSScriptRoot\SearchCourse.ps1"
    ."$PSScriptRoot\SetUp.ps1"

    #Get course ID or path to directory
    $is_directory = $false

    #See if it is a directory
    if ($course_id -match "[A-Z]:\\") 
    {
        $is_directory = $true
    }
    else 
    {
        ."$PSScriptRoot/SetCanvasDomain.ps1"
    }

    #To time how long the program will run, will be output with desktop notification at end of script
    $StopWatch = [Diagnostics.StopWatch]::new()
    $StopWatch.start()
    #Make sure correct modules are installed
    Get-Modules

    #Run command based on if it is a directory or not
    if ($is_directory) {
        Search-CourseDirectory $course_id "A11yReport"
    }
    else {
        Search-CanvasCourse $course_id "A11yReport"
    }

    #Format the excel document
    Write-Host "Formatting Excel Doc..." -ForegroundColor Green
    ConvertTo-A11yExcel

    #Print finish message, stop the timer and send notification
    Write-Host "Report Generated" -ForegroundColor Green
    $StopWatch.stop()
    #Send-EndNotification
}