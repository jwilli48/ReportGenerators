function Search-CanvasCourse 
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$course_id,
        $type
    )
    #Get the course name and fix it so it won't throw errors later on
    $course_name = (Get-CanvasCoursesById -Id $course_id).course_code
    $course_name = $course_name -replace [regex]::escape('+'), ' ' -replace ':', ''

    #Set path to the excel report    
    $Global:ExcelReport = "$PSScriptRoot\Reports\{2}_{0}_{1}.xlsx" -f $course_name, $ReportType, $type

    #Make sure it does not already exist
    if (Test-Path $Global:ExcelReport)
    {
        #If it does append a (Copy) tag to the end of file path
        $i = 1
        while($true)
        {
            #Keep incrementing until we find a file name that does not exist
            $NewPath = $Global:ExcelReport -replace ".xlsx", " (V $i).xlsx"
            #Break once filename is unique
            if (-not (Test-Path $NewPath))
            {
                $Global:ExcelReport = $NewPath
                break
            }
            $i++
        }
    }
    
    #Get all of the modules in the course (this is most likely to contain only what is actually being used in the course)
    $course_modules = Get-CanvasModule -CourseId $course_id

    #Loop through all modules in the course
    foreach ($module in $course_modules) 
    {
        #Print name of module
        Write-Host "Module: $($module.name)" -ForegroundColor Cyan

        #Get all items within module
        $module_items = Get-CanvasModuleItem -Course $course_id -ModuleId $module.id

        #loop through all module items
        foreach ($item in $module_items)
        {
            #If anything throws an error then we don't have access
            try{
                #Figure out the type of the item so we can use correct search API command
                if ($item.type -eq "Page") {
                    $page = Get-CanvasCoursesPagesByCourseIdAndUrl -CourseId $course_id -Url $item.page_url
                    $page_body = $page.body
                }
                elseif ($item.type -eq "Discussion") {
                    $page = Get-CanvasCoursesDiscussionTopicsByCourseIdAndTopicId -CourseId $course_id -TopicId $item.content_id
                    $page_body = $page.message
                }
                elseif ($item.type -eq "Assignment") {
                    $page = Get-CanvasCoursesAssignmentsByCourseIdAndId -CourseId $course_id -Id $item.content_id
                    $page_body = $page.description
                }
                elseif ($item.type -eq "Quiz") {
                    $page = Get-CanvasQuizzesById -CourseId $course_id -Id $item.content_id
                    $page_body = $page.description
                }
                else {
                    #if its not any of the above just skip it as it is not yet supported
                    Write-Host "Not Supported:`n$item " -ForegroundColor Yellow
                    continue
                }
            }catch{
               #Check if it was an unauthorized error
                if($_ -match "Unauthorized")
                {
                    #Print nicer formatted error message
                    Write-Host "ERROR: (401) Unauthorized, can not search:`n$item" -ForegroundColor Red
                }
                else
                {
                    #Unknown erorr, print whole thing out
                    Write-Host $_ -ForegroundColor Red
                }
            }
            

            #Print name of item
            Write-Host $item.title -ForegroundColor Green

            #Check if page is empty
            if ('' -eq $page_body -or $NULL -eq $page_body) 
            {
                continue
            }

            #Process contents of the page
            Start-ProcessContent $page_body

            #If item is a quiz need to check all of the questions
            if ($item.type -eq "Quiz")
            {
                #Wrap in try, catch block as we may not be authorized to check the quiz questions
                try
                {
                    $quiz_questions = Get-CanvasQuizQuestion -CourseId $course_id -QuizId $item.content_id

                    #loop through each questions
                    foreach ($question in $quiz_questions)
                    {
                        if ('' -ne $question.question_text -and $NULL -ne $question.question_text)
                        {
                            Start-ProcessContent $question.question_text
                        }

                        #loop through all answers
                        foreach ($answer in $question.answers)
                        {
                            #Make sure it isn't empty
                            if('' -ne $answer.html -and $NULL -ne $answer.html)
                            {
                                #Answer text
                                Start-ProcessContent $answer.html
                            }
                            #Make sure it isn't empty
                            if ('' -ne $answer.comments_html -and $NULL -ne $answer.comments_html)
                            {
                                #Answer comments by teacher
                                Start-ProcessContent $answer.comments_html
                            }
                            
                        }
                    }
                } 
                catch 
                {
                    #Check if it was an unauthorized error
                    if($_ -match "Unauthorized")
                    {
                        #Print nicer formatted error message
                        Write-Host "ERROR: (401) Unauthorized, can not search quiz questions. Skipping..." -ForegroundColor Red
                    }
                    else
                    {
                        #Unknown erorr, print whole thing out
                        Write-Host $_ -ForegroundColor Red
                    }
                }
            }
        }
    }
}

