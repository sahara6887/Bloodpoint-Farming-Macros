/*
Bloodweb autospender using the speed tech from:
https://www.reddit.com/r/deadbydaylight/s/njguTZBODp
*/
#Requires AutoHotkey v2.0
#SingleInstance
#HotIf WinActive("DeadByDaylight")
#Include Lib\scaling.ahk
#Include Lib\colors.ahk

SetMouseDelay(-1) ; Make cursor move instantly rather than mimicking user behavior
CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")

if (FileExist("icons/autopurchase.ico"))
    TraySetIcon("icons/autopurchase.ico")

spender := Autospender()

; Start spending
~F6:: {
    spender.startSpending()
}

~^+F6:: {
    ; Debug stub to check level-detection without actually spending
    spender.reliablyGetBloodwebLevel()
}

class Autospender {
    prevLevel := -1

    __New(ops := BaseOps()) {
        this.ops := ops
        this.scaled := ScaledOps(ops)
        this.scaled.enabled := false
    }

    startSpending() {
        ; if this.scaled.enabled
        ;     return
        this.scaled.enabled := true
        OutputDebug("Started spending")

        level := this.getBloodwebLevel()
        if (level = -1) {
            this.ops.click(201, 459) ; bloodweb tab
            Sleep(100)
        }

        this.scaled.mouseMove(910, 755)
        ToolTip("Autospending... (wiggle mouse to disable)")
        SetTimer(this.CheckPixels.Bind(this), 100)
    }

    disable() {
        ; if !this.scaled.enabled
        ;     return
        this.scaled.enabled := false
        OutputDebug("Stopped spending")
        ToolTip()
        SetTimer(this.CheckPixels.Bind(this), 0)

        MouseGetPos(&oldX, &oldY)

        level := this.getBloodwebLevel()
        if (level = 10 or level > 11) {
            ; Interrupt autopurchase
            Sleep(100)
            this.ops.click(201, 143) ; character tab to cancel the autospending
            Sleep(100)
            this.ops.click(201, 459) ; bloodweb tab
            Sleep(100)
            this.ops.mouseMove(oldX, oldY)
        }
    }

    CheckPixels() {
        ; Stop if the user tabs out or moves the mouse
        MouseGetPos(&mouseX, &mouseY)
        mouseMoved := mouseX != this.scaled.scaleX(910) || mouseY != this.scaled.scaleY(755)
        if (!WinActive("DeadByDaylight") || mouseMoved = true) {
            this.disable()
            return
        }

        level := this.reliablyGetBloodwebLevel()

        if (level != -1 && this.prevLevel != level) {
            this.cycleBloodweb()
            Sleep(100)
            this.prevLevel := level
        }

        this.clickAutoPurchase()
    }

    cycleBloodweb() {
        ; Closing and opening the bloodweb skips the "level" interstitial
        this.scaled.click(201, 459) ; bloodweb tab
        Sleep(100)
        this.scaled.click(201, 459) ; bloodweb tab
    }

    clickAutoPurchase() {
        this.scaled.click(910, 755, "down") ; autopurchase
        Sleep(50) ; hold time is important
        this.scaled.click(910, 755, "up") ; autopurchase
    }

    expectedNextLevel() {
        if (this.prevLevel = 50)
            return 1
        return this.prevLevel + 1
    }

    reliablyGetBloodwebLevel() {
        level := this.getBloodwebLevel()

        expected := this.expectedNextLevel()
        if (level != -1 && level != this.prevLevel && level != expected) {
            OutputDebug("Surprise level! expected=" expected " actual=" level)
            ; Wait, really? Maybe we split reads across two frames.
            ; Hopefully trying again fixes it.
            Sleep(100)
            level := this.getBloodwebLevel()
        }

        OutputDebug("level=" level)

        return level
    }

