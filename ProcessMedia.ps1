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
    $Global:url_list = [System.Collections.ArrayList]::new()
    $Global:video_length_list = [System.Collections.ArrayList]::new()
    $Global:text_list = [System.Collections.ArrayList]::new()
    $Global:transcript_availability = [System.Collections.ArrayList]::new()
    $Global:media_count_list = [System.Collections.ArrayList]::new()

    #Helper functions to process the various elements of the page_body
    Start-ProcessLinks
    Start-ProcessIframes
    Start-ProcessVideoTags
    Start-ProcessBrightcoveVideoHTML

    #Set up data to be put into the excel document
    $data = Format-TransposeData Element, Location, VideoID, Url, VideoLength, Text, Transcript, MediaCount `
                                 $element_list, `
                                 $location_list, `
                                 $id_list, `
                                 $url_list, `
                                 $video_length_list, `
                                 $text_list, `
                                 $transcript_availability, `
                                 $media_count_list

    #Color formatting for certain cells / flags
    $mark_text_red = @((New-ConditionalText -Text "Video not found" -BackgroundColor '#ff5454' -ConditionalTextColor '#000000'))
    $highlight_text = @((New-ConditionalText -Text "Duplicate Video" -BackgroundColor '#ffff8b' -ConditionalTextColor '#000000' ))
    $mark_text_cyan = @((New-ConditionalText -Text "Inline Media:`nUnable to find title or video length for this type of video" -BackgroundColor Cyan -ConditionalTextColor '#000000'))

    #Make sure data array is not empty, then add it to Exel document
    if(-not($NULL -eq $data))
    {
        $data | Export-Excel $Global:ExcelReport -ConditionalText $mark_text_red, $highlight_text, $mark_text_cyan -AutoFilter -AutoSize -Append
    }
}

