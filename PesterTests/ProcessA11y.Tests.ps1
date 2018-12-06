."..\ProcessA11y.ps1"
Describe Start-ProcessContent {
    
}

Describe Start-ProcessLinks {
    mock Add-ToArray {[PSCustomObject] @{
            Element       = $element
            VideoID       = $videoID
            Text          = $text
            Accessibility = $Accessibility
        }}
    it 'should add two issues to array (empty link and bad link text) on single pass' {
        $page_body = '<a href=""> good link text</a>'
        $results = Start-ProcessLinks
        Assert-MockCalled Add-ToArray -Exactly 2 -Scope It
        $results[0].Element | Should Be "Link"
        $results[0].VideoID | Should Be ""
        $results[0].Text | Should Be "<a href=`"`"> good link text</a>"
        $results[0].Accessibility | Should Be "Empty Link Tag"
        $results[1].Element | Should Be "Link"
        $results[1].VideoID | Should Be ""
        $results[1].Text | Should Be " good link text"
        $results[1].Accessibility | Should Be "Adjust link text"
    }
    it 'should not find error from single word link text without duplicate' {
        $page_body = "<a href=""test_link.com"">IAmAGoodLinkText</a>"
        Start-ProcessLinks | Should Be $Null
        Assert-MockCalled Add-ToArray -Exactly 0 -Scope It
    }
    it 'should error on duplicate link text' {
        $page_body = "<a href=""""> here</a>`n<a href=""""> here</a>"
        Start-ProcessLinks | Should Not Be $Null
        Assert-MockCalled Add-ToArray -Exactly 4 -Scope It
    }
}

Describe Start-ProcessImages {
    mock Add-ToArray {[PSCustomObject] @{
            Element       = $element
            VideoID       = $videoID
            Text          = $text
            Accessibility = $Accessibility
        }}
    it 'should find issue with no alt text' {
        $page_body = '<img src="asdsadsadasd.jpg">'
        $result = Start-ProcessImages
        $result | Should Not Be $null
        Assert-MockCalled Add-ToArray -Exactly 1 -Scope It
        $result.Accessibility | Should Be "No alt attribute"
    }
    it 'should find issue with any alt text that has a file extension' {
        $page_body = '<img alt="asdsd.jpg" src="asdasdad.jpg"><img alt="asdsd.png" src="asdasdad.png">'
        $result = Start-ProcessImages
        $result | Should Not Be $null
        Assert-MockCalled Add-ToArray -Exactly 2 -Scope It
        $result[0].Accessibility | Should Be "Alt Text May Need Adjustment"
        $result[1].Accessibility | Should Be "Alt Text May Need Adjustment"
    }
    it 'should not find issue with alt text that may be good' {
        $page_body = '<img alt="Maybe this is good" src="asdasdasd.jpg">'
        $result = Start-ProcessImages
        $result | Should Be $null
        Assert-MockCalled Add-ToArray -Exactly 0 -Scope It
    }
}

Describe Start-ProcessIframes {
    mock Add-ToArray {[PSCustomObject] @{
            Element       = $element
            VideoID       = $videoID
            Text          = $text
            Accessibility = $Accessibility
        }}
    it 'should only find issue with iframes that do not have a title' {
        $page_body = '<iframe src="asdasdasd.com" title="I have a title"></iframe><iframe src="asdasdas.com"></iframe>'
        $results = Start-ProcessIframes
        $results | Should Not Be $Null
        $results.Accessibility | Should Be "Needs a title"
        Assert-MockCalled Add-ToArray -Exactly 1 -Scope It
    }
    it 'should check for transcripts if the iframe is a known video type' {
        mock Get-TranscriptAvailable {}
        $page_body = '<iframe src="asdasdasd.com" title="I have a title"></iframe>
                    <iframe src="brightcove.com"></iframe>'
        $results = Start-ProcessIframes
        Assert-MockCalled Get-TranscriptAvailable -Exactly 1 -Scope It
    }
}

Describe Start-ProcessBrightcoveVideoHTML {
    
}

Describe Start-ProcessHeaders {

}

Describe Start-ProcessTables {

}

Describe Start-ProcessSemantics {

}

Describe Start-ProcessVideoTags {

}

Describe Start-ProcessFlash {

}

Describe Start-ProcessColor {

}

Describe Add-ToArray {

}

