#SingleInstance Force
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
    global settingFpsTookMs
    start := A_TickCount

    detectDbdWindowScale()
    openGraphicsSettings()

    scaledClick(x, y)

    closeSettings()

    settingFpsTookMs := A_TickCount - start
    info("Setting FPS took " . settingFpsTookMs . " ms")
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
    doWithRetriesUntil("openFpsMenu", "isFpsMenuOpen")
}

closeSettings() {
    Send, {ESC}
}

isSettingsOpen() {
    ; 'E' of MATCH DETAILS (1999, 100)
    ; ']' of ESC: (295, 1350)
    matchDetailsE := getColor(1999, 100)

    ; Black background of back button to disquality all bright images
    backBlack := getColor(200, 1370)

    return isWhiteish(matchDetailsE) && isBlackish(backBlack)
}

selectGraphicsTab() {
    scaledClick(988, 94)
}

isGraphicsTabSelected() {
    ; 'R' of 'GRAPHICS': (950, 100)
    return isWhiteish(getColor(950, 100))
}

openFpsMenu() {
    ; Center of FPS option
    scaledClick(1350, 938)
}

isFpsMenuOpen() {
    ; Check for the base of the 2 of the 120: (1771, 1100)
    return isWhiteish(getColor(1771, 1100))
}

doWithRetriesUntil(actionName, predicateName, maxDurationMs := 500) {
    startTime := A_TickCount  ; Get the current time (in milliseconds)
    action := Func(actionName)
    predicate := Func(predicateName)

    while (A_TickCount - startTime < maxDurationMs) {
        action.Call()

        ; Check several times before repeating the action.
        ; Checking instantly isn't enough time, but the action is often slow,
        ; so we don't want to repeat the action if we don't need to.
        Loop, 5 {
            if (predicate.Call()) {
                duration := A_TickCount - startTime
                log(predicate.Name . " took " . duration . " ms.")
                return
            }
            Sleep, 10
        }
    }

    log("Failed waiting for " . predicate.Name . " after " . maxDurationMs . " ms.")

    Exit
}

isWhiteish(color) {
    ; Some pixels starts off-white and eventually becomes full white.
    ; We only care if each RGB component is > 0xF8, so we'll mask the low bits
    ; Most reshade filters leave near-pure-white pixels as near-pure-white.
    ; isWhiteish := (color | 0x070707) = 0xFFFFFF

    ; isBrightish is a less specific alternative for users with reshade filters that transform white pixels to:
    ; - non-white, e.g. tint
    ; - non-stable values that change based on surrounding pixels (fog removal, bloom, etc.)
    ; Setting to isBrightish may result in false positives.
    b := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    r := color & 0xFF
    thres := 0xD0
    isBrightish := r > thres && g > thres && b > thres

    return isBrightish
}

isBlackish(color) {
    return (color & 0xF0F0F0) == 0
}

getColor(x, y) {
    global xScale, yScale, lastCheckedColor
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    PixelGetColor, lastCheckedColor, scaledX, scaledY

    log("get color at (" . scaledX . ", " . scaledY . ") color=" . lastCheckedColor)
    return lastCheckedColor
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

info(msg) {
    ; Uncomment while developing:
    ; OutputDebug, %msg% ; view with https://learn.microsoft.com/en-us/sysinternals/downloads/debugview
}

doNothing() {
    ; used as a noop for doWithRetriesUntil(action, predicate)
}