function Start-ProcessLinks
{
    #Get list of links and corresponding href's
    $link_list = $page_body | 
                    Select-String -pattern "<a.*?>.*?</a>" -AllMatches | 
                    ForEach-Object {$_.Matches.Value}
    $href_list = $link_list | 
                    Select-String -pattern 'href="(.*?)"' -AllMatches | 
                    ForEach-Object {$_.Matches.Groups[1].Value}

    #Loop through every link to check if any are the weird Canvas video links
    foreach ($link in $link_list)
    {
        #Switch to see if it meets condition
        switch -regex ($link)
        {
            "class=.*?video_link" 
            {
                #Check if it has a transcript, returns Yes or No
                $transcript = Get-TranscriptAvailable $link
                #Add item to the array
                Add-ToArray "Canvas Video Link" `
                            "" `
                            "00:00:00" `
                            "Inline Media:`nUnable to find title or video length for this type of video" `
                            $transcript `
                            (($link -split "href=`"")[-1] -split "`"")[0]
                break
            }
        }
    }

    #Loop through all of the href's to see if any are links to videos
    foreach ($href in $href_list)
    {
        #Variable to mark if the video was found or not
        $Global:video_not_found = ""
        #Get the text for corresponding link
        $text = ($link_list -match $href) | 
                Select-String -pattern "<a.*?>(.*?)</a>" -AllMatches | 
                ForEach-Object {$_.Matches.Groups[1].Value}
        $skip = $false
        #see if the href matches any of the video conditions
        switch -regex ($href)
        {
            #Check if its a yotube link, sometimes have the random . in the middle of it
            "youtu\.?be"
            {
                #Try to split to ge the ID
                $split_href = ($href -split "v=")[-1]
                #if it is then there are quite a few edge cases to check for to get ID correctly
                if ($split_href.contains("t="))
                {
                    $video_id = $split_href.split("?")[0].split("/")[-1]
                }
                elseif ($split_href.contains('='))
                {
                    $video_id = ($split_href -split 'v=')[-1].split("&")[0]
                }
                else
                {
                    $video_id = $split_href.split('/')[-1]
                }
                #Will error if video does not actually exist / the id is inccorect
                try 
                {
                    #Try to make sure everything on the ID is removed besides the ID itself
                    $video_id = $video_id.split("?")[0]
                    #Try to get the video length 
                    $video_length = [timespan]::FromSeconds((Get-GoogleVideoSeconds -VideoID $video_id)).toString("hh\:mm\:ss")
                }
                #If it failed then video does not exist or ID is wrong
                catch 
                {
                    #Print that video was not found
                    Write-Host "Video not found" -ForegroundColor Magenta
                    #Make variable empty 0's so it can still go into array fine
                    $video_length = "00:00:00"
                    $Global:video_not_found = "`nVideo not found"
                }
                #Transcript for youtube videos are always yes as it auto generates them
                $transcript = "Yes"
                $element = "YouTube Link"
                break
            }
            #Various other video platforms will now be checked for, I do not have many test cases for these to see if there are any edge cases to account for.
            "alexanderstreet"
            {
                #Get id from href
                $video_id = $href.split("/")[-1]
                #Get length with Selenium driver
                $video_length = (Get-AlexanderStreetLinkLength $video_id).toString("hh\:mm\:ss")
                #Add to array, transcript not avaiable as I am not sure if these videos auto generate them or not
                $transcript = "N\A"
                $element = "AlexanderStreet Link"
                break
            }
            "kanopy"
            {
                #Get id
                $video_id = $href.split("/")[-1]
                #Get video length with Selenim Driver
                $video_length = (Get-KanopyLinkLength $video_id).toString("hh\:mm\:ss")
                #Set other variables needed to add to data arrays
                $element = "Kanopy Link"
                $transcript = "N\A"
                break
            }
            "byu.mediasite"
            {
                #Get id
                $video_id = $href.split("/")[-1]
                $video_length = (Get-BYUMediaSiteVideoLength $video_id)
                $transcript = "N\A"
                $element = "ByuMediasite Link"
                break
            }
            "panopto"
            {
                $video_id = ($href -split "id=")[-1]
                $video_legnth = (Get-PanoptoVideoLength $video_id)
                $transcript = "N\A"
                $element = "Panopto Link"
                break
            }
            "bcove"
            {
                $chrome.Url = $href
                $video_id = $chrome.url.split('=')[-1]
                $video_length = (Get-BrightcoveVideoLength $video_id)
                $transcript = ($transcript = Get-TranscriptAvailable $href)
                $element = "Bcove Link"
                break
            }
            default
            {
                $skip = $true
            }
        }
        #Skip non-video links
        if($skip)
        {
            continue
        }
        #Add the item to the arrays to be put into the excel document
        Add-ToArray $element `
                    $video_id `
                    $video_length `
                    "$text$video_not_found" `
                    $transcript `
                    $href
    }
}

function Start-ProcessIframes
{
    #Get list of iframes within the page
    $iframe_list = $page_body | 
                    Select-String -pattern  "<iframe.*?>.*?</iframe>" -AllMatches | 
                    ForEach-Object {$_.Matches.Value}
    #loop through all iframes
    foreach ($iframe in $iframe_list)
    {
        #Global var for if the video was found
        $Global:video_not_found = ""
        #Be default assume title is empty
        $title = ""
        #Check if iframe has a title
        if(-not ($iframe.contains('title')))
        {
            $title = "No Title Attribute Found"
        }
        else 
        {   #Title exists
            #Set title to frames title
            $title = $iframe | 
                    Select-String -pattern 'title="(.*?)"' | 
                    ForEach-Object {$_.Matches.Groups[1].value}
            #if it is still empty then notify that it was found but something may be wrong with it
            if ($null -eq $title -or "" -eq $title) 
            {
                $title = "Title found but was empty or could not be saved."
            }
        }
        #Get the url for the source of the iframe
        $url = $iframe | 
                Select-String -pattern 'src="(.*?)"' | 
                ForEach-Object {$_.Matches.Groups[1].value}
        #default
        $transcript = "ASDF"
        #Check what type of iframe it is
        switch -regex ($url)
        {
            "youtube"
            {
                #Checks to make sure we correctly get the video's id
                if ($url.contains('?')) 
                {
                    $video_id = $url.split('/')[4].split('?')[0]
                }
                else 
                {
                    $video_id = $url.split('/')[-1]
                }
                #See if we can get video length
                try 
                {
                    #Try to make sure everything on the ID is removed besides the ID itself
                    $video_id = $video_id.split("?")[0]
                    #Try to get the video length 
                    $video_length = [timespan]::FromSeconds((Get-GoogleVideoSeconds -VideoID $video_id)).toString("hh\:mm\:ss")
                }
                #If it failed then video does not exist or ID is wrong
                catch 
                {
                    #Print that video was not found
                    Write-Host "Video not found" -ForegroundColor Magenta
                    #Make variable empty 0's so it can still go into array fine
                    $video_length = "00:00:00"
                    $Global:video_not_found = "`nVideo not found"
                }
                #Assign element type and transcript is auto yes for youtube
                $element = "YouTube Video"
                $transcript = "Yes"
                break
            }
            "brightcove"
            {
                #Get birghtcove id
                $video_id = ($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].value}).split('=')[-1].split("&")[0]
                #Get the length, will return 00:00:00 if not found
                $video_Length = (Get-BrightcoveVideoLength $video_id).toString('hh\:mm\:ss')
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
                #Can add this straight to the array without any other processing
                #Assign element
                $element = "H5P"
                #Need to assign everything else to be empty as this is not a video
                $video_length = "00:00:00"
                $transcript = "N\A"
                $video_id = ""
                break
            }
            "byu.mediasite"
            {
                #Get unique ID
                $video_id = ($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-1]
                #Check if it is empty, as that means the ID was wrong and try a different method to find it
                if ("" -eq $video_ID) 
                {
                    $video_id = ($iframe | 
                                Select-String -pattern 'src="(.*?)"' | 
                                ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-2]
                }
                #Get length, if it wasn't found flag will be set and length will be 00:00:00
                $video_length = (Get-BYUMediaSiteVideoLength $Video_ID).toString('hh\:mm\:ss')
                $element = "BYU Mediasite Video"
                break
            }
            "panopto"
            {
                #get panopto id
                $video_id = ($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('=').split('&')[1]
                #Get length, if it wasn't found flag will be set and length will be 00:00:00
                $video_length = (Get-PanoptoVideoLength $video_ID).toString('hh\:mm\:ss')
                $element = "Panopto Video"
                break
            }
            "alexanderstreet"
            {
                #Get unique ID
                $video_id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}) -split "token/")[-1]
                #Get length, if it wasn't found flag will be set and length will be 00:00:00
                $video_length = (Get-AlexanderStreetVideoLength $video_ID).toString('hh\:mm\:ss')
                $element = "AlexanderStreet Video"
                break
            }
            "kanopy"
            {
                #Get unique kanopy ID
                $video_id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}) -split "embed/")[-1]
                #Attempt to get video length
                $video_length = (Get-KanopyVideoLength $Video_ID).toString('hh\:mm\:ss')
                $element = "Kanopy Video"
                break
            }
            "ambrosevideo"
            {
                $video_id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('?')[-1].split('&')[0])
                $video_length = (Get-AmbroseVideoLength $Video_ID).toString('hh\:mm\:ss')
                $element = "Ambrose Video"
                break
            }
            "facebook"
            {
                $Video_ID = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value})) | 
                            Select-String -pattern "\d{17}" -Allmatches | 
                            ForEach-Object {$_.Matches.Value}
                #this is the most unreliable videos for getting the time, so there may be false negatives
                $video_length = (Get-FacebookVideoLength $Video_ID).toString('hh\:mm\:ss')
                $element = "Facebook Video"
                break
            }
            "dailymotion"
            {
                $video_id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-1])
                $video_length = (Get-DailyMotionVideoLength $Video_ID).toString('hh\:mm\:ss')
                $element = "DailyMotion Video"
                break
            }
            "vimeo"
            {
                $video_id = (($iframe | 
                            Select-String -pattern 'src="(.*?)"' | 
                            ForEach-Object {$_.Matches.Groups[1].Value}).split('/')[-1]).split('?')[0]
                $video_length = (Get-VimeoVideoLength $Video_ID).toString('hh\:mm\:ss')
                $element = "Vimeo Video"
                break
            }
            default
            {
                #This means it is just a plain iframe / one I have not ran into before so it will be unlabeled.
                $element = "Iframe"
                $video_id = ""
                $video_length = "00:00:00"
                $transcript = "N\A"
                break
            }
        }
        #If it is default value then we need to find if a transcript exist for that video
        if($transcript -eq "ASDF")
        {
            $transcript = Get-TranscriptAvailable $iframe
        }
        #Sometimes there are extra slashes at the beginning
        $url = $url -replace "^//", "https://"
        #Add item to data arrays
        Add-ToArray $element `
                    $video_id `
                    $video_length `
                    "$title$video_not_found" `
                    $transcript `
                    $url
    }
}

function Start-ProcessVideoTags
{
    #Get list of video tags
    $video_tag_list = $page_body | 
                        Select-String -pattern '<video.*?>.*?</video>' -AllMatches | 
                        ForEach-Object {$_.Matches.Value}
    #loop through all of the videos
    foreach ($video in $video_tag_list)
    {
        #get url list
        $url = $video | 
                Select-String -pattern 'src="(.*?)"' -AllMatches | 
                ForEach-Object {$_.Matches.Groups[1].Value}
        $video_id = $url.split('=')[1].split("&")[0]
        $transcript = Get-TranscriptAvailable $iframe
        Add-ToArray "Inline Media Video" `
                    $video_id `
                    "00:00:00" `
                    "Inline Media: `nUnable to find title or video length for this tpe of video" `
                    $transcript `
                    $url
    }
}

