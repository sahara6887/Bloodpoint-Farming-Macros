#Requires AutoHotkey v2.0

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

dbd := DbdWindow()

class DbdWindow {
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
class BaseOps {
    click(x, y, options := "") {
        BlockInput("MouseMove")  ; Block mouse movement
        Click(x " " y " " options)
        BlockInput("MouseMoveOff")  ; Re-enable mouse movement
    }

    mouseMove(x, y) => MouseMove(x, y)
    getColor(x, y) => PixelGetColor(x, y)
}

/**
 * Scales the coordinates of the operations to the current window size.
 */
class ScaledOps extends BaseOps {
    /**
     * Whether actions are taken or ignored completely.
     * AHK doesn't support hard interruption of a sequence of actions, so it must be done cooperatively.
     * It's more convenient to have all actions check a flag than to replicate the check everywhere.
     */
    enabled := true

    __New(ops, baseWidth := 2560, baseHeight := 1440) {
        this.ops := ops
        this.baseWidth := baseWidth
        this.baseHeight := baseHeight
    }

    scaleX(x) => Round(x * dbd.width / this.baseWidth)
    scaleY(y) => Round(y * dbd.height / this.baseHeight)

    click(x, y, options := "") {
        if !this.enabled
            return
        scaledX := this.scaleX(x)
        scaledY := this.scaleY(y)

        OutputDebug("scaled.click(" x "=>" scaledX ", " y "=>" scaledY ")")
        return this.ops.click(scaledX, scaledY, options)
    }

    getColor(x, y) {
        scaledX := this.scaleX(x)
        scaledY := this.scaleY(y)

        color := this.ops.getColor(scaledX, scaledY)

        OutputDebug("getColor(" x ", " y ") => (" scaledX ", " scaledY ")=" color)

        return color
    }

    mouseMove(x, y) {
        if !this.enabled
            return

        scaledX := this.scaleX(x)
        scaledY := this.scaleY(y)

        this.ops.mouseMove(scaledX, scaledY)
    }
}