function Search-CourseDirectory
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$directory,
        $type
    )

    #Get the course name, second to last split of the directory path
    $course_name = $directory.split('\')[-2]

    #Get the type (drive) of report. Global as this variable can be set in various different places
    $Global:ReportType = "{0}Drive" -f $Directory[0]
    $Global:ExcelReport = "$PSScriptRoot\Reports\{2}_{0}_{1}.xlsx" -f $course_name, $ReportType, $type
    #Make sure it does not already exist
    if (Test-Path $Global:ExcelReport) {
        #If it does append a (Copy) tag to the end of file path
        $i = 1
        while ($true) {
            #Keep incrementing until we find a file name that does not exist
            $NewPath = $Global:ExcelReport -replace ".xlsx", " (V $i).xlsx"
            #Break once filename is unique
            if (-not (Test-Path $NewPath)) {
                $Global:ExcelReport = $NewPath
                break
            }
            $i++
        }
    }
    #Get course HTML files, exclude files names that are common to ignore
    $course_files = Get-ChildItem "$directory\*.html" -Exclude '*old*', '*ImageGallery*', '*CourseMedia*', '*GENERIC*'

    #Check if directory is empty (possibly inout wrong file path)
    if ($NULL -eq $course_files) 
    {
        Write-Host "ERROR: Directory input is empty"
    }
    else
    {
        #Loop through all of the files
        foreach ($file in $course_files)
        {
            #Get the file contents as UTF8 and raw so it will fit into same Start-ProcessContent as the Canvas Course
            $file_content = Get-Content -Encoding UTF8 -Path $file.PSPath -raw

            #Set the link URL for the given directory, this is to dramatically speed up and optimize the location links in the end Excel Report.
            #Each condition will manipulate the directory to match the correct form needed for the URL
            if ($directory[0] -eq "I")
            {
                $url = "https://iscontent.byu.edu/$($directory -replace `"I:\\`", `"`")/$($file.name)"
            }
            elseif ($directory[0] -eq "Q")
            {
                $url = "https://isdev.byu.edu/courses/$($directory -replace `"Q:\\`", `"`")/$($file.name)"
            }
            else
            {
                #This is default extenstion to open a file in a browser
                $url = "file:///$directory/$($file.name)"
            }

            #Put into an object named item to make it fit into the Start-ProcessContent properly
            $item = Format-TransposeData body, title, url $file_content, $file.name, $url

            #To match variable names for processes inside of Start-ProcessContent
            $page_body = $item.body

            #Print file name
            Write-Host $item.title -ForegroundColor Green

            #Check if page_body is empty and if it is skip this file
            if ('' -eq $page_body -or $NULL -eq $page_body) 
            {
                continue
            }

            #Process the contents
            Start-ProcessContent $page_body
        }

        #Once done going through files need to check the .css file for specific course
        $path_to_css = "{0}\this_course_only.css" -f $Directory.replace("HTML", "CSS")

        if (Test-Path $path_to_css) 
        {
            #Get file content in correct format
            $file_content = Get-Content -Encoding UTF8 -Path $path_to_css -raw

            #This should be a basic file open extension so it will open in default text editor
            $url = "file:///$path_to_css"

            #Get into item format to be input correctly into Start-ProcessContent
            $item = Format-TransposeData body, title, url $file_content, $file_content.PSChildName, $url

            #Print file name
            Write-Host $item.title -ForegroundColor Green

            #Set content to correct var
            $page_body = $item.body
            
            #Process
            Start-ProcessContent $page_body
        }
    }
}