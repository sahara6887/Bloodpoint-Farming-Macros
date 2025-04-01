#SingleInstance Force
#Persistent
#IfWinActive DeadByDaylight
WinGetPos, ignoredX, ignoredY, DbdWidth, DbdHeight, DeadByDaylight

; Scaling factor for monitors at resolutions other than 2560x1440
xScale := DbdWidth / 2560
yScale := DbdHeight / 1440

CoordMode, Pixel, Window

SetMouseDelay, -1 ; Make cursor move instantly rather than mimicking user behavior

; Set 30 FPS (Ctrl-)
F3::
{
    openGraphicsSettings()

    ; 30 FPS option
    scaledClick(1760, 778)

    closeSettings()
}
return

; Set 120 FPS (Ctrl+)
F4::
{
    openGraphicsSettings()

    ; 120 FPS option
    scaledClick(1778, 1084)

    closeSettings()
}
return

openGraphicsSettings() {
    ; Open Settings
    Send, {ESC}

    ; Sometimes the game lags with black screen when opening menu first time.
    ; Wait for the screen to open.
    ; Note that the [ ESC ] button looks pure white, but is slightly off white!
    ; waitUntilColor(1999, 100, 0xFFFFFF) ; 'E' of MATCH DETAILS
    Sleep, 300

    ; Select "Graphics" tab
    scaledClick(988, 94)
    ; waitUntilColor(950, 100, 0xFFFFFF) ; 'R' of 'GRAPHICS'
    Sleep, 50

    ; Open FPS dropdown
    scaledClick(1350, 938)
    ; The text strokes of the FPS options are thin. Hard to find a pure white pixel.
    ; We'll just sleep here instead of pixel matching since this menu seems performant enough.
    Sleep, 50
}

closeSettings() {
    Send, {ESC}
}

waitUntilColor(x, y, expectedColor) {
    global xScale, yScale
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    ; ToolTip ; Uncomment for debugging
    ; Looping 200 times is roughly 2 seconds on my PC -- long enough.
    Sleep, 200
    Loop, 200
    {
        PixelGetColor, color, scaledX, scaledY
        if (color = expectedColor)
        {
            return
        }
    }
    ; ToolTip, (%x% %y%) * %xScale% = ( %scaledX%  %scaledY% ) %color% != %expectedColor% ; Uncomment for debugging
    Exit
}

scaledClick(x, y) {
    global xScale, yScale

    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    Click, %scaledX%, %scaledY%
}
