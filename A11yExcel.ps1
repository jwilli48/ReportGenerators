function ConvertTo-A11yExcel {
    <#
    .DESCRIPTION

    Moves the default excel sheet made into the template excel sheet. Takes the each row of default excel sheet then adds it to the correct table with the correct values in the template then saves over the old one.
    #>
    #Get the template into a variable
    $template = Open-ExcelPackage -Path "$PsScriptRoot\CAR - Accessibility Review Template.xlsx"
    #Attempt to get the data from the excel sheet and format it
    try
    {
        #Get the data
        $data = Import-Excel -path $ExcelReport
        #Get the cells
        $cell = $template.Workbook.Worksheets[1].Cells
        $rowNumber = 9
        #Loop through the entire data array
        for ($i = 0; $i -lt $data.length; $i++) 
        {
            #The firs column to set would be Not Started for all rows
            $cell[$rowNumber, 2].Value = "Not Started"
            #Location is set the same way for all issues in data array
            $cell[$rowNumber, 3].Value = $data[$i].Location
            #Parse through all possible issues to correctly input it into the template
            switch ($data[$i].Accessibility) 
            {
                "Needs a title" 
                {
                    Add-ToCell "Semantics" `
                               "Missing title/label" `
                               ("{0} needs a title attribute`nID: {1}" -f $data[$i].Element, $data[$i].VideoID)
                    Break
                }
                "Adjust Link Text" 
                {
                    Add-ToCell "Link" `
                               "Non-Descriptive Link" `
                               ("{0}" -f $data[$i].Text)
                    Break
                }
                "No Alt Attribute" 
                {
                    Add-ToCell "Image" `
                               "No Alt Attribute" `
                               ""
                    Break
                }
                "Alt Text May Need Adjustment" 
                {
                    Add-ToCell "Image" `
                               "Non-Descriptive alt tags" `
                               ("{0}" -f $data[$i].Text)
                    break
                }
                "JavaScript links are not accessible" 
                {
                    Add-ToCell "Link" `
                               "" `
                               ("{0}`n{1}" -f $data[$i].Text, $data[$i].Accessibility) `
                               3 3 3
                    break
                }
                "Check if header is meant to be invisible and is not a duplicate" {
                    Add-ToCell "Semantics" `
                               "Improper Headings" `
                               ("{0}, a {1}, is invisible" -f $data[$i].Text, $data[$i].Element) `
                               3 3 3
                    break
                }
                "Broken link" 
                {
                    Add-ToCell "Link" `
                               "Broken Link" `
                               ("{0}" -f $data[$i].Text) `
                               5 5 5
                    break
                }"No transcript found" 
                {
                    Add-ToCell "Media" `
                               "Transcript Needed" `
                               ("{0}" -f $data[$i].Text) `
                               5 5 5
                    break
                }"Revise table" 
                {
                    Add-ToCell "Table" `
                               "" `
                               ("{0}" -f $data[$i].Text)
                    break
                }"<i>/<b> tags should be <em>/<strong> tags" 
                {
                    Add-ToCell "Semantics" `
                               "Bad use of <i> and/or <b>" `
                               ("{0}" -f $data[$i].Accessibility)
                    break
                }"Empty link tag" 
                {
                    Add-ToCell "Link" `
                               "Broken Link" `
                               ("{0}" -f $data[$i].Text)
                    break
                }"Flash is inaccessible" 
                {
                    Add-ToCell "Misc" `
                               "" `
                               ("{0}.`n{1}" -f $data[$i].Text, $data[$i].Accessibility)
                    break
                }"Does not meet AA color contrast" 
                {
                    Add-ToCell "Color" `
                               "Doesn't meet contrast ratio" `
                               ("{0}:`n{1}" -f $data[$i].Accessibility, $data[$i].Text)
                    break
                }default 
                {
                    Add-ToCell "" `
                               "" `
                               ("{0}, `n{1},`n{2}" -f $data[$i].Element, $data[$i].Text, $data[$i].Accessibility)
                    break
                }
            }
            #increment row number to input next data set into next row
            $rowNumber++
        }
        #Format the location column to be links to the page with the given issue
        $column = 3 #C
        $row = 9 #start of data
        while ($NULL -ne $cell[$row, $column].Value) 
        {
            $cell[$row, $column].Hyperlink = $cell[$row, $column].Value
            $cell[$row, $column].Value = $cell[$row, $column].Value.Split("/").split("\")[-1]
            $row++
        }

        #Format the conditional coloring as it gets messed up with the conversion for some reason
        $template.Workbook.Worksheets[1].ConditionalFormatting[0].LowValue.Color = [System.Drawing.Color]::FromArgb(255, 146, 208, 80)
        $template.Workbook.Worksheets[1].ConditionalFormatting[0].MiddleValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 213, 5)
        $template.Workbook.Worksheets[1].ConditionalFormatting[0].HighValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 71, 71)
        $template.Workbook.Worksheets[1].ConditionalFormatting[1].LowValue.Color = [System.Drawing.Color]::FromArgb(255, 146, 208, 80)
        $template.Workbook.Worksheets[1].ConditionalFormatting[1].MiddleValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 213, 5)
        $template.Workbook.Worksheets[1].ConditionalFormatting[1].HighValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 71, 71)
        #Set the date format for a specific cell
        Set-Format -WorkSheet $template.Workbook.Worksheets[1] -Range "E6:E6" -NumberFormat 'Short Date'
    }
    catch
    {
        #Print out error message if it fails
        Write-Host "Error formatting excel to template, attemping to save it as is: ErrorMessage:`n$_" -ForegroundColor Red
    }
    #Attempt to save
    try
    {
        Close-ExcelPackage $template -SaveAs "$ExcelReport"
    }
    catch
    {
        #Print out error message if it fails to save
        Write-Host "Failed to save excel document:`n$_" -ForegroundColor Red
    }
}

function Add-ToCell {
    <#
  .DESCRIPTION

  Used in the ConvertTo-A11yExcel function, used to simplify adding data to the correct cells.
  #>
    param(
        [string]$issueType,
        [string]$DescriptiveError,
        [string]$Notes,
        [int]$Serverity = 1,
        [int]$Occurence = 1,
        [int]$Detection = 1
    )
    $cell[$rowNumber, 4].Value = $issueType
    $cell[$rowNumber, 5].Value = $DescriptiveError
    $cell[$rowNumber, 6].Value = $Notes
    $cell[$rowNumber, 7].Value = $Serverity
    $cell[$rowNumber, 8].Value = $Occurence
    $cell[$rowNumber, 9].Value = $Detection
}