#Brightcove
function Set-BrightcoveCredentials 
{
    <#
    .DESCRIPTION
    If they don't have credentials, will ask them for some and save a file with username and a secure string password, then it will set the username and password to the variables saved in text files.
    #>
    #Test if the password directory exists
    if (-not (Test-Path "$PSScriptRoot\Passwords")) {
        New-Item -Path "$PsScriptRoot\Passwords" -ItemType Directory
    }
    #Test if the passowrd file exists
    if (Test-Path "$PSScriptRoot\Passwords\MyBrightcovePassword.txt") {}
    else {
        #if it does not exists we need to get the credentials from the user
        Write-Host "No Brightcove Credentials found, please enter them now." -ForegroundColor Yellow
        #Get credential information
        $PasswordType = "Brightcove"
        $SetupCred = Get-Credential -Message "Brightcove Credentials needed"
        $secureStringText = $SetupCred.Password | ConvertFrom-SecureString
        #Create secure text file
        Set-Content $("$PSScriptRoot\Passwords\My" + $PasswordType + "Password.txt") $secureStringText
        Set-Content $("$PSScriptRoot\Passwords\My" + $PasswordType + "Username.txt") $SetupCred.UserName
        #Print warning that if this is entered wrong the program will not work and they need to fix it
        Write-Host "WARNING: If Brightcove fails to login this script will also continue to throw errors.`nYou may also need to go to the file $PsScriptRoot\Passwords.ps1 and change the username variable there" -ForegroundColor Yellow
    }
    #Try catch to make sure the files aren't empty and if we can actually read the password SecureString
    try {
        $username = Get-Content "$PSScriptRoot\Passwords\MyBrightcoveUsername.txt"
        $password = Get-Content "$PSScriptRoot\Passwords\MyBrightcovePassword.txt"
        $securePwd = $password | ConvertTo-SecureString
        #Need to make sure this variable is avaible everywhere once made
        $Global:BrightcoveCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePwd
        Write-Host "WARNING: If Brightcove fails to login you may have saved the wrong Username and Password, please go to $PSScriptRoot\Passwords and delete the text files there to reset them" -ForegroundColor Yellow
    }
    catch {
        #Let them know that a fatal error occured
        Write-Host "Your password and username files at $PSScriptRoot\Passwords threw an error, they may be empty, please delete them and run the program again" -ForegroundColor Red
        #Force them to close program
        Read-Host "If you do not want to check brightcove videos, you can probably continue without issue, but if not please close the program now. It will still attempt to log into brightcove (it will throw some errors) but should work for everything else"
    }
}

function Get-GoogleAPI 
{
    #Make sure they have a google API for 
    if (-not (Test-Path "$PSScriptRoot\Passwords\MyGoogleApi.txt")) 
    {
        #If they don't have one made already then get the API from them
        Write-Host "Google API needed to get length of YouTube videos." -ForegroundColor Magenta
        $api = Read-Host "Please enter it now (It will then be saved)"
        Set-Content $PSScriptRoot\Passwords\MyGoogleApi.txt $api
    }
    #This needs to be global so it can be accessed everywhere in the script
    $Global:GoogleApi = Get-Content "$PSScriptRoot\Passwords\MyGoogleApi.txt"
}

function Get-Modules 
{
    <#
    .DESCRIPTION

    Makes sure they have the needed modules installed and will install them if they do not
    #>
    #Check for ImportExcel module (used to create the excel)
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) 
    {
        Write-Host "You need to have the ImportExcel module installed. Intalling now..." -ForegroundColor Yellow
        Install-Module ImportExcel -Scope CurrentUser
    }
    #Check for BurntToast module (used for sending desktop notifications)
    if (-not (Get-Module -ListAvailable -Name BurntToast)) 
    {
        Write-Host "You need to have the BurntToast module installed. Installing now..." -ForegroundColor Yellow
        Install-Module BurntToast -Scope CurrentUser
    }
    #Check if the report directory has been made, this is to store all of the generated reports.
    if (-not (Test-Path "$PSScriptRoot\Reports")) 
    {
        New-Item -Path "$PsScriptRoot\Reports" -ItemType Directory
    }
}