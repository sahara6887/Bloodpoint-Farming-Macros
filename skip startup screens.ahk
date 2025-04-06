#Persistent
#SingleInstance Force
; Skips DBD startup screens until the [ESC] text on main menu is visible.
; DBD must be fullscreen and visible

; Set showToolTip to false if you don't want tooltip status reports.
global showToolTip := true

SetTitleMatchMode, 1 ; Exact title match
CoordMode, Pixel, Screen
global startTime, xScale, yScale, lastCheckedColor
isDbdRunning := false
SetTimer, CheckIfDbdRunning, 5000
return

CheckIfDbdRunning:
IfWinExist, DeadByDaylight
{
    if (!isDbdRunning)
    {
        OutputDebug, DBD found. Starting check loop.
        startTime := A_TickCount
        isDbdRunning := true
        SetTimer, ClickThroughScreens, 500
    }
} else {
    isDbdRunning := false
}
return

ClickThroughScreens:
{
    color := getColor(238, 1351) ; [ESC] main menu white pixel
    if (color = 0xFFFFFF || (A_TickCount - StartTime > 90000))
    {
        ; Finished/Loaded
        SetTimer, ClickThroughScreens, Off

        global dbdLoadTimeSeconds := elapsedSeconds() ; set global var for user retrieval later.
        statusUpdate("DBD started in " . dbdLoadTimeSeconds . " seconds.")
        SetTimer, clearToolTip, 2000
    } else {
        ; Not loaded/keep clicking...
        statusUpdate("Clicking through startup screens (" . elapsedSeconds() . " sec)...")
        ControlClick,, DeadByDaylight
    }
}
return

clearToolTip() {
    if (showToolTip)
        ToolTip
}

elapsedSeconds() {
    elapsedMs := A_TickCount - startTime
    return Floor(elapsedMs / 1000)
}

; All pixel coordinates are relative to a 1440p monitor.
; Detect a scaling factor for other resolutions such as 1080p.
; This should be tested every time in case the resolution changes.
; Runtime of this function was measured at 0 ms, so it's effectively free.
detectDbdWindowScale() {
    WinGetPos, ignoredX, ignoredY, DbdWidth, DbdHeight, DeadByDaylight

    ; Scaling factor for monitors at resolutions other than 2560x1440
    xScale := DbdWidth / 2560
    yScale := DbdHeight / 1440
}

getColor(x, y) {
    detectDbdWindowScale()
    WinGetPos, winX, winY, winWidth, winHeight, DeadByDaylight

    scaledX := Round(x * xScale) + winX
    scaledY := Round(y * yScale) + winY

    PixelGetColor, lastCheckedColor, scaledX, scaledY

    return lastCheckedColor
}

statusUpdate(msg) {
    if (showToolTip)
        ToolTip % msg
}