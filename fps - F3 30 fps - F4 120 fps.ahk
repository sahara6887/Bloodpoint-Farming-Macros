#SingleInstance Force
#NoEnv
#Persistent
#IfWinActive DeadByDaylight
if (FileExist("icons/fps-120.ico"))
    Menu, Tray, Icon, icons/fps-120.ico
CoordMode, Pixel, Window

SetMouseDelay, -1 ; Make cursor move instantly rather than mimicking user behavior
global xScale, yScale, lastCheckedColor

; Set 30 FPS
F3::
{
    ; 30 FPS option
    if (FileExist("icons/fps-30.ico"))
        Menu, Tray, Icon, icons/fps-30.ico
    selectFpsOption(1760, 778)
}
return

; Set 120 FPS
F4::
{
    ; 120 FPS option
    if (FileExist("icons/fps-120.ico"))
        Menu, Tray, Icon, icons/fps-120.ico
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
    global colorMatchDetailsE := getColor(1999, 100)

    ; Red arrow `<` of back button to add further specificity
    global colorBackRed := getColor(133, 1350)

    return isWhiteish(colorMatchDetailsE) && isRedish(colorBackRed)
}

selectGraphicsTab() {
    scaledClick(988, 94)
}

isGraphicsTabSelected() {
    ; 'R' of 'GRAPHICS': (950, 100)
    global colorGraphicsR := getColor(950, 100)
    return isWhiteish(colorGraphicsR)
}

openFpsMenu() {
    ; Center of FPS option
    scaledClick(1350, 938)
}

isFpsMenuOpen() {
    ; Check for the base of the 2 of the 120: (1771, 1100)
    global colorFps120 := getColor(1771, 1100)
    return isWhiteish(colorFps120)
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

getColor(x, y) {
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    PixelGetColor, color, scaledX, scaledY

    log("get color at (" . scaledX . ", " . scaledY . ") color=" . color)
    return color
}

; Click on the scaled coords.
; Prevent mouse movement from the user which may cause the click to miss
scaledClick(x, y) {
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
