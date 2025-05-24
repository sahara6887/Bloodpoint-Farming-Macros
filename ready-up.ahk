#Requires AutoHotkey v2+
#Include Lib/common.ahk

/**
 * Clicks the ready button as soon as it becomes visible.
 * Disables for 60 seconds if the user manually unreadies.
 * Re-enables if the user readies up again.
 */
SetTimer(CheckReadyButton, 1000)
setTrayIcon("icons/ready.ico")

pausedAt := 0

CheckReadyButton() {
    if (!dbdWindow.isActive())
        return

    if (!isPaused() and isReadyButtonVisible() and !isReadiedUp()) {
        readyUp()
    }
}

readyUp() {
    if (!dbdWindow.isActive())
        return

    logger.info("Readying up")

    ; Capture the initial mouse position
    MouseGetPos(&initialX, &initialY)

    BlockInput("MouseMove")
    coords.mouseMove(readyButtonWhiteR)
    Sleep(20)
    Click("down, Left")
    Sleep(50)
    Click("up, Left")
    Sleep(20)
    BlockInput("MouseMoveOff")

    ; Move mouse back to initial position
    MouseMove(initialX, initialY, 0)
}

~LButton::
{   
    ; Disable for 60 seconds if the user unreadies.
    ; Re-enable if the user readies up again.
    if (isMouseInReadyButtonRegion()) {
        ; Wait for status to change
        Sleep(200)

        if (isReadiedUp()) {
            unpause()
        } else {
            pause()
        }
    }
}

isMouseInReadyButtonRegion() {
    MouseGetPos(&mx, &my)
    result := mx >= scaled.scaleX(2068) && mx <= scaled.scaleX(2445) && my >= scaled.scaleY(1213) && scaled.scaleY(my) <= 1301
    logger.debug("isMouseInReadyButtonRegion(" mx ", " my ") => " result)
    return result
}

isPaused() => A_TickCount - pausedAt < 60000

unpause() {
    global pausedAt
    pausedAt := 0
}

pause() {
    global pausedAt
    pausedAt := A_TickCount
}
