function MediaReport{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $course_id,
        $domain = $NULL
    )        
    #Make sure files are not blocked
    Get-ChildItem -Recurse -Path "$PSScriptRoot" | Unblock-File

    #Import modules with needed functions to generate report
    Import-Module "$home\Desktop\AccessibilityTools\PowerShell\Modules\SeleniumTest\PowerShellSelenium.psm1"
    ."$PSScriptRoot/SetUp.ps1"
    ."$PSScriptRoot/PoshCanvas.ps1"
    ."$PSScriptRoot/MediaExcel.ps1"
    ."$PSScriptRoot/SearchCourse.ps1"
    ."$PSScriptRoot/Util.ps1"
    ."$PSScriptRoot/MediaUtil.ps1"
    ."$PSScriptRoot/ProcessMedia.ps1"

    #Make sure all credentials and dependencies are downloaded
    Set-BrightcoveCredentials
    Get-GoogleAPI
    Get-Modules

    #Get the ID/Directory
    $is_directory = $false

    #See if it is a directory, else figure out what Canvas domain is being worked in
    if ($course_id -match "[A-Z]:\\") 
    {
        $is_directory = $true
    }
    else 
    {
        ."$PSScriptRoot/SetCanvasDomain.ps1"
    }

    #To time how long the program will run
    $StopWatch = [Diagnostics.StopWatch]::new()
    $StopWatch.start()

    #We need to browser for this report to get the length of time the video is
    Write-Host -ForegroundColor Magenta "Starting automated Chrome Browser..."

    #Create new chrome driver, set URL and log into Brightcove
    $Chrome = New-SeChrome -Headless -MuteAudio
    Set-SeUrl -DriverList $Chrome -Url "https://signin.brightcove.com/login?redirect=https%3A%2F%2Fstudio.brightcove.com%2Fproducts%2Fvideocloud%2Fmedia"
    #Send username
    Invoke-SeWaitUntil -DriverList $Chrome -Condition ElementIsVisible -By CssSelector -Locator input[name*="email"] |
        Send-SeKeys -Text $BrightcoveCredentials.UserName |
        Out-Null
    #Send password
    Invoke-SeWaitUntil -DriverList $Chrome -Condition ElementIsVisible -By CssSelector -Locator input[id*="password"] |
        Send-SeKeys -Text $BrightcoveCredentials.GetNetworkCredential().password |
        Out-Null
    #Click submit
    (Invoke-SeWaitUntil -DriverList $Chrome -Condition ElementIsVisible -By CssSelector -Locator button[id*="signin"]).submit() |
        Out-Null

    #If directory run directory search, else canvas search
    if($is_directory) 
    {
        Search-CourseDirectory $course_id "MediaReport"
    }else {
        Search-CanvasCourse $course_id "MediaReport"
    }

    #Close the Chrome Browser as we are now done gathering data
    Exit-SeDriver -DriverList $Chrome

    #Attempt to format Excel document
    try
    {
        #Check if it is empty, $ExcelReport variable is a global var created elsewhere in the script
        Import-Excel $ExcelReport |
            Out-Null
        #Let user know whats going on
        Write-Host 'Formatting Excel Document...' -ForegroundColor Green

        #Basic Formatting for first sheet
        Format-MediaExcelOne
        #Set the pivot tables into excel
        Set-MediaPivotTables
        #Formatting for the pivot tables
        Format-MediaExcelTwo
        #Print that report is finished
        Write-Host "Report Generated" -ForegroundColor Green
    }
    catch
    {
        #Most likely to get here if excel document is empty
        Write-Host "ERROR: Excel Sheet may be empty" -ForegroundColor Red
    }

    #Stop the timer and send desktop notification letting them know it is finished
    $StopWatch.stop()
    #Send-EndNotification
}