/*
Bloodweb autospender using the speed tech from:
https://www.reddit.com/r/deadbydaylight/s/njguTZBODp
*/
#SingleInstance Force
#Persistent
#IfWinActive DeadByDaylight
#NoEnv
SetMouseDelay, -1 ; Make cursor move instantly rather than mimicking user behavior

if (FileExist("icons/autopurchase.ico"))
    Menu, Tray, Icon, icons/autopurchase.ico

global clickHoldTime := 50
global prevLevel := -1

; Start the clicking
~F6::
    MouseMove, 910, 755
    ToolTip, Autospending... (wiggle mouse to disable)
    SetTimer, CheckPixels, 100
Return

; Stop the clicking
~F7::
    disable()
Return

disable() {
    ToolTip
    SetTimer,, Off
}

CheckPixels:
{
    ; Stop if the user tabs out or moves the mouse
    MouseGetPos, mouseX, mouseY
    mouseMoved := mouseX != 910 || mouseY != 755
    if (!WinActive("DeadByDaylight") || mouseMoved = true) {
        disable()
        return
    }

    level := getBloodwebLevel()

    if (level != prevLevel && level != expectedNextLevel()) {
        ; Wait, really? Maybe we split reads across two frames.
        ; Hopefully trying again fixes it.
        Sleep, 100
        level := getBloodwebLevel()
    }

    OutputDebug, level=%level%

    if (level != -1 && prevLevel != level) {
        cycleBloodweb()
        Sleep, 100
        prevLevel := level
    }

    ; Click autopurchase.
    scaledClick(910, 755, "down") ; autopurchase
    Sleep, clickHoldTime
    scaledClick(910, 755, "up") ; autopurchase

    return
}

cycleBloodweb() {
    scaledClick(201, 459) ; bloodweb tab
    Sleep, 100
    scaledClick(201, 459) ; bloodweb tab
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

expectedNextLevel() {
    if (prevLevel = 50)
        return 1
    return prevLevel + 1
}

getBloodwebLevel() {
    ; Decision-tree OCR.
    ; Highly efficient. Questionably reliable.
    ; Returns -1 if no level is present.
    ; TODO: Probably thinks a pure white screen is a digit.

    ; Level is left aligned, so the tens digit houses levels 0-9
    digit1 := isLit(820, 141) ? (isLit(814, 139) ? (isLit(816, 148) ? (isLit(825, 134) ? (9) : (-1)) : (isLit(822, 147) ? (4) : (-1))) : (isLit(827, 149) ? (isLit(825, 149) ? (2) : (-1)) : (isLit(827, 127) ? (isLit(822, 136) ? (7) : (-1)) : (isLit(821, 148) ? (1) : (-1))))) : (isLit(826, 133) ? (isLit(820, 137) ? (isLit(814, 140) ? (isLit(822, 147) ? (8) : (-1)) : (isLit(823, 140) ? (3) : (-1))) : (isLit(824, 133) ? (0) : (-1))) : (isLit(826, 127) ? (isLit(818, 137) ? (5) : (-1)) : (isLit(819, 136) ? (6) : (-1))))
    digit10 := isLit(802, 141) ? (isLit(796, 139) ? (isLit(798, 148) ? (isLit(807, 134) ? (9) : (-1)) : (isLit(804, 147) ? (4) : (-1))) : (isLit(809, 149) ? (isLit(807, 149) ? (2) : (-1)) : (isLit(809, 127) ? (isLit(804, 136) ? (7) : (-1)) : (isLit(803, 148) ? (1) : (-1))))) : (isLit(808, 133) ? (isLit(802, 137) ? (isLit(796, 140) ? (isLit(804, 147) ? (8) : (-1)) : (isLit(805, 140) ? (3) : (-1))) : (isLit(806, 133) ? (0) : (-1))) : (isLit(808, 127) ? (isLit(800, 137) ? (5) : (-1)) : (isLit(801, 136) ? (6) : (-1))))

    if (digit10 = -1)
        return -1
    if (digit1 = -1)
        return digit10
    return digit10 * 10 + digit1
}

isLit(x, y) {
    ; Check if the pixel is plausibly text in the bloodweb.
    color := getColor(x, y)

    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    hsl := RGBtoHSL(r, g, b)

    s := hsl[2]
    l := hsl[3]

    isBright := l >= 0xC9/0xFF ; 0xCB is the darkest value I've seen so far.
    isDesaturated := s < 0.01

    OutputDebug, (%x%, %y%)=%color%
    return isBright && isDesaturated
}

getColor(x, y) {
    WinGetPos, winX, winY, DbdWidth, DbdHeight, DeadByDaylight

    ; Scaling factor for monitors at resolutions other than 2560x1440
    xScale := DbdWidth / 2560
    yScale := DbdHeight / 1440

    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    PixelGetColor, color, scaledX, scaledY, RGB

    return color
}

scaledClick(x, y, options := "") {
    WinGetPos, winX, winY, DbdWidth, DbdHeight, DeadByDaylight

    ; Scaling factor for monitors at resolutions other than 2560x1440
    xScale := DbdWidth / 2560
    yScale := DbdHeight / 1440

    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    BlockInput, MouseMove  ; Block mouse movement
    Click, %scaledX% %scaledY% %options%
    BlockInput, MouseMoveOff  ; Re-enable mouse movement
}


log(msg) {
    ; Uncomment while developing:
    OutputDebug, %msg% ; view with https://learn.microsoft.com/en-us/sysinternals/downloads/debugview
}
