#Persistent
#SingleInstance Force
SetTitleMatchMode, 1 ; Exact title match

; Skips DBD startup screens until the [ESC] text on main menu is visible.

isDbdRunning := false

SetTimer, CheckIfDbdRunning, 5000
return

CheckIfDbdRunning:
IfWinExist, DeadByDaylight
{
    if (!isDbdRunning)
    {
        OutputDebug, DBD found. Starting check loop.
        isDbdRunning := true
        SetTimer, ClickThroughScreens, 500
        global StartTime := A_TickCount
    }
}
else
{
    isDbdRunning := false
}
return

ClickThroughScreens:
{
    PixelGetColor, color, 238, 1351, RGB
    if (color = 0xFFFFFF || (A_TickCount - StartTime > 120000)) ; stop after 2 minutes or [ESC] pixel turns white
    {
        OutputDebug, Main menu reached. My work here is done.
        SetTimer, ClickThroughScreens, Off
        ToolTip
        return
    }

    ToolTip, Clicking through startup screens...
    ControlClick,, DeadByDaylight
}
return
