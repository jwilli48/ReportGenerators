function Format-MediaExcelOne {
    <#
    .DESCRIPTION

    Formats the media excel sheet which we do not have a template for. Makes sure that some of the rows do not become to long, gives it a max width and makes it so the column has text wrap. Also makes sure the number format is correct for both the video ID numbers in column C, and for the video lengths in column D
    #>
    #Get the excel document
    $excel = Export-Excel $ExcelReport -PassThru
    #If it isn't empty then format the various columns
    if (-not ($NULL -eq $excel)) {
        #Set various widths in an attempt to make it look better and not be super long
        $excel.Workbook.Worksheets["Sheet1"].Column(2).Width = 50
        $excel.Workbook.Worksheets["Sheet1"].Column(2).Style.wraptext = $true
        $excel.Workbook.Worksheets["Sheet1"].Column(4).Width = 50
        $excel.Workbook.Worksheets["Sheet1"].Column(4).Style.wraptext = $true
        $excel.Workbook.Worksheets["Sheet1"].Column(5).Width = 16
        $excel.Workbook.Worksheets["Sheet1"].Column(6).Width = 75
        $excel.Workbook.Worksheets["Sheet1"].Column(6).Style.wraptext = $true
        $excel.Workbook.Worksheets["Sheet1"].Column(7).Width = 15
        #For the ID col the alignment is weird so force it to center all text
        $excel.Workbook.Worksheets["Sheet1"].Column(3).Style.HorizontalAlignment = "Left"
        #Make sure number format is correct for the time vs. normal numbers, otherwise it defaults to scientific notation
        $sheet = $excel.Workbook.Worksheets["Sheet1"]
        Set-Format -WorkSheet $sheet -Range "E:E" -NumberFormat "hh:mm:ss"
        Set-Format -WorkSheet $sheet -Range "C:C" -NumberFormat "#############"
        #Loop through the Location collumn to change all of the locations to hyperlinks and change name to be more readable
        <#$cell = $excel.Workbook.Worksheets["Sheet1"].Cells
        $column = 2 #C
        $row = 2 #start of data
        #While the cell is not empty keep going
        while ($NULL -ne $cell[$row, $column].Value) {
            $cell[$row, $column].Hyperlink = $cell[$row, $column].Value
            $cell[$row, $column].Value = $cell[$row, $column].Value.Split("/").split("\")[-1]
            $row++
        }#>
        #Close and save the excel
        $excel.Save()
        $excel.Dispose()
    }
}

function Set-MediaPivotTables {
    <#
    .DESCRIPTION

    Adds a bunch of tables and charts for quick information:
    1. Table and Chart of how many of each type of media there was found
    2. Table and Chart of how total time for each type of media
    3. Table and Chart of total video time per location in the course
    4. Table and Chart of total time based on transcripts found/not found. Can also be split to show more details, such as within the videos that don't have transcripts you can split it to see how much time for each media type.
    #>
    #Pivot table and chart to show media count based on type of media
    Export-Excel $ExcelReport -IncludePivotTable -IncludePivotChart -PivotRows "Element" -PivotData @{MediaCount = 'sum'} -ChartType PieExploded3d -ShowCategory -ShowPercent -PivotTableName "MediaTypes"
    #Pivot table and chart to show media length based on type of media
    Export-Excel $ExcelReport -IncludePivotTable -IncludePivotChart -PivotRows "Element" -PivotData @{VideoLength = 'sum'} -ChartType PieExploded3d -ShowPercent -PivotTableName "MediaLength"
    #Pivot table and chart to show media length based on location of media
    Export-Excel $ExcelReport -IncludePivotTable -IncludePivotChart -PivotRows "Location" -PivotData @{VideoLength = 'sum'} -ChartType PieExploded3d -ShowPercent -PivotTableName "MediaLengthByLocation" -NoLegend
    #Pivot table and chart to show how many hours of video are in need of transcripts
    Export-Excel $ExcelReport -IncludePivotTable -IncludePivotChart -PivotRows "Transcript" -PivotData @{VideoLength = 'sum'} -ChartType PieExploded3d -ShowCategory -ShowPercent -PivotTableName "TranscriptsVideoLength"
}

function Format-MediaExcelTwo {
    <#
    .DESCRIPTION

    After the pivot tables are added there are some additional formatting needed for those tables. The default time for the tables is in days and I want it in hours.
    #>
    #Get excel document and set the correct time format for the pivot table
    $excel = Export-Excel $ExcelReport -PassThru
    $excel.Workbook.Worksheets[3].PivotTables[0].DataFields[0].Format = "[h]:mm:ss"
    $excel.Workbook.Worksheets[4].PivotTables[0].DataFields[0].Format = "[h]:mm:ss"
    $excel.Workbook.Worksheets[5].PivotTables[0].DataFields[0].Format = "[h]:mm:ss"
    Close-ExcelPackage $excel
}