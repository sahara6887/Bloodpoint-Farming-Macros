/*
Bloodweb autospender using the speed tech from:
https://www.reddit.com/r/deadbydaylight/s/njguTZBODp
*/
#SingleInstance Force
#Persistent
#IfWinActive DeadByDaylight
#NoEnv
SetMouseDelay, -1 ; Make cursor move instantly rather than mimicking user behavior
CoordMode, Mouse, Client
CoordMode, Pixel, Client

if (FileExist("icons/autopurchase.ico"))
    Menu, Tray, Icon, icons/autopurchase.ico

global clickHoldTime := 50
global prevLevel := -1

; Start the clicking
~F6::
    scaledMouseMove(910, 755)
    ToolTip, Autospending... (wiggle mouse to disable)
    SetTimer, CheckPixels, 100
Return

; Stop the clicking
~F7::
    disable()
Return


JustCheckLevel:
    level := reliablyGetBloodwebLevel()
    OutputDebug, level=%level%
Return


disable() {
    ToolTip
    SetTimer,, Off
}

scaledMouseMove(x, y) {
    checkScale()
    scaledX := scaleX(x)
    scaledY := scaleY(y)
    MouseMove, scaledX, scaledY
}

CheckPixels:
{
    ; Stop if the user tabs out or moves the mouse
    MouseGetPos, mouseX, mouseY
    mouseMoved := mouseX != scaleX(910) || mouseY != scaleY(755)
    if (!WinActive("DeadByDaylight") || mouseMoved = true) {
        disable()
        return
    }

    level := reliablyGetBloodwebLevel()

    if (level != -1 && prevLevel != level) {
        cycleBloodweb()
        Sleep, 100
        prevLevel := level
    }

    clickAutoPurchase()

    return
}

cycleBloodweb() {
    ; Closing and opening the bloodweb skips the "level" interstitial
    scaledClick(201, 459) ; bloodweb tab
    Sleep, 100
    scaledClick(201, 459) ; bloodweb tab
}

clickAutoPurchase() {
    ; Click autopurchase.
    scaledClick(910, 755, "down") ; autopurchase
    Sleep, clickHoldTime
    scaledClick(910, 755, "up") ; autopurchase
}

expectedNextLevel() {
    if (prevLevel = 50)
        return 1
    return prevLevel + 1
}

reliablyGetBloodwebLevel() {
    level := getBloodwebLevel()

    if (level != -1 && level != prevLevel && level != expectedNextLevel()) {
        ; Wait, really? Maybe we split reads across two frames.
        ; Hopefully trying again fixes it.
        Sleep, 100
        level := getBloodwebLevel()
    }

    OutputDebug, level=%level%

    return level
}

getBloodwebLevel() {
    ; Decision-tree OCR.
    ; Highly efficient. Zero dependencies. Questionably reliable.
    ; Returns -1 if no level is present.
    ; TODO: Probably thinks a pure white screen is a digit.

    OutputDebug, ones:
    digit1 := isLit(616, 102) ? (isLit(623, 100) ? (isLit(615, 108) ? (isLit(619, 104) ? (isLit(617, 97) ? (8) : (-1)) : (isLit(616, 103) ? (0) : (-1))) : (isLit(619, 104) ? (9) : (-1))) : (isLit(616, 96) ? (isLit(615, 109) ? (5) : (-1)) : (isLit(615, 104) ? (6) : (-1)))) : (isLit(624, 108) ? (isLit(615, 98) ? (isLit(617, 97) ? (3) : (-1)) : (isLit(622, 107) ? (4) : (-1))) : (isLit(624, 112) ? (isLit(617, 97) ? (2) : (-1)) : (isLit(614, 96) ? (isLit(617, 97) ? (7) : (-1)) : (isLit(619, 104) ? (1) : (-1)))))
    OutputDebug, tens:
    digit10 := isLit(602, 102) ? (isLit(609, 100) ? (isLit(601, 108) ? (isLit(605, 104) ? (isLit(603, 97) ? (8) : (-1)) : (isLit(602, 103) ? (0) : (-1))) : (isLit(605, 104) ? (9) : (-1))) : (isLit(602, 96) ? (isLit(601, 109) ? (5) : (-1)) : (isLit(601, 104) ? (6) : (-1)))) : (isLit(610, 108) ? (isLit(601, 98) ? (isLit(603, 97) ? (3) : (-1)) : (isLit(608, 107) ? (4) : (-1))) : (isLit(610, 112) ? (isLit(603, 97) ? (2) : (-1)) : (isLit(600, 96) ? (isLit(603, 97) ? (7) : (-1)) : (isLit(605, 104) ? (1) : (-1)))))
    OutputDebug, digit1=%digit1% digit10=%digit1%

    ; Bloodweb level is left-aligned, so the tens digit actually houses levels 0-9 and the ones digit is empty.
    ; If tens digit is missing, then it's not a valid bloodweb level.
    if (digit10 = -1)
        return -1
    if (digit1 = -1)
        return digit10
    return digit10 * 10 + digit1
}

isLit(x, y) {
    ; Check if the pixel is plausibly text in the bloodweb.
    color := getColor(x, y, scale := false) ; hacked in 1080 coords

    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    hsl := RGBtoHSL(r, g, b)

    s := hsl[2]
    l := hsl[3]

    isBright := l >= 0xC9/0xFF ; 0xCB is the darkest value I've seen so far.
    isDesaturated := s < 0.01

    ; OutputDebug, (%x%, %y%)=%color%
    return isBright && isDesaturated
}

global xScale, yScale
checkScale() {
    static lastCheck := 0

    if (A_TickCount - lastCheck > 1000) {
        WinGetPos, winX, winY, DbdWidth, DbdHeight, DeadByDaylight

        ; Scaling factor for monitors at resolutions other than 2560x1440
        xScale := DbdWidth / 2560
        yScale := DbdHeight / 1440

        lastCheck := A_TickCount
    }
}

scaleX(x) {
    checkScale()
    return Round(x * xScale)
}

scaleY(y) {
    checkScale()
    return Round(y * yScale)
}

getColor(x, y, scale := true) {
    checkScale()

    scaledX := scale ? scaleX(x) : x
    scaledY := scale ? scaleY(y) : y

    PixelGetColor, color, scaledX, scaledY, RGB

    OutputDebug, getColor(%x%, %y%) => (%scaledX%, %scaledY%)=%color%

    return color
}


RGBtoHSL(r, g, b) {
    r := r / 255.0, g := g / 255.0, b := b / 255.0

    max := Max(r, g, b), min := Min(r, g, b)
    l := (max + min) / 2

    if (max = min)
        return [0, 0, l]

    d := max - min
    s := l > 0.5 ? d / (2 - max - min) : d / (max + min)
    h := (max = r) ? ((g - b) / d + (g < b ? 6 : 0)) :
         (max = g) ? ((b - r) / d + 2) : ((r - g) / d + 4)

    return [h / 6, s, l]
}

scaledClick(x, y, options := "") {
    checkScale()
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    OutputDebug, scaledClick(%x%=>%scaledX%, ...)
    BlockInput, MouseMove  ; Block mouse movement
    Click, %scaledX% %scaledY% %options%
    BlockInput, MouseMoveOff  ; Re-enable mouse movement
}
