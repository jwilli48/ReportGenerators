function Format-LinkExcel {
    $excel = Export-Excel $ExcelReport -PassThru

    $cell = $excel.Workbook.Worksheets["Sheet1"].Cells
    $column = 1 #C
    $row = 2 #start of data
    #While the cell is not empty keep going
    <#while ($NULL -ne $cell[$row, $column].Value) {
        $cell[$row, $column].Hyperlink = $cell[$row, $column].Value
        $cell[$row, $column].Value = $cell[$row, $column].Value.Split("/").split("\")[-1]
        $row++
    }#>
    #Close and save the excel
    $excel.Save()
    $excel.Dispose()
}