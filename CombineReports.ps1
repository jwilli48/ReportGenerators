function CombineReports {
    param (
        $course_id,
        $domain
    )
    ."$PSScriptRoot/PoshCanvas.ps1"
    if($domain -eq 4)
    {
        #Get the course name, second to last split of the directory path
        $course_name = $course_id.split('\')[-2]
    }
    else
    {
        $course_name = (Get-CanvasCoursesById -Id $course_id).course_code
        $course_name = $course_name -replace [regex]::escape('+'), ' ' -replace ':', ''
    }
    try{
        $main_excel_path = (Get-ChildItem -Path "$PSScriptRoot\Reports\A11yReport_$course_name*.xlsx")[0].FullName
    }catch{

    }
    try{
        $media_excel_path = (Get-ChildItem -Path "$PSScriptRoot\Reports\MediaReport_$course_name*.xlsx")[0].FullName
    }catch{

    }
    try{
        $link_excel_path = (Get-ChildItem -Path "$PSScriptRoot\Reports\LinkCheck_$course_name*.xlsx")[0].FullName
    }catch{

    }
    if($main_excel_path)
    {
        if($media_excel_path)
        {
            Import-Excel -Path $media_excel_path -WorksheetName 'Sheet1' |
                Export-Excel -Path $main_excel_path -WorksheetName "Media Report" -StartRow 4 -StartColumn 2 -NoHeader

            $excel = Export-Excel $main_excel_path -PassThru
            
            #Make sure number format is correct for the time vs. normal numbers, otherwise it defaults to scientific notation
            $sheet = $excel.Workbook.Worksheets["Media Report"]
            Set-Format -WorkSheet $sheet -Range "F:F" -NumberFormat "hh:mm:ss"
            Set-Format -WorkSheet $sheet -Range "D:D" -NumberFormat "#############"
            Set-Format -WorkSheet $sheet -Range "K:L" -NumberFormat "hh:mm:ss"
            #Loop through the Location collumn to change all of the locations to hyperlinks and change name to be more readable
            $cell = $excel.Workbook.Worksheets["Media Report"].Cells
            $column = 3 #C
            $row = 4 #start of data
            #While the cell is not empty keep going
            while ($NULL -ne $cell[$row, $column].Value) {
                $cell[$row, $column].Hyperlink = $cell[$row, $column].Value
                $cell[$row, $column].Value = $cell[$row, $column].Value.Split("/").split("\")[-1]
                $row++
            }
            #Close and save the excel
            Close-ExcelPackage $excel
            Remove-Item -Path $media_excel_path -Force
        }
        if($link_excel_path)
        {
            Import-Excel -Path $link_excel_path -WorksheetName "Sheet1" |
                Export-Excel -Path $main_excel_path -WorksheetName "Link Report" -StartRow 4 -StartColumn 2 -NoHeader

            $excel = Export-Excel $main_excel_path -PassThru
            $cell = $excel.Workbook.Worksheets["Link Report"].Cells
            $column = 2 #C
            $row = 4 #start of data
            #While the cell is not empty keep going
            while ($NULL -ne $cell[$row, $column].Value) {
                $cell[$row, $column].Hyperlink = $cell[$row, $column].Value
                $cell[$row, $column].Value = $cell[$row, $column].Value.Split("/").split("\")[-1]
                $row++
            }
            #Close and save the excel
            Close-ExcelPackage $excel
            Remove-Item $link_excel_path
        }
    }
    $FinalReportPath = $main_excel_path -replace "A11yReport", "FinalReport"
    if (Test-Path $FinalReportPath) {
        #If it does append a (Copy) tag to the end of file path
        $i = 1
        while ($true) {
            #Keep incrementing until we find a file name that does not exist
            $NewPath = $FinalReportPath -replace ".xlsx", " (V $i).xlsx"
            #Break once filename is unique
            if (-not (Test-Path $NewPath)) {
                $FinalReportPath = $NewPath
                break
            }
            $i++
        }
    }

    #Touch up the document
    $excel = Export-Excel $main_excel_path -PassThru
    #Format the conditional coloring as it gets messed up with the conversion for some reason
    $excel.Workbook.Worksheets[1].ConditionalFormatting[0].LowValue.Color = [System.Drawing.Color]::FromArgb(255, 146, 208, 80)
    $excel.Workbook.Worksheets[1].ConditionalFormatting[0].MiddleValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 213, 5)
    $excel.Workbook.Worksheets[1].ConditionalFormatting[0].HighValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 71, 71)
    $excel.Workbook.Worksheets[1].ConditionalFormatting[1].LowValue.Color = [System.Drawing.Color]::FromArgb(255, 146, 208, 80)
    $excel.Workbook.Worksheets[1].ConditionalFormatting[1].MiddleValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 213, 5)
    $excel.Workbook.Worksheets[1].ConditionalFormatting[1].HighValue.Color = [System.Drawing.Color]::FromArgb(255, 255, 71, 71)
    #Set the date format for a specific cell
    Set-Format -WorkSheet $excel.Workbook.Worksheets[1] -Range "E6:E6" -NumberFormat 'Short Date'
    Close-ExcelPackage $excel

    Rename-Item -Path $main_excel_path -NewName $FinalReportPath
}