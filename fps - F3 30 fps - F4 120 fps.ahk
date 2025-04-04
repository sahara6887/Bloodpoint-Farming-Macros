﻿#SingleInstance Force
#Persistent
#IfWinActive DeadByDaylight

CoordMode, Pixel, Window

SetMouseDelay, -1 ; Make cursor move instantly rather than mimicking user behavior

; Set 30 FPS
F3::
{
    ; 30 FPS option
    selectFpsOption(1760, 778)
}
return

; Set 120 FPS
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

    ; 30 FPS option
    scaledClick(x, y)

    closeSettings()

    log("Setting FPS took " . (A_TickCount - start) . " ms")
}

; All pixel coordinates are relative to Snoggles 1440p monitor.
; Detect a scaling factor for other resolutions such as 1080p.
; This should be tested every time in case the resolution changes.
; Runtime of this function was measured at 0 ms, so it's effectively free.
detectDbdWindowScale() {
    global xScale, yScale

    WinGetPos, ignoredX, ignoredY, DbdWidth, DbdHeight, DeadByDaylight

    ; Scaling factor for monitors at resolutions other than 2560x1440
    xScale := DbdWidth / 2560
    yScale := DbdHeight / 1440
}

openGraphicsSettings() {
    ; Open Settings
    Send, {ESC}

    ; Sometimes the game lags with black screen when opening menu first time.
    ; Wait for the screen to open.
    ; Note that the [ ESC ] (295, 1350) button looks pure white, but is slightly off white!
    doWithRetriesUntil("doNothing", "isSettingsOpen")

    ; Select "Graphics" tab
    doWithRetriesUntil("selectGraphicsTab", "isGraphicsTabSelected")

    ; Open FPS dropdown
    scaledClick(1350, 938)
    ; The text strokes of the FPS options are thin. Hard to find a pure white pixel.
    ; We'll just sleep here instead of pixel matching since this menu seems performant enough.
    Sleep, 50
}

closeSettings() {
    Send, {ESC}
}

isSettingsOpen() {
    ; 'E' of MATCH DETAILS (1999, 100)
    ; ']' of ESC: (295, 1350)
    color := getColor(1999, 100)

    ; The pixel starts off-white and eventually becomes full white.
    ; We only care if each RGB component is > 0xF8, so we'll mask the low bits
    maskedColor := color | 0x070707
    return maskedColor = 0xFFFFFF
}

selectGraphicsTab() {
    scaledClick(988, 94)
}

isGraphicsTabSelected() {
    ; 'R' of 'GRAPHICS': (950, 100)
    return (getColor(950, 100) | 0x030303) = 0xFFFFFF
}

doWithRetriesUntil(actionName, predicateName, maxDurationMs := 500) {
    startTime := A_TickCount  ; Get the current time (in milliseconds)
    action := Func(actionName)
    predicate := Func(predicateName)

    while (A_TickCount - startTime < maxDurationMs) {
        action.call()
        result := predicate.call()
        if (result) {
            duration := A_TickCount - startTime
            log(predicateName . " took " . duration . " ms.")
            return
        }
        Sleep, 25
    }

    log("Failed waiting for " . predicate.Name . " after " . maxDurationMs . " ms.")

    Exit
}

getColor(x, y) {
    global xScale, yScale
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    PixelGetColor, color, scaledX, scaledY

    log("get color at (" . scaledX . ", " . scaledY . ") color=" . color)
    return color
}

; Click on the scaled coords.
; Prevent mouse movement from the user which may cause the click to miss
scaledClick(x, y) {
    global xScale, yScale

    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    BlockInput, MouseMove  ; Block mouse movement
    Click, %scaledX%, %scaledY%
    BlockInput, MouseMoveOff  ; Re-enable mouse movement
}

log(msg) {
    ; Uncomment while developing:
    ; OutputDebug, %msg% ; view with https://learn.microsoft.com/en-us/sysinternals/downloads/debugview
}

doNothing() {
    ; used as a noop for doWithRetriesUntil(action, predicate)
}
