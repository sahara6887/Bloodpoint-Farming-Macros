#SingleInstance Force
#Persistent
; This macro hooks a carried survivor whenever possible,
; adding years of life to your keyboard's spacebar.

global xScale, yScale

SetTimer, HookIfPossible, 100
SetTimer, detectDbdWindowScale, 1000
detectDbdWindowScale()
return

HookIfPossible:
    if (WinActive("DeadByDaylight")) {
        ; Head of the "carried survivor" icon.
        ; Chosen because it is not white in the same spot as the "Blight Rush" icon.
        global colorHead := getColor(228, 1253)

        ; White part of the 'A' of the "[SPACE] HANG" prompt.
        global colorSpaceA := getColor(1258, 1254)

        ; Black background of the "[SPACE] HANG" prompt to disqualify an all white screen.
        global colorSpaceBg := getColor(1280, 1254)

        if (colorHead = 0xFFFFFF && colorSpaceA = 0xFFFFFF && colorSpaceBg = 0x000000) {
            Send, {Space}
        }
    }
return

getColor(x, y) {
    scaledX := Round(x * xScale)
    scaledY := Round(y * yScale)

    PixelGetColor, color, scaledX, scaledY

    return color
}

; All pixel coordinates are relative to a 1440p screen.
; Detect a scaling factor for other resolutions such as 1080p.
; This should be tested periodically in case the resolution changes.
; Runtime of this function was measured at 0 ms, so it's effectively free.
detectDbdWindowScale() {
    WinGetPos, ignoredX, ignoredY, DbdWidth, DbdHeight, DeadByDaylight

    ; Scaling factor for monitors at resolutions other than 2560x1440
    xScale := DbdWidth / 2560
    yScale := DbdHeight / 1440
}
