#SingleInstance Force
#Persistent
#NoEnv
SetBatchLines, -1
SetTimer, CheckMatchStart, 500
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen

startTime := 0
running := false
barsWerePresent := false

screenWidth := A_ScreenWidth
screenHeight := A_ScreenHeight
barHeight := Round(screenHeight * 0.055)  ; ~5.5% of screen

; GUI Setup
Gui, +AlwaysOnTop -Caption +ToolWindow
Gui, Color, 1E1E1E
Gui, Font, s32 cFFFFFF, Consolas

; Add vertically centered timer display
; +0x200 = SS_CENTERIMAGE, centers text vertically within its control
Gui, Add, Text, vTimerDisplay x0 y0 w300 h90 Center BackgroundTrans +0x200 gDragWindow, 0:00

Gui, Show, x10 y10 w300 h90 NoActivate, DBD Stopwatch
SetTimer, UpdateTimer, 1000
Return

CheckMatchStart:
{
    PixelGetColor, topBarColor, % screenWidth // 2, % barHeight // 2, RGB
    PixelGetColor, bottomBarColor, % screenWidth // 2, % (screenHeight - barHeight // 2), RGB

    centerX := screenWidth // 2
    centerY := screenHeight // 2
    PixelGetColor, centerColor, %centerX%, %centerY%, RGB

    PixelGetColor, leftCenterColor, 0, %centerY%, RGB
    PixelGetColor, rightCenterColor, % (screenWidth - 1), %centerY%, RGB

    if (!barsWerePresent
        && topBarColor = 0x000000
        && bottomBarColor = 0x000000
        && centerColor != 0x000000
        && (leftCenterColor != 0x000000 || rightCenterColor != 0x000000)) {

        barsWerePresent := true
        Return
    }

    if (barsWerePresent
        && topBarColor != 0x000000
        && bottomBarColor != 0x000000
        && centerColor != 0x000000) {

        startTime := A_TickCount
        running := true
        barsWerePresent := false
    }
}
Return


UpdateTimer:
if (running) {
    elapsed := (A_TickCount - startTime) // 1000
    minutes := elapsed // 60
    seconds := Mod(elapsed, 60)
    formattedTime := minutes ":" SubStr("0" seconds, -1)
    GuiControl,, TimerDisplay, %formattedTime%
}
Return


; Make whole window draggable
DragWindow:
PostMessage, 0xA1, 2,,, A
Return

GuiClose:
ExitApp
