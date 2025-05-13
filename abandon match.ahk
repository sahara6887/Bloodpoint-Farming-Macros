/*
Uses the Abandon Match feature as soon as available.

Requirements:
- Looks for pure white and black pixels of text.
  Reshade filters that make them off-white/black will cause this to fail.
*/
#SingleInstance Force
#NoEnv
#Persistent
#IfWinActive DeadByDaylight

if (FileExist("icons/esc.ico"))
    Menu, Tray, Icon, icons/esc.ico

CoordMode, Pixel, Client

SetMouseDelay, -1 ; Make cursor move instantly rather than mimicking user behavior
global xScale, yScale
detectDbdWindowScale()

SetTimer, CheckForAbandon, 500
return

~^+a::
abandonMatch()
return

CheckForAbandon:
if (!WinActive("DeadByDaylight")) {
    return
}

if (isEscapeAbandonOptionVisible()) {
    start := A_TickCount

    abandonMatch()

    abandonTookMs := A_TickCount - start
    info("Abandoning match took " . abandonTookMs . " ms")
}
return

abandonMatch() {
    ; Full process of abandoning the match.
    Send, {ESC}

    doWithRetriesUntil("doNothing", "isSettingsOpen")
    doWithRetriesUntil("clickSettingsAbandonButton", "isAbandonConfirmOpen")

    clickFinalAbandonButton()
}

isEscapeAbandonOptionVisible() {
    ; Samples the [ESC] ABANDON button background in the top right
    ; in a spot that's common across keyboard (ESC), PS5 (OPTIONS)

    ; The button position moved for dbd 8.7.0.
    xShift := 9
    yShift := 19

    ; Black background
    bgLeftX := 2189 + xShift
    bgRightX := 2199 + xShift
    bgTopY := 82 + yShift
    bgBotY := 88 + yShift
    global escBlackBg1 := getColor(bgLeftX, bgTopY)
    global escBlackBg2 := getColor(bgRightX, bgTopY)
    global escBlackBg3 := getColor(bgLeftX, bgBotY)
    global escBlackBg4 := getColor(bgRightX, bgBotY)

    ; Outside of the button, which we assume to be non-black.
    fgLeftX := 2169 + xShift
    fgRightX := 2220 + xShift
    fgTopY := 43 + yShift
    fgBotY := 104 + yShift
    global escNotBlackBg1 := getColor(fgLeftX, fgTopY)
    global escNotBlackBg2 := getColor(fgRightX, fgTopY)
    global escNotBlackBg3 := getColor(fgLeftX, fgBotY)
    global escNotBlackBg4 := getColor(fgRightX, fgBotY)

    buttonIsBlack := escBlackBg1 = 0 and escBlackBg2 = 0 and escBlackBg3 = 0 and escBlackBg4 = 0
    surroundIsNotBlack := escNotBlackBg1 != 0 and escNotBlackBg2 != 0 and escNotBlackBg3 != 0 and escNotBlackBg4 != 0

    return buttonIsBlack and surroundIsNotBlack
}

clickSettingsAbandonButton() {
    ; Abandon button in the bottom right of the settings page
    scaledClick(2400, 1330)
}

isAbandonConfirmOpen() {
    ; After we click Abandon, we get a confirmation dialog
    ; It has a title of ABANDON in pure white
    global confirmWhiteA := getColor(1171, 380)
    global confirmWhiteN := getColor(1375, 372)
    return confirmWhiteA = 0xFFFFFF and confirmWhiteN = 0xFFFFFF
}

clickFinalAbandonButton() {
    ; Final abandon button
    ; It loads in lower on the screen and drifts up.
    ; We'll aim towards the bottom in case it's clickable then.
    scaledClick(1844, 1067)
}

; All pixel coordinates are relative to a 1440p monitor.
; Detect a scaling factor for other resolutions such as 1080p.
; This should be tested every time in case the resolution changes.
; Runtime of this function was measured at 0 ms, so it's effectively free
detectDbdWindowScale() {
    static lastCheck := 0

    if (A_TickCount - lastCheck > 1000) {
        ; WinGetPos, winX, winY, DbdWidth, DbdHeight, DeadByDaylight
        ; WinGetPos does not return the client area height while windowed, regardless of CoordMode, Client.
        WinGet, hwnd, ID, DeadByDaylight
        VarSetCapacity(rect, 16, 0)
        DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
        DbdWidth  := NumGet(rect, 8, "Int")
        DbdHeight := NumGet(rect, 12, "Int")

        ; Scaling factor for monitors at resolutions other than 2560x1440
        xScale := DbdWidth / 2560
        yScale := DbdHeight / 1440

        lastCheck := A_TickCount
    }
}

isSettingsOpen() {
    ; 'E' of MATCH DETAILS (1999, 100)
    ; ']' of ESC: (295, 1350)
    global settingsWhiteishMatchDetailsE := getColor(1999, 100)

    ; Red arrow `<` of back button to add further specificity
    global settingsRedishBackArrow := getColor(133, 1350)

    return isWhiteish(settingsWhiteishMatchDetailsE) && isRedish(settingsRedishBackArrow)
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
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    thres := 0xD0
    isBrightish := r > thres && g > thres && b > thres

    return isBrightish
}

isRedish(color) {
    r := ((color >> 16) & 0xFF) / 255.0
    g := ((color >> 8) & 0xFF) / 255.0
    b := (color & 0xFF) / 255.0

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
    return hue <= 20 || hue >= 340
}

getColor(x, y) {
    detectDbdWindowScale()
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    PixelGetColor, color, scaledX, scaledY, RGB

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
    OutputDebug, %msg% ; view with https://learn.microsoft.com/en-us/sysinternals/downloads/debugview
}

info(msg) {
    ; Uncomment while developing:
    OutputDebug, %msg% ; view with https://learn.microsoft.com/en-us/sysinternals/downloads/debugview
}

doNothing() {
    ; used as a noop for doWithRetriesUntil(action, predicate)
}
