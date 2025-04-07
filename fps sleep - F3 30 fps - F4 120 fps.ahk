#SingleInstance Force
#Persistent
#IfWinActive DeadByDaylight

; This macro much is slower than the default one,
; but does not depend on pixels being a specific color.
; This makes it much more likely to work with bizarre reshade filters.

global xScale, yScale

CoordMode, Pixel, Window

SetMouseDelay, -1 ; Make cursor move instantly rather than mimicking user behavior

; Set 30 FPS (Ctrl-)
F3::
{
    ; 30 FPS option
    selectFpsOption(1760, 778)
}
return

; Set 120 FPS (Ctrl+)
F4::
{
    ; 120 FPS option
    selectFpsOption(1778, 1084)
}
return

; Selects an option from the FPS dropdown at the specified pixel coordinates
; relative to a 1440p resolution. These will be scaled for non-1440p resolutions.
selectFpsOption(x, y) {
    start := A_TickCount

    detectDbdWindowScale()
    openGraphicsSettings()

    scaledClick(x, y)

    closeSettings()

    global settingFpsTookMs := A_TickCount - start
}

openGraphicsSettings() {
    ; Open Settings
    Send, {ESC}

    ; Sometimes the game lags with black screen when opening menu first time.
    ; Wait for the screen to open.
    Sleep, 300

    ; Select "Graphics" tab
    scaledClick(988, 94)
    Sleep, 50

    ; Open FPS dropdown
    scaledClick(1350, 938)
    Sleep, 50
}

closeSettings() {
    Send, {ESC}
}

scaledClick(x, y) {
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    Click, %scaledX%, %scaledY%
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
