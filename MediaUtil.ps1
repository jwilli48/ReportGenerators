function Get-GoogleVideoSeconds {
    param(
        [string]$VideoID
    )
    #Get video data with API
    $gdata_uri = "https://www.googleapis.com/youtube/v3/videos?id=$VideoId&key=$GoogleApi&part=contentDetails"
    $metadata = Invoke-RestMethod $gdata_uri
    #Get the duration from the data
    $duration = $metadata.items.contentDetails.duration;
    #Convert the time to a more readable format
    $ts = [Xml.XmlConvert]::ToTimeSpan("$duration")
    '{0:00},{1:00},{2:00}.{3:00}' -f ($ts.Hours + $ts.Days * 24), $ts.Minutes, $ts.Seconds, $ts.Milliseconds | Out-Null
    #Turn the time into a timespan and convert to seconds
    $timespan = [TimeSpan]::Parse($ts)
    $totalSeconds = $timespan.TotalSeconds
    $totalSeconds
}

function Get-BrightcoveVideoLength {
    param(
        [string]$videoID
    )
    #Set automated browser to the URL that would find the video
    $chrome.url = ("https://studio.brightcove.com/products/videocloud/media/videos/search/" + $videoID)
    #See if the video exists
    try {
        $length = (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator div[class*='runtime']).text
    }
    catch {
        #If it didn't work that way then we are going to try the url that was inside of the iframe element
        try {
            $chrome.url = "https:" + ($iframe | Select-String -pattern 'src="(.*?)"' | ForEach-Object {$_.Matches.Groups[1].value})
            (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator button.vjs-big-play-button).click()
            $length = (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator div[class*="vjs-duration-display"]).text.split("`n")[-1]
        }
        catch {
            #If the source URL didn't work then that means the video is broken and does not work
            Write-Host "Video not found" -ForegroundColor Magenta
            $length = "00:00"
            $Global:videoNotFound = "`nVideo not found"
        }
    }
    #Make sure time is in correct format to return
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-BYUMediaSiteVideoLength {
    param(
        [string]$videoID
    )
    #Set to URL to find video length
    $chrome.url = "https://byu.mediasite.com/Mediasite/Play/" + $videoID
    #See if the video exists
    try {
        #We have to wait till the time loads, which means it is not null, empty or a 0 time
        while ("0:00" -eq $length -or "" -eq $length  -or $NULL -eq $length) {
            $length = (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator span[class*="duration"]).text
        }
    }
    catch {
        #If it wasn't found the flag it
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Make sure time is in correct format to return
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-PanoptoVideoLength {
    param(
        [string]$videoID
    )
    #Set URL
    $chrome.url = "https://byu.hosted.panopto.com/Panopto/Pages/Embed.aspx?id=$videoID&amp;v=1"
    Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator body
    #Try to make sure the page is loaded
    while ($chrome.ExecuteScript("return document.readyState") -ne "complete") {}
    while ($chrome.ExecuteScript("return jQuery.active") -ne 0) {}
    #Try to get time / click play button
    try {
        while((Invoke-SeFindElements -DriverList $chrome -By CssSelector -Locator "[id=copyrightNoticeContainer]").Displayed){}
        (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator 'div[aria-label="Play"]').click()
        $length = (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator span[class*="duration"]).text
    }
    catch {
        #Flag it if it throws an error as video does not exists
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Make sure time is in correct format to return
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-AlexanderStreetVideoLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://search.alexanderstreet.com/embed/token/$videoId"
    #See if video time can be found
    try {
        $length = (Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator span.fulltime).text
    }
    catch {
        #Flag if error was find
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Make sure time is in correct format to return
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-AlexanderStreenLinkLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://lib.byu.edu/remoteauth/?url=https://search.alexanderstreet.com/view/work/bibliog
raphic_entity|video_work|$videoId"
    #Try to find length
    try {
        $length = (Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator span.fulltime).text
    }
    catch {
        #Flag if error was thrown
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-KanopyVideoLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://byu.kanopy.com/embed/$videoID"
    #Try to find video length after clicking play button
    try {
        (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator button.vjs-big-play-button).click()
        $length = ((Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator div.vjs-remaining-time-display).text -split '-')[-1]
    }
    catch {
        #Flag if error was thrown
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Make sure time is in correct format to return
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-KanopyLinkLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://byu.kanopy.com/video/$videoID"
    #Try to find time after clicking play button
    try {
        (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator button.vjs-big-play-button).click()
        $length = ((Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator div.vjs-remaining-time-display).text -split '-')[-1]
    }
    catch {
        #Flag if error was thrown
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Make sure time is in correct format to return
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-AmbroseVideoLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://byu.kanopy.com/embed/$videoID"
    #Try to find length after clicking play
    try {
        (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator div.jw-icon.jw-icon-display.jw-button-color.jw-reset).click()
        $length = ((Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator span.jw-text.jw-reset.jw-text-duration).text -split '-')[-1]
    }
    catch {
        #Flag if error was thrown
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Format the time to return
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-FacebookVideoLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://www.facebook.com/video/embed?video_id=$videoID"
    #Try to find video length after clicking play button
    try {
        (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator img).click()
        $length = (Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator div[playbackdurationtimestamp]).text -replace '-', '0'
    }
    catch {
        #If that didn't work then try refreshing the page (I kept running into false negatives) and try again
        try {
            $chrome.Navigate().Refresh()
            (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator img).click()
            $length = (Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator div[playbackdurationtimestamp]).text -replace '-', '0'
        }
        catch {
            #If that didn't work then the video is broken / does not exist
            Write-Host "Video not found" -ForegroundColor Magenta
            $length = "00:00"
            $Global:videoNotFound = "`nVideo not found"
        }
    }
    #Format time
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-DailyMotionVideoLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://www.dailymotion.com/embed/video/$videoID"
    #Try to find length after clicking play
    try {
        (Invoke-SeWaitUntil -DriverList $chrome -Condition ElementIsVisible -By CssSelector -Locator button[aria-label*="Playback"]).click()
        $length = ((Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator span[aria-label*="Duration"]).text)
    }
    catch {
        #Flag if error was thrown
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Format time
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}

function Get-VimeoVideoLength {
    param(
        [string]$videoId
    )
    #Set URL
    $chrome.url = "https://player.vimeo.com/video/$videoID"
    #Try to find video length
    try {
        $length = ((Invoke-SeWaitUntil -DriverList $chromoe -Condition ElementIsVisible -By CssSelector -Locator div.timecode).text)
    }
    catch {
        #Flag if error was thrown
        Write-Host "Video not found" -ForegroundColor Magenta
        $length = "00:00"
        $Global:videoNotFound = "`nVideo not found"
    }
    #Format time
    $length = "00:" + $length
    $length = [TimeSpan]$length
    $length
}