function Start-ProcessBrightcoveVideoHTML
{
    #Get list of brightcove videos (this is mainly for HTML files and the template that BYU Independant study has them in)
    $brightcove_list = $page_body | 
                        Select-String -pattern 'id="[^\d]*(\d{13}).*?"' -Allmatches | 
                        ForEach-Object {$_.Matches.Value}
    #Get list of brightcove ID's
    $id_list = $brightcove_list | 
                Select-String -pattern '\d{13}' -AllMatches | 
                ForEach-Object {$_.matches.Value}
    #loop through all of the ID's
    foreach ($id in $id_list)
    {
        $video_length = (Get-BrightcoveVideoLength $id).toString('hh\:mm\:ss')
        #Need to do a custom check for a transcript as these are mcuh more spread out
        #Split the page body into an array to make it easier to parse through
        $split_body = $page_body.split("`n")
        $i = 0
        #Parse the body until we run into the line with the video's id
        while ($split_body[$i] -notmatch "$id") {$i++}
        #Assume there is no transcript
        $transcript = "No"
        #Check if there is a transcript within 10 lines of the ID
        for ($j = $i; $j -lt ($i + 10); $j++) {
            #Make sure we haven't reached the end of the file
            if ($split_body[$j] -eq $NULL) {
                #End of file
                break
            }
            #Check if it contains the word transcript
            elseif ($split_body[$j] -match "transcript") {
                $transcript = "Yes"
                break
            }
        }
        #Add to the array
        Add-ToArray "Brightove Video" `
                    $id `
                    $video_length `
                    $title `
                    $transcript `
                    "https://studio.brightcove.com/products/videocloud/media/videos/search/$id"
    }
}

function Add-ToArray {
    param(
        [string]$element,
        [string]$VideoID,
        [TimeSpan]$VideoLength,
        [string]$Text,
        [string]$Transcript,
        [string]$url,
        [string]$MediaCount = 1
    )
    #Make sure url is formatted right
    #Get the excel document to see if there are any duplicates (mostly for Video ID's, don't want to count a videos time more then once)
    $Global:excel = Export-Excel $Global:ExcelReport -PassThru
    #Add to the given arrays
    $Global:element_list += $element
    #location is the same string manipulation for each item
    $Global:location_list += "{0}" -f ($item.url -split "api/v\d/" -join "")
    #Make sure excel is not empty
    if ($NULL -eq $excel) {}
    else {
        #If ID is empty, no need to check if it exists
        if ("" -eq $videoID -or $NULL -eq $videoID) {
            $Global:id_list += $VideoID
            $Global:video_length_list += $VideoLength
        }
        #If excel contains video id then add Duplicate Video tag to beginning and we don't want to include the time again
        elseif ($excel.Workbook.Worksheets['Sheet1'].Names.Value -contains $videoID) {
            $Global:id_list += "Duplicate Video: `n$videoID"
            #Make length 0 so it doesn't get added to total video time
            $Global:video_length_list += ""
        }
        #Just add it to the array as it is unique
        else {
            $Global:id_list += $VideoID
            $Global:video_length_list += $VideoLength
        }
    }
    $Global:text_list += $Text
    $Global:transcript_availability += $Transcript
    $Global:media_count_list += $MediaCount
    $Global:url_list += $url
    #Close the excel doc so it doesn't cause issues elsewhere having it open
    $excel.Dispose()
}