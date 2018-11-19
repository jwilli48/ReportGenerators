if($NULL -eq $domain -or "" -eq $domain){
    Write-Host "Which canvas are you using:"
    $domain = Read-Host "[1] Main, [2] Test, [3] MasterCourses"
}
#If the CanvasApiCreds.json file exists this will find which domain it is for, copy it to the a different name and delete it. This is to ensure you don't accidently use the wrong ApiCreds with the wrong domain.
if (Test-Path "$HOME\Documents\CanvasApiCreds.json") 
{
    $CanvasType = (Get-Content "$HOME\Documents\CanvasApiCreds.json" | ConvertFrom-Json).BaseUri
    switch -regex ($CanvasType) 
    {
        "https://byu.instructure.com" 
        {
            Copy-Item -Path "$HOME\Documents\CanvasApiCreds.json" -Destination "$HOME\Documents\BYU_CanvasApiCreds.json" -Force
            $Global:ReportType = "Canvas"
            break
        }
        "https://byuistest.instructure.com" 
        {
            Copy-Item -Path "$HOME\Documents\CanvasApiCreds.json" -Destination "$HOME\Documents\TEST_CanvasApiCreds.json" -Force
            $Global:ReportType = "CanvasTest"
            break
        }
        "https://byuismastercourses.instructure.com" 
        {
            Copy-Item -Path "$HOME\Documents\CanvasApiCreds.json" -Destination "$HOME\Documents\MASTER_CanvasApiCreds.json" -Force
            $Global:ReportType = "CanvasMasterCourses"
            break
        }
        default 
        {
            Write-Host "CanvasApiCreds.json for unknown domain found, saving to `"$HOME\Documents\UNKNOWN_CanvasApiCreds.json`"" -ForegroundColor Red
            Copy-Item -Path "$HOME\Documents\CanvasApiCreds.json" -Destination "$HOME\Documents\UNKNOWN_CanvasApiCreds.json" -Force
        }
    }
    Remove-Item -Path "$HOME\Documents\CanvasApiCreds.json"
}

switch ($domain) 
{
    "1" {
        if (Test-Path "$HOME\Documents\BYU_CanvasApiCreds.json") 
        {
            Copy-Item -Path "$HOME\Documents\BYU_CanvasApiCreds.json" -Destination "$HOME\Documents\CanvasApiCreds.json" -Force
        }
        else {
            Write-Host "You will need to create a Canvas API for this domain."
        }
        break
    }"2" {
        if (Test-Path "$HOME\Documents\TEST_CanvasApiCreds.json") 
        {
            Copy-Item -Path "$HOME\Documents\TEST_CanvasApiCreds.json" -Destination "$HOME\Documents\CanvasApiCreds.json" -Force
        }
        else {
            Write-Host "You will need to create a Canvas API for this domain."
        }
        break
    }"3" {
        if (Test-Path "$HOME\Documents\MASTER_CanvasApiCreds.json") 
        {
            Copy-Item -Path "$HOME\Documents\MASTER_CanvasApiCreds.json" -Destination "$HOME\Documents\CanvasApiCreds.json" -Force
        }
        else 
        {
            Write-Host "You will need to create a Canvas API for this domain."
        }
        break
    }
}
