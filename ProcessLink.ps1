function Start-ProcessContent
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $page_body
    )
    $Global:location_list = [System.Collections.ArrayList]::new()
    $Global:url_list = [System.Collections.ArrayList]::new()
    $Global:error_list = [System.Collections.ArrayList]::new()
    #Process the page
    Start-ProcessLinks
    Start-ProcessImages
    #Format the data
    $data = Format-TransposeData File, URL, Error $location_list, $url_list, $error_list
    #Make sure data is not empty before adding it to the excel document.
    if (-not ($NULL -eq $data)) {
        $data | Export-Excel $Global:ExcelReport -AutoFilter -AutoSize -Append
    }
}

function Start-ProcessLinks
{
    #Get list of links
    $link_list = $page_body | 
                    Select-String -pattern "<a.*?>.*?</a>" -AllMatches | 
                    ForEach-Object {$_.Matches.Value}
    #Get list of hrefs
    $href_list = $link_list | 
                    Select-String -pattern 'href="(.*?)"' -AllMatches | 
                    ForEach-Object {$_.Matches.Groups[1].Value}
    #Loop through each href
    foreach ($href in $href_list)
    {
        $error_msg = ""
        #Switch to parse possible problems
        switch -regex ($href)
        {
            "^#"
            {
                #Can't be checked by program
                break
            }
            "^mailto:"
            {
                #Can't be checked by program
                break
            }
            "^javascript:"
            {
                #Mark it as javascript links are iffy
                $error_msg = "JavaScript links are often not accessible \ broken."
                break
            }
            "http|^www\.|.*?\.com$|.*?\.org$"
            {
                #It is a website link
                #See if the links are valid
                try 
                {
                    #Just try to ping the URL and send it out to nothing, we just want to see if it throws an error
                    Invoke-WebRequest $href | Out-Null
                }
                catch 
                {
                    #Mark it as a broken link
                    $error_msg = "Broken link, needs to be checked"
                }
                break
            }
            default
            {
                #check if it is a path outside of current directory
                if ($href -match "^\.\.") 
                {
                    #Format the path to the actual file path
                    $formatted_path = ("{0}\{1}" -f $directory.replace("HTML", ""), `
                                        $href.replace("..", "").replace("/", "\")) -replace "\\\\\\", "\"
                    #Remove any extra directions specified.
                    $formatted_path = $formatted_path.Split("#")[0]
                    #Test the path
                    if (-not (Test-Path $formatted_path)) 
                    {
                        $error_msg = "File does not exist"
                    }
                }
                elseif (-not (Test-Path ("{0}\{1}" -f $directory, $href.split("#")[0]))) 
                {
                    $error_msg = "File does not exist"
                }
                break
            }
        }
        #Only add if error_msg is not blank
        if("" -ne $error_msg)
        {
            Add-ToArray $href `
                        $error_msg
        }
    }
}

function Start-ProcessImages
{
    #Get list of images
    $image_list = $page_body | 
                    Select-String -pattern "<img.*?>" -AllMatches | 
                    ForEach-Object {$_.Matches.Value}
    #Get list of file paths to images
    $src_list = $image_list | 
                Select-String -pattern 'src="(.*?)"' -AllMatches | 
                ForEach-Object {$_.Matches.Groups[1].Value}

    #Loop through sources
    foreach ($src in $src_list)
    {
        $error_msg = ""
        #Parse through possible errors
        switch -regex ($src)
        {
            "http|^www\.|.*?\.com|.*?\.org$"
            {
                #We want to check everything but these
                break
            }
            default
            {
                #See what the file path is like to format it correctly
                if($src -match "^\.\.")
                {
                    #Needs special formatting
                    $formatted_path = ("{0}{1}" -f ($directory.split("\").replace("HTML","") -join "\"), `
                                                    ($src.split("/").replace("..", $NULL) -join "\")) `
                                                    -replace "\\\\", "\"
                    
                    #Test the path if it exist
                    if(-not (Test-Path $formatted_path))
                    {
                        $error_msg = "Image does not exist"
                    }
                }
                #Does not need special formatting, just test it
                elseif(-not (Test-Path ("{0}\{1}" -f $directory, $src)))
                {
                    $error_msg = "Image does not exist"
                }
                break
            }
        }
        #If there was an error message then add it to the array
        if("" -ne $error_msg)
        {
            Add-ToArray $src `
                        $error_msg
        }
    }
}
function Add-ToArray {
    param(
        $url,
        $error_msg
    )
    #Location is the same for every element, we won't to make it a link to that specific page / html file
    $Global:location_list += "$($item.url -split `"api/v\d/`" -join `"`")"
    $Global:url_list += $url
    $Global:error_list += $error_msg
}
