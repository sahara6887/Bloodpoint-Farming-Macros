#Requires AutoHotkey v2+

#Include logging.ahk
#Include decorator.ahk

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

dbdWindow := DbdWindowOps()
ops := WindowOps()
scaled := ScaledOps(ops)

class DbdWindowOps {
    checkScale() {
        static lastCheck := 0

        if (A_TickCount - lastCheck > 1000) {
            ; WinGetPos, winX, winY, DbdWidth, DbdHeight, DeadByDaylight
            ; WinGetPos does not return the client area height while windowed, regardless of CoordMode, Client.
            hwnd := WinGetID("DeadByDaylight")
            rect := Buffer(16, 0)
            DllCall("GetClientRect", "ptr", hwnd, "ptr", rect.Ptr)

            this._width := NumGet(rect, 8, "Int")
            this._height := NumGet(rect, 12, "Int")

            lastCheck := A_TickCount
        }
    }
    width => (this.checkScale(), this._width)
    height => (this.checkScale(), this._height)
}

/**
 * Wrapper around default operations so we can DI fakes for testing.
 */
class WindowOps {
    click(x, y, options := "") {
        BlockInput("MouseMove")  ; Block mouse movement
        Click(x " " y " " options)
        BlockInput("MouseMoveOff")  ; Re-enable mouse movement
    }

    mouseMove(x, y) => MouseMove(x, y)
    getColor(x, y) => (PixelGetColor(x, y) & 0xFFFFFF)
}

/**
 * Controls whether actions are taken or ignored completely.
 * AHK doesn't support hard interruption of a sequence of actions, so it must be done cooperatively.
 * It's more convenient to have all actions check a flag than to replicate the check everywhere.
 */
class DisableableWindowOps extends Decorator {
    enabled := false

    mouseMove(x, y) {
        if this.enabled
            return this.underlying.mouseMove(x, y)
    }
    click(x, y, options := "") {
        if this.enabled
            return this.underlying.click(x, y, options)
    }
}

/**
 * Scales the coordinates of the operations to the current window size.
 */
class ScaledOps extends Decorator {
    baseWidth := 2560
    baseHeight := 1440
    
    __New(underlying := WindowOps(), baseWidth := 2560, baseHeight := 1440) {
        super.__New(underlying)
        this.baseWidth := baseWidth
        this.baseHeight := baseHeight
    }

    scaleX(x) => Round(x * dbdWindow.width / this.baseWidth)
    scaleY(y) => Round(y * dbdWindow.height / this.baseHeight)

    click(x, y, options := "") {
        scaledX := this.scaleX(x)
        scaledY := this.scaleY(y)

        logger.trace("scaled.click(" x "=>" scaledX ", " y "=>" scaledY ") " options)
        return this.underlying.click(scaledX, scaledY, options)
    }

    getColor(x, y) {
        scaledX := this.scaleX(x)
        scaledY := this.scaleY(y)

        color := this.underlying.getColor(scaledX, scaledY)

        logger.trace("getColor(" x ", " y ") => (" scaledX ", " scaledY ")=0x" Format("{:06X}", color))

        return color
    }

    mouseMove(x, y) {
        scaledX := this.scaleX(x)
        scaledY := this.scaleY(y)

        this.underlying.mouseMove(scaledX, scaledY)
    }
}
