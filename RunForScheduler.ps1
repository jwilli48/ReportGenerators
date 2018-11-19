$ScriptPath = "$home\Desktop\AccessibilityTools\CanvasReport-master"

."$ScriptPath/LinkReport.ps1"
."$ScriptPath/MediaReport.ps1"
."$ScriptPath/A11yReport.ps1"

Invoke-A11yReport -course_id $args[0] -domain $args[1]
MediaReport -course_id $args[0] -domain $args[1]

#Only run link report if it is a directory
if (4 -eq $args[1]) {
    LinkReport -course_id $args[0]
}

."$ScriptPath/CombineReports.ps1"

CombineReports -course_id $args[0] -domain $args[1]