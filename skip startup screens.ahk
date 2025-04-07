#Persistent
#SingleInstance Force
; Skips DBD startup screens until the [ESC] text on main menu is visible.
; DBD must be fullscreen and visible

; Set showToolTip to false if you don't want tooltip status reports.
global showToolTip := true

SetTitleMatchMode, 1 ; Exact title match
CoordMode, Pixel, Screen
global startTime, xScale, yScale
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
    ; Main menu: bottom of 'E' of '[ESC]' Some users have funky reshade filters that make this as dark as 0xbfc4b1
    escText := getColor(251, 1358)
    escTextIsWhite := isWhiteish(escText)

    ; Main menu: Middle of the red '<' arrow
    ; Can be a dark red without reshade filters, so we must look at hue rather than red component intensity
    backArrow := getColor(137, 1349)
    backArrowIsRed := isRedish(backArrow)

    isMainMenuLoaded := escTextIsWhite && backArrowIsRed
    waitedTooLong := A_TickCount - StartTime > 90000

    if (isMainMenuLoaded || waitedTooLong)
    {
        ; Finished/Loaded
        SetTimer, ClickThroughScreens, Off

        global dbdLoadTimeSeconds := elapsedSeconds() ; set global var for user retrieval later.
        statusUpdate("DBD started in " . dbdLoadTimeSeconds . " seconds.")
        SetTimer, clearToolTip, 2000
    } else {
        ; Not loaded/keep clicking...
        ; statusUpdate("Clicking through startup screens (" . elapsedSeconds() . " sec)...")
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

isRedish(color) {
    b := ((color >> 16) & 0xFF) / 255.0
    g := ((color >> 8) & 0xFF) / 255.0
    r := (color & 0xFF) / 255.0

    max := r, min := r
    if (g > max)
        max := g
    if (b > max)
        max := b
    if (g < min)
        min := g
    if (b < min)
        min := b

    delta := max - min

    if (delta = 0) {
        return false  ; grayscale (no hue)
    } else if (max = r) {
        hue := 60 * Mod(((g - b) / delta), 6)
    } else if (max = g) {
        hue := 60 * (((b - r) / delta) + 2)
    } else {
        hue := 60 * (((r - g) / delta) + 4)
    }

    if (hue < 0)
        hue += 360

    ; Reddish hue range: 0–20 or 340–360
    return (hue <= 20 || hue >= 340)
}

isWhiteish(color) {
    ; isBrightish handles reshade filters that transform near-pure-white pixels to:
    ; - non-white, e.g. tint
    ; - non-stable values that change based on surrounding pixels (fog removal, bloom, etc.)
    b := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    r := color & 0xFF
    thresh := 0xb0
    isBrightish := r >= thresh && g >= thresh && b >= thresh

    return isBrightish
}
