function Start-ProcessContent
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$page_body    
    )
    #lists to keep track of the items found, all will be added to with a function called Add-ToArray
    $Global:element_list = [System.Collections.ArrayList]::new()
    $Global:location_list = [System.Collections.ArrayList]::new()
    $Global:id_list = [System.Collections.ArrayList]::new()
    $Global:text_list = [System.Collections.ArrayList]::new()
    $Global:issue_list = [System.Collections.ArrayList]::new()
    $Global:issue_severity_list = [System.Collections.ArrayList]::new()

    #Functions to process each of the types of items that could hav eissues
    Start-ProcessLinks
    Start-ProcessImages
    Start-ProcessIframes
    Start-ProcessHeaders
    Start-ProcessTables
    Start-ProcessSemantics
    Start-ProcessVideoTags
    Start-ProcessBrightcoveVideoHTML
    Start-ProcessFlash
    Start-ProcessColor

    #Get the data from the arrays
    $data = Format-TransposeData Element, Location, VideoID, Text, Accessibility, IssueSeverity `
                                    $element_list, 
                                    $location_list, 
                                    $id_list, 
                                    $text_list, 
                                    $issue_list, 
                                    $issue_severity_list
    #Make sure data is not empty before adding it to the excel document.
    if(-not ($NULL -eq $data))
    {
        $data | Export-Excel $Global:ExcelReport -AutoFilter -AutoSize -Append
    }
}

function Start-ProcessLinks
{
    #Get list of links
    $link_list = $page_body | 
                Select-String -pattern "<a.*?>.*?</a>" -AllMatches | 
                ForEach-Object {$_.Matches.Value}
    $id = ""
    #Loop through links to see if that have an HREF tag or not
    foreach ($link in $link_list)
    {
        #default value for link elements
        $element = "Link"
        $issue_found = $false
        #Onclicks are almost always inaccessible
        if($link -match "onlick")
        {
            $element = "JavaScript Link"
            $issue = "JavaScript links are not accessible"
            $issue_found = $true
        }
        #Make sure href is not empty as that will cause problems with keyboard navigation.
        elseif((-not ($link -match 'href')) -or ($link -match 'href="\s*?"'))
        {
            $issue = "Empty link tag"
            $issue_found = $true
        }
        #Add the item to the array if issue found
        if($issue_found)
        {
            Add-ToArray $element `
                        $id `
                        $link `
                        $issue
        }
    }

    #Check the link text to see if it is any commonly used non-descriptive link text
    #Get the text
    $link_text = $link_list | 
                    Select-String -pattern '<a.*?>(.*?)</a>' -AllMatches | 
                    ForEach-Object {$_.Matches.Groups[1].Value}
    #loop through all of the text
    foreach ($text in $link_text)
    {
        #Set to true and if it reaches default option in switch then set it to false
        $issue_found = $true
        #basic variables
        $element = "Link"
        $issue = "Adjust Link Text"
        $id = ""

        #Use a switch to find if any issues where found
        switch -regex ($text) 
        {
            '<img' 
            {  
                #Images will be caught by the Start-ProcessImage helper function
                $issue_found = $false
                break
            }
            $NULL
            {
                #Links should always have text and not be invisible, this can cause keyboard navigation issues
                $text = "Invisible link with no text"
                break
            }
            "^ ?[A-Za-z\.]+ ?$"
            {
                #Matches with the text if it is a single word, which would almost always be considered non-descriptive
                break
            }
            "Click"
            {
                #Link text should not have click in them, usually followed by a here
                break
            }
            "http"
            {
                #Link text should not be the link itself
                break
            }
            "www\."
            {
                #Link text should not be the link itself
                break
            }
            "Link"
            {
                #Link text should not include the word like in it
                if($text -match "Links to an external site")
                {
                    #These link texts where OK'd and do not need to be changed I guess
                    $issue_found = $false
                }
                break
            }
            Default 
            {
                #If it reaches default condition then there was no issue found
                $issue_found = $false
                break
            }
        }

        #If an issue was found, add to the array
        if($issue_found)
        {
            Add-ToArray $element `
                        $id `
                        $text `
                        $issue
        }
    }
}

function Start-ProcessImages
{
    #Get list of images
    $image_list = $page_body | 
                    Select-String -pattern '<img.*?>' -AllMatches | 
                    ForEach-Object {$_.Matches.Value}

    #loop through all of the iamges to check alt text
    foreach ($img in $image_list)
    {
        $element = "Image"
        $id = ""
        #check if it has alt text at all
        if(-not ($img -match 'alt'))
        {
            $issue = "No Alt Attribute"
            #Putting the whole image tag so it can be identified
            Add-ToArray $element `
                        $id `
                        $img `
                        $issue
        }
        else
        { #Check if the alt text is bad
            #Assume issue will be found
            $issue_found = $true

            #get the alt text, it will be used to id the image once it is in the excel doc
            $alt = $img | 
                    Select-String -pattern 'alt="(.*?)"' -AllMatches | 
                    ForEach-Object {$_.Matches.Groups[1].Value}
            $issue = "Alt Text May Need Adjustment"

            #Switch to see if it any common issue
            switch -regex ($alt) 
            {
                "banner" 
                {  
                    #should not have banner in the alt text in vast majority of cases
                    break
                }
                "Placholder"
                {
                    #should not just be a placeholder value
                    break
                }
                "\.jpg"
                {
                    #should not just be the image file name / path
                    break
                }
                "\.png"
                {
                    #should not just be the image file name / path
                    break
                }
                "http"
                {
                    #should not be a link
                    break
                }
                Default 
                {
                    #if it reaches here then no issue found
                    $issue_found = $false
                    break
                }
            }

            #If issue is still true then an issue was found
            if ($issue_found) 
            {
                Add-ToArray $element `
                            $id `
                            $alt `
                            $issue
            }
        }
    }
}

function Start-ProcessIframes
{
    #Get list of iframes
    $iframe_list = $page_body | 
                    Select-String -pattern "<iframe.*?>.*?</iframe>" -AllMatches | 
                    ForEach-Object {$_.Matches.Value}
    #loop through the iframes list
    foreach($iframe in $iframe_list)
    {
        #pretty much the only inherent accessibility issue is if it is missing a title
        if(-not ($iframe -match 'title'))
        {
            #default values
            $issue = "Needs a title"
            $element = "Iframe"
            $id = ""

            #need to find simple defining aspect of iframe, first get the iframe source
            $url = $iframe | 
                    Select-String -pattern 'src="(.*?)"' | ForEach-Object {$_.Matches.Groups[1].value}
            #Parse the URL to see what type of iframe it is
            #Switch sets the variables and flags that will then be added to the array after the switch is complete, to reduce repetetive code.
            switch ($url)
            {
                "youtube"
                {
                    #Checks to make sure we correctly get the video's id
                    if ($url.contains('?')) {
                        $id = $url.split('/')[4].split('?')[0]
                    }
                    else {
                        $id = $url.split('/')[-1]
                    }
                    $element = "Youtube Video"
                    break
                }
                "brightcove"
                {
                    #Get birghtcove id
                    $id = ($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].value}).split('=')[-1].split("&")[0]

                    #Assign element
                    $element = "Brightcove Video"
                    #Brightcove may need an addition to the url
                    if (-not $url.contains("https:")) {
                        $url = "https:$url"
                    }
                    break
                }
                "H5P"
                {
                    $element = "H5P"
                    break
                }
                "byu.mediasite"
                {
                    #Get unique ID
                    $id = ($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-1]
                    #Check if it is empty, as that means the ID was wrong and try a different method to find it
                    if ("" -eq $ID) {
                        $id = ($iframe | 
                                Select-String -pattern 'src="(.*?)"' | 
                                ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-2]
                    }
                    $element = "BYU Mediasite Video"
                    break
                }
                "panopto"
                {
                    #get panopto id
                    $id = ($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('=').split('&')[1]
                    $element = "Panopto Video"
                    break
                }
                "alexanderstreet"
                {
                    #get ID
                    $id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}) -split "token/")[-1]
                    $element = "AlexanderStreet Video"
                    break
                }
                "kanopy"
                {
                    $id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}) -split "embed/")[-1]
                    $element = "Kanopy Video"
                    break
                }
                "ambrosevideo"
                {
                    $id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('?')[-1].split('&')[0])
                    $element = "Ambrose Video"
                    break
                }
                "facebook"
                {
                    $id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value})) | 
                            Select-String -pattern "\d{17}" -Allmatches | 
                            ForEach-Object {$_.Matches.Value}
                    $element = "Facebook Video"
                    break
                }
                "dailymotion"
                {
                    $id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-1])
                    $element = "DailyMotion Video"
                    break
                }
                "vimeo"
                {
                    $id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-1]).split('?')[0]
                    $element = "Vimeo Video"
                }
                default
                {
                    #This means it is just a plain iframe / one I have not ran into before so it will be unlabeled.
                    $element = "Iframe"
                    break
                }
            }
            Add-ToArray $element $id "" $issue
        }

        #Now we need to check if the video types have a transcipt or not
        #var to count number of video
        $i = 1
        foreach ($iframe in $iframe_list)
        {
            #See if it is any of the video types that would need a transcript
            if($iframe -match "brightcove|byu\.mediasite|panopto|vimeo|dailymotion|facebook|ambrosevideo|kanopy|alexanderstreet")
            {
                #Check if it has a transcript or not
                if((Get-TranscriptAvailable $iframe) -eq "No")
                {
                    Add-ToArray "Transcript" "" "Video number $i on page" "No transcript found"
                }
            }
            $i++
        }
    }
}

function Start-ProcessBrightcoveVideoHTML 
{
    #Retrieve list of brightcove videos
    $brightcove_list = $page_body | 
                        Select-String -pattern '<div id="[^\d]*(\d{13})"' -Allmatches | 
                        ForEach-Object {$_.Matches.Value}
    #Get list of ID's from the brightcove list
    $id_list = $brightcove_list | 
                Select-String -pattern '\d{13}' -AllMatches | 
                ForEach-Object {$_.matches.Value}
    #Loop through all of the found ID's
    foreach ($id in $id_list) 
    {
        #manually need to check for transcript as it is pretty different / more spread out then other video types
        #Split page body into an array for each line
        $transcriptCheck = $page_body.split("`n")
        $i = 0
        #Move through the page until we find the element with the correct ID
        while ($transcriptCheck[$i] -notmatch "$id") {$i++}
        #Assume there is no transcript
        $transcript = $FALSE
        #Search the next 10 lines to see if there is a transcript
        for ($j = $i; $j -lt ($i + 10); $j++) 
        {
            #Make sure the we haven't reached the end of the file
            if ($NULL -eq $transcriptCheck[$j]) 
            {
                #End of file
                break
            }
            #If we find the word transcript assume it is an actual transcript
            elseif ($transcriptCheck[$j] -match "transcript") 
            {
                $transcript = $TRUE
                break
            }
        }
        #If a transcript was not found then add the the array
        if(-not $transcript)
        {
            Add-ToArray "Transcript" `
                        $id `
                        "No transcript found for BrightCove video with id:`n$id" `
                        "No transcript found"
        }
    }
}


function Start-ProcessHeaders {
    #Get list of headers on the page, only if the tag is on one line, which is really should be
    $headerList = $page_body | 
                    Select-String -pattern '<h\d.*?>.*?</h\d>' -Allmatches | 
                    ForEach-Object {$_.Matches.Value}
    #Assume no issue
    $accessibility = ""
    #Loop through all of the headers
    foreach ($header in $headerList) {
        #Get the level of the header
        $headerLevel = $header | 
                        Select-String -Pattern "<h(\d)" -Allmatches | 
                        ForEach-Object {$_.matches.Groups[1].Value}
        #Switch to parse through possible issues
        $element = "Header Level $headerLevel"
        $id = ""
        $text = $header
        $Accessibility = "ASDF"
        switch -regex ($header) 
        {
            'class=".*?screenreader-only.*?"' 
            {
                #Only real issue I've found is that sometimes they are set to be invisible and have duplicates
                $Accessibility = "Check if header is meant to be invisible and is not a duplicate"
                break
            }
        }
        #Add element to array if issue was found
        if("ASDF" -ne $Accessibility)
        {
            Add-ToArray $element `
                        "" `
                        $text `
                        $Accessibility
        }
        
    }
}

function Start-ProcessTables 
{
    #See if the page contains any tables
    if ($page_body.contains("<table")) 
    {
        #If it does begin to parse through them
        $tableNumber = 0
        #Split page into an array of lines
        $check = $page_body.split("`n")
        #Need to check the entire page for one or more tables
        for ($i = 0; $i -lt $check.length; $i++) 
        {
            #List of issues that may be found
            $issueList = [System.Collections.ArrayList]::new()
            #If we found the line that has the table then we need to start parsing the table
            if ($check[$i].contains("<table")) 
            {
                #Helper variables
                $rowNumber = 0
                $columnNumber = 0
                $tableNumber++
                $hasHeaders = $FALSE
                #Starts going through the whole table line by line, the try is just in case the file is missing a closing </table> tag
                try 
                {
                    #Loop through the file until we find the end of the table
                    while (-not ($check[$i].contains("</table>"))) 
                    {
                        #parse through possible issues for each line of the table
                        switch -regex ($check[$i])
                        {
                            "<h\d"
                            {
                                #Table should not have h tags in it
                                $issueList += "Heading tags should not be inside of tables"
                                #DON'T BREAK HERE, as this can be a duplcate issue on top of other things
                            }
                            "colspan"
                            {
                                #If it is a colspan then we need to check if it is the only cell in it's row
                                if ($check[$i - 1] -match "<tr" -and $check[$i + 1] -match "</tr") 
                                {
                                    #If it is then suggest that it become a title for the table instead of a streched cell
                                    $issueList += "Stretched cell(s) should be a <caption> title for the table"
                                }
                                break
                            }
                            "<th[^e]"
                            {
                                #Match with a th tag, but make sure it doesn't make a <theader> tag
                                #Set header flag to true
                                $hasHeaders = $TRUE
                                #See if it as a scope tag, if not add to issue list
                                if ($check[$i] -notmatch "scope") 
                                {
                                    $issueList += "Table headers should have a scope attribute"
                                }
                                #Add to number of columns
                                $columnNumber++
                                break
                            }
                            "<td"
                            {
                                #Normal cells shot NOT have a scope tag, if they do that is an issue
                                if ($check[$i] -match "scope") 
                                {
                                    $issueList += "Non-header table cells should not have scope attributes"
                                }
                                #Add to the number of columns
                                $columnNumber++
                                break
                            }
                            "<tr"
                            {
                                #If it is a row then we need to add to the number of rows
                                $rowNumber++
                                break
                            }
                            "</tr"
                            {
                                #See if the table is going to continue or end
                                if($check[$i + 1] -match "<tr")
                                {
                                    #If it is then reset column number
                                    #This isn' the best way as sometimes the last row is just a single stretched column
                                    #Not sure how else to track the column numbers though
                                    $columnNumber = 0
                                }
                            }
                        }
                        $i++
                    }
                }
                catch 
                {
                    #If an error was thrown then we know the table is missing a closing tag
                    $issueList += "Table does not have an ending </table> tag"
                }
                if (-not $hasHeaders) 
                {
                    #If no headers were found and it is less then 3 row and 3 cols then don't flag it
                    if (($rowNumber -le 3) -and ($columnNumber -lt 3)) 
                    {

                    }
                    else 
                    {
                        $issueList += "Table has no headers"
                    }
                }
                #Create a single string with each unique issue found with a new line between each item
                $issueString = ""
                $issueList | 
                    Select-Object -Unique | 
                    ForEach-Object {$issueString += "$_`n"}
                #Check if any issues were found
                if ($issueList.count -eq 0) {}
                else {
                    #If issues found add it to the arrays
                    Add-ToArray "Table" `
                                "" `
                                ("Table number {0}:`n{1}" -f $tableNumber, $issueString) `
                                "Revise table"
                }
            }
        }
    }
}

function Start-ProcessSemantics 
{
    #Get list of i tags
    $i_tag_list = $page_body | 
                    Select-String -pattern "<i.*?>(.*?)</i>" -AllMatches | 
                    ForEach-Object {$_.Matches.Groups[1].Value}
    #Get list of b tags
    $b_tag_list = $page_body | 
                    Select-String -pattern "<b.*?>(.*?)</b>" -AllMatches | 
                    ForEach-Object {$_.Matches.Groups[1].Value}
    #Loop through to see if any where found (may possibly add checks to this which is why I left it in this framework instead of just checking for the count of the above arrays)
    $i = 0
    foreach ($i_tag in $i_tag_list) 
    {
        $i++
    }
    foreach ($b_tag in $b_tag_list) 
    {
        $i++
    }
    #If any where found then mark it the one time
    if ($i -gt 0) 
    {
        Add-ToArray "<i> or <b> tags" `
                    "" `
                    "Page contains <i> or <b> tags" `
                    "<i>/<b> tags should be <em>/<strong> tags"
    }
}

function Start-ProcessVideoTags 
{
    #Get list of video tags
    $videotag_list = $page_body -split "`n" | 
                        Select-String -pattern '<video.*?>.*?</video>' -AllMatches | 
                        ForEach-Object {$_.Matches.Value}
    #Loop through all found tags
    foreach ($video in $videotag_list) 
    {
        #Get the video source
        $src = $video | 
                Select-String -pattern 'src="(.*?)"' -AllMatches | 
                ForEach-Object {$_.Matches.Groups[1].Value}
        #Try to get the video ID
        $videoID = $src.split('=')[1].split("&")[0]
        #See if there is a transcript
        $transcript = Get-TranscriptAvailable $video
        #If no transcript was found then add it to the array
        if($transcript -eq "No")
        {
            Add-ToArray "Inline Media Video" `
                        $videoID `
                        "Inline Media Video`n" `
                        "No transcript found"
        }
    }
}

function Start-ProcessFlash 
{
    #Check if it has the common flash messages anywhere in the page
    if ($page_body -match "Content on this page requires a newer version of Adobe Flash Player") 
    {
        $flash_elements = $page_body.split("`n") -match "Content on this page requires a newer version of Adobe Flash Player" |
                            Measure-Object
        #If it does, flash is always inaccessible, so flag it
        Add-ToArray "Flash Element" `
                    "" `
                    ("{0} embedded flash element(s) on this page" -f $flash_elements.Count) `
                    "Flash is inaccessible"
    }
}

function Start-ProcessColor 
{
    #Get list of all of the colors.
    #Need to check if there was a background color and attach them together
    #There is still work that can be done as there are times when people nest a whole bunch of colors  which causes a lot of confusion as to what color is actually be used. This does not check very in depth and assumes that people are using HTML styles correctly.
    $colorList = $page_body -split "`n" | 
                    Select-String -Pattern "((?:background-)?color:[^;`"]*)" -Allmatches | 
                    ForEach-Object `
                    {
                        #Create an object to attatch a color with its background
                        $c = [PSCustomObject]@{
                                Color = ""
                                BackgroundColor = ""
                        }
                        #Try to see which one is the background color
                        if($_.Matches.Groups[1].Value -match "background")
                        {
                            #Format the color to get rid of extra text
                            $c.BackgroundColor = $_.Matches.Groups[1].Value -replace ".*?:", "" -replace " ", ""
                            $c.Color = $_.Matches.Groups[2].Value -replace ".*?:", "" -replace " ", ""
                        }elseif($_.Matches.Groups[2].Value -match "background")
                        {
                            #Format the color to get rid of extra text
                            $c.BackgroundColor = $_.Matches.Groups[2].Value -replace ".*?:", "" -replace " ", ""
                            $c.Color = $_.Matches.Groups[1].Value -replace ".*?:", "" -replace " ", ""
                        }else
                        {
                            #If neither of the colors are a background color(there may only be one color found as well) then just assign found color to the main color
                            $c.Color = $_.Matches.Groups[1].Value -replace ".*?:", "" -replace " ", ""
                        }
                        #If there is no background color then assume it is white
                        if($null -eq $c.BackgroundColor -or "" -eq $c.BackgroundColor)
                        {
                            $c.BackgroundColor = "#FFFFFF"
                        }
                        #Make sure main color is not empt (assume it is black text)
                        if($null -eq $c.Color -or "" -eq $c.Color)
                        {
                            $c.Color = "#000000"
                        }
                        #Return the custom object
                        $c
                    }
    #Loop through all of the colors found
    Foreach ($color in $colorList) 
    {
        #See if the color is in hexadecimal form
        if ($color.Color -notmatch "#") 
        {
            #If it is not then convert the color to hexadecimal based on RGB values
            $convert = @([System.Drawing.Color]::($color.Color).R, [System.Drawing.Color]::($color.Color).G, [System.Drawing.Color]::($color.Color).B)
            #Short code to convert the three RBG values from the above array into a hexadecimal format
            $color.Color = '#' + -join (0..2| % {"{0:X2}" -f + ($convert[$_])})
        }

        #Do the same for the background color
        if ($color.BackgroundColor -notmatch "#") 
        {
            $convert = @([System.Drawing.Color]::($color.BackgroundColor).R, [System.Drawing.Color]::($color.BackgroundColor).G, [System.Drawing.Color]::($color.BackgroundColor).B)
            $color.BackgroundColor = '#' + -join (0..2| % {"{0:X2}" -f + ($convert[$_])})
        }

        #Get rid of the "#" signs so they will work correctly with the API
        $color.Color = $color.Color.replace("#", "")
        $color.BackgroundColor = $color.BackgroundColor.replace("#", "")

        #Send the color and background color to the API and get the result
        $api_url = "https://webaim.org/resources/contrastchecker/?fcolor={0}&bcolor={1}&api" -f $color.Color, $color.BackgroundColor
        $results = (Invoke-WebRequest -Uri $api_url).Content | 
                    ConvertFrom-Json

        #See if the color passed, if it did not add it to the array (according to the more loose AA standard)
        if ($results.AA -ne 'pass') 
        {
            #Format results
            $formatted_results = $results -replace "@{", "" -replace "}","" -replace " ", "" -split ";" -join "`n"
            #Add it to an array, need to format the color with the results
            Add-ToArray "Color Contrast" `
                        "" `
                        ("Color: {0}`nBackgroundColor: {1}`n{2}" -f $color.Color, $color.BackgroundColor, $formatted_results) `
                        "Does not meet AA color contrast"
        }
    }
}

function Add-ToArray 
{
    param(
        [string]$element,
        [string]$VideoID,
        [string]$Text,
        [string]$Accessibility,
        [int]$issueSeverity = 1
    )
    $Global:element_list += $element
    #Location is the same for every element, we won't to make it a link to that specific page / html file
    $Global:location_list += "$($item.url -split `"api/v\d/`" -join `"`")"
    $Global:id_list += $VideoID
    $Global:text_list += $Text
    $Global:issue_list += $Accessibility
    $Global:issue_severity_list += $issueSeverity
}