    getBloodwebLevel() {
        ; Decision-tree OCR.
        ; Highly efficient. Zero dependencies. Questionably reliable.
        ; Returns -1 if no level is present.
        ; TODO: Probably thinks a pure white screen is a digit.

        if (dbd.height != 1080 && dbd.height != 1440) {
            ; UI elements move around at other resolutions. It's not going to work.
            return -1
        }

        isLit := this.isLit.Bind(this)

        OutputDebug("tens:")
        if (dbd.height = 1080) {
            digit10 := isLit(602, 102) ? (isLit(609, 100) ? (isLit(601, 108) ? (isLit(605, 104) ? (isLit(603, 97) ? (8) : (-1)) : (isLit(602, 103) ? (0) : (-1))) : (isLit(605, 104) ? (9) : (-1))) : (isLit(602, 96) ? (isLit(601, 109) ? (5) : (-1)) : (isLit(601, 104) ? (6) : (-1)))) : (isLit(610, 108) ? (isLit(601, 98) ? (isLit(603, 97) ? (3) : (-1)) : (isLit(608, 107) ? (4) : (-1))) : (isLit(610, 112) ? (isLit(603, 97) ? (2) : (-1)) : (isLit(600, 96) ? (isLit(603, 97) ? (7) : (-1)) : (isLit(605, 104) ? (1) : (-1)))))
        } else if (dbd.height = 1440) {
            digit10 := isLit(802, 141) ? (isLit(796, 139) ? (isLit(798, 148) ? (isLit(807, 134) ? (9) : (-1)) : (isLit(804, 147) ? (4) : (-1))) : (isLit(809, 149) ? (isLit(807, 149) ? (2) : (-1)) : (isLit(809, 127) ? (isLit(804, 136) ? (7) : (-1)) : (isLit(803, 148) ? (1) : (-1))))) : (isLit(808, 133) ? (isLit(802, 137) ? (isLit(796, 140) ? (isLit(804, 147) ? (8) : (-1)) : (isLit(805, 140) ? (3) : (-1))) : (isLit(806, 133) ? (0) : (-1))) : (isLit(808, 127) ? (isLit(800, 137) ? (5) : (-1)) : (isLit(801, 136) ? (6) : (-1))))
        }

        OutputDebug("ones:")
        if (dbd.height = 1080) {
            digit1 := isLit(616, 102) ? (isLit(623, 100) ? (isLit(615, 108) ? (isLit(619, 104) ? (isLit(617, 97) ? (8) : (-1)) : (isLit(616, 103) ? (0) : (-1))) : (isLit(619, 104) ? (9) : (-1))) : (isLit(616, 96) ? (isLit(615, 109) ? (5) : (-1)) : (isLit(615, 104) ? (6) : (-1)))) : (isLit(624, 108) ? (isLit(615, 98) ? (isLit(617, 97) ? (3) : (-1)) : (isLit(622, 107) ? (4) : (-1))) : (isLit(624, 112) ? (isLit(617, 97) ? (2) : (-1)) : (isLit(614, 96) ? (isLit(617, 97) ? (7) : (-1)) : (isLit(619, 104) ? (1) : (-1)))))
        } else if (dbd.height = 1440) {
            digit1 := isLit(820, 141) ? (isLit(814, 139) ? (isLit(816, 148) ? (isLit(825, 134) ? (9) : (-1)) : (isLit(822, 147) ? (4) : (-1))) : (isLit(827, 149) ? (isLit(825, 149) ? (2) : (-1)) : (isLit(827, 127) ? (isLit(822, 136) ? (7) : (-1)) : (isLit(821, 148) ? (1) : (-1))))) : (isLit(826, 133) ? (isLit(820, 137) ? (isLit(814, 140) ? (isLit(822, 147) ? (8) : (-1)) : (isLit(823, 140) ? (3) : (-1))) : (isLit(824, 133) ? (0) : (-1))) : (isLit(826, 127) ? (isLit(818, 137) ? (5) : (-1)) : (isLit(819, 136) ? (6) : (-1))))
        }

        OutputDebug("digit10=" digit10 " digit1=" digit1)

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
        color := this.ops.getColor(x, y) ; no scaling! coords are specific to 1080 or 1440.

        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        hsl := RGBtoHSL(r, g, b)

        s := hsl[2]
        l := hsl[3]

        isBright := l >= 0xA0 / 0xFF
        isDesaturated := s < 0.15

        OutputDebug "(" x ", " y ")=" color " isBright=" isBright " isDesaturated=" isDesaturated " s=" s

        return isBright && isDesaturated
    }
}
