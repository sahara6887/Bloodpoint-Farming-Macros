/*
Bloodweb autospender using the speed tech from:
https://www.reddit.com/r/deadbydaylight/s/njguTZBODp
*/
#Requires AutoHotkey v2.0
#SingleInstance
#HotIf WinActive("DeadByDaylight")
#Include Lib\common.ahk

setTrayIcon("icons/autopurchase.ico")

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
    enabled := false

    __New(ops := WindowOps()) {
        this.ops := ops
        this.scaled := DisableableWindowOps(ScaledOps(ops))
        this.timerFunc := this.CheckPixels.Bind(this)
    }

    startSpending() {
        if this.enabled
            return
        this.enabled := true
        info("Started spending")

        level := getBloodwebLevel()
        if (level = -1) {
            this.ops.click(201, 459) ; bloodweb tab
            Sleep(100)
        }

        this.scaled.mouseMove(910, 755)
        ToolTip("Autospending... (wiggle mouse to disable)")
    
        this.timer := SetTimer(this.timerFunc, 100)
    }

    disable() {
        if !this.enabled
            return
        this.enabled := false
        info("Stopped spending")
        ToolTip()
        SetTimer(this.timerFunc, 0)

        MouseGetPos(&oldX, &oldY)

        level := getBloodwebLevel()
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
        level := getBloodwebLevel()

        expected := this.expectedNextLevel()
        if (level != -1 && level != this.prevLevel && level != expected) {
            warn("Surprise level! expected=" expected " actual=" level)
            ; Wait, really? Maybe we split reads across two frames.
            ; Hopefully trying again fixes it.
            Sleep(100)
            level := getBloodwebLevel()
        }

        OutputDebug("level=" level)

        return level
    }
}
