# Report Generator
This program is now able to run on a directory of HTML files and allows you to enter either a Canvas course ID or a directory path

## NOTE

This is a refactored version of my CanvasReport repository and there are some steps needed to get it working.
1. Make a directory on your desktop called AccessibilityTools
2. Download my SeleniumPSWrapper repository and make sure it is this exact file path: C:\Users\UserName\Desktop\AccessibilityTools\PowerShell\Modules\SeleniumTest
	-There should be no other directories inside of there and you can just copy all of the files inside the SeleniumPSWrapper-master directory you downloaded into that filepath
3. Download this repositoy and place it right inside the AccessibilityTools directory

Files should look something like this:

* Desktop
	* AccessibilityTools
		* PowerShell
			* Modules
				* SeleniumTest
		* ReportGenerator-master

## DEPENDANCIES
They will be automatically installed when first running the program.
1. ImportExcel Module (For creating and formatting the Excel document generated)
2. BurntToast Module (For sending a desktop notification when the application finishes)

## How to Run
Just run the .exe file for the report you want to generate. If it is the first time running it will ask you for certain credentials needed to fully run the program and then it will save them into the Passwords directory that will also be created on the first time being run. If you need to reset any of the data entered just delete the text files or the whole Password directory to reset them. As a side note the Media Report will throw errors if you do not have a brightcove account, it should still work for everything else, but this has not been fully tested.

To run this program from PowerShell if your PowerShell execution policy is restricted, do the following commands:
1. Navigate to folder containing these scripts (Change path to where you have it on your computer)
	cd 'C:\Users\Username\Documents\ReportGenerators'
2. Type or copy the following into your PowerShell window
	Set-ExecutionPolicy Bypass -Scope Process
3. Run the script
	.\A11yReport.exe
	.\MediaReport.exe
	.\LinkReport.exe

If you wish to be able to run the program without doing the above every time, then do the following:
1. Run the following command in any PowerShell window
	Set-ExecutionPolicy Bypass -Scope CurrentUser
2. You can then just right click the program and hit 'Run with PowerShell'

	-Warning that this will also allow you to run any (possibly malicious) scripts you download from the internet without asking for permission.

## Reports
The report will be generated and saved to the Report folder within this directory.

I added another .exe to check a directory of HTML files for any broken links or file paths. Similar to the others, just outputs to an excel sheet with the links or file paths that threw errors. As Canvas has it's own built in link checker, I did not make it so the program will check anything other then HTML files.

The location column in the table will also become hyperlinks to the page that contains that specific issue. This will work both for HTML directory reports and Canvas reports (although if the files are located on a different drive it may be extremely slow / freeze).

### Accessibility Template
The template used for the Accessibility Report is the CAR - Accessibility Review Template.xlsx

There is the main Worksheet that contains all of the issues found, their rating as well as the Location column is also a link that will either go to that Canvas page or it will open up the HTML file (if you have access to it on your computer) in your default browser (although I have so far only tested it in Chrome and Firefox). There is an overview with notes at the right side of the table, it is the last item in side boxes.

There is also a worksheet that links to a bunch of the WCAG guidelines for accessibility, as well as a table and chart of the issues in another worksheet.

## First time running
***IMPORTANT:***
~~You may need to unblock the .dll files contained in the net40 folder if you wish to run the Media Report generator. I believe this can also be done all at once if you unblock the .zip file before extracting it.~~ This is no longer needed and the files will be unblocked as part of the script.

The first time you run this it will ask you to input your Canvas API and the Canvas Default URL, as well as Brightcove credentials and a Google API
1.You will need to generate your own API from your Account Settings in Canvas
2.The default/base URL for BYU's canvas is https://byu.instructure.com

## Google/YouTube API Key
In order for this program to scan YouTube videos for closed captioning, you will need to create a YouTube Data API key.

1. Go to the [Google Developer Console](https://console.developers.google.com).
2. Create a project.
3. Enable YouTube Data API
4. Create an API key

## BUGS
One issues that I seem unable to fix is if the location links are to a file that is located on a seperate drive then excel, it will cause excel to dramtically slow down / freeze when any of the links to those files are accessed.

## RECOGNICTION
Inspired by the VAST program originally created by the University of Central Florida at https://github.com/ucfopen/VAST

Able to work due to the Canvas APIs for PowerShell project at https://github.com/squid808/CanvasApis

* The code I use from that project is contained in the PoshCanvasNew.ps1 file (I just cut out all of the functions I do not use to make the file smaller)

# Accessibility Report Generator
It does not catch every accessibility issue. For example:
1. It can't check anything that appears after JavaScript is run on the page
2. Anything I haven't seen before or possibly just forget to add a check for

***This check can not tell if things are inaccessible if they rely on context*** (ex. it will only check if a table has any headers, not if the headers are correct or not)

What it can not check:
1. Rubrics within Quizzes / Assignments / Asessments as they are not stored as an HTML table