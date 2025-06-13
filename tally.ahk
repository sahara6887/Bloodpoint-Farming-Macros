#Requires AutoHotkey v2+

#Include Lib\common.ahk
#Include Lib\Gdip_All.ahk

/**
 * Captures the tabs of the Tally screen as a single screenshot.
 */

config := {
    ; Click the continue button?
    continue: false,
    ; How long to wait before clicking continue? User can wiggle to cancel.
    continueGracePeriodMs: 3000,
    ; How often to check? Responsiveness vs load.
    timerPollIntervalMs: 500,
    ; How long until we start checking again after hitting continue?
    timerRestartMs: 120000,
    ; What info should we capture in the screenshot?
    capture: {
        ; "Which category did I miss?"
        bloodpoints: true,
        ; "Did everyone max? Correct right perks?"
        ; Capturing Bloodpoints and Scoreboard together takes ~1.3 seconds.
        scoreboard: true,
        ; "Match time?"
        ; Adds ~1.6 seconds.
        ; Fairly slow, but enabled by default since it's useful to track match times.
        ; Killer times should be considered authoritative.
        ; Survivors may escape LONG before the match ends, which doesn't matter since they still have to wait for the killer to requeue.
        xp: true,
        ; "Does this build pip?" Unimportant for BP farming, so disabled by default.
        ; Useful for analyzing builds.
        ; Adds 700 ms.
        emblems: false,
    },
    ; How should screenshots be stored?
    screenshot: {
        ; Where to store the screenshots?
        dir: EnvGet("USERPROFILE") "\Pictures\dbd-matches",
        ; How many screenshots to retain? They're ~295 KB each at 1440p. Aim for < 100 MB.
        limit: 300,
    },
}

Gdip_Startup()

startTimer()

; Hotkey stub for testing
~^+!F3:: CheckTallyScreen() ; Ctrl + Shift + Alt + F3

CheckTallyScreen() {
    global config
    if !WinActive("DeadByDaylight")
        return

    if isTallyScreen() {
        captureImages()
        SetTimer(deleteOldestScreenshots, -100, Priority := -1) ; off the critical path

        if (config.continue)
            clickContinueWithDelay()

        queueTimerRestart()
    }
}

startTimer() {
    global config
    if isTallyScreen() {
        ; Don't take more screenshots if we're still in Tally.
        logger.info("Tally screen still visible.")
        queueTimerRestart()
    } else {
        SetTimer(CheckTallyScreen, config.timerPollIntervalMs)
        logger.info("Watching for Tally screen...")
    }
}

queueTimerRestart() {
    SetTimer(CheckTallyScreen, 0) ; cancel timer
    SetTimer(startTimer, -config.timerRestartMs) ; delay restarting the timer
    logger.info("Paused watching Tally screen for " config.timerRestartMs " ms")
}

captureImages() {
    global tabIndex, config
    width := 1097
    matchXp := 0, scoreTop := 0, scoreBottom := 0, scoreboard := 0, emblems := 0, emblemsGradeProgress := 0, scoreMatchTotal := 0
    captureStartTime := A_TickCount

    ; We start on the Score tab.
    global tabIndex := 0

    logger.info("Capturing tally screen...")

    ; Scoreboard
    if config.capture.scoreboard {
        switchToTab(-1)
        Sleep 350
        scoreboard := screenshot(76, 362, width, 772)
    }

    ; Match XP / Player Level
    if config.capture.xp {
        switchToTab(-2)
        Sleep 1500 ; 87 frames@60fps from click to Match XP (1.45 seconds)
        matchXp := screenshot(76, 918, width, 68)
    }

    ; Score
    if config.capture.bloodpoints {
        switchToTab(0)
        waitUntil("isTallyBloodpointsScreen", 1500)
        scoreTop := screenshot(50, 301, width, 18, padding := 10)
        scoreBottom := screenshot(50, 541, width, 29, padding := 10)
        scoreMatchTotal := screenshot(50, 627, width, 82, padding := 10)
    }

    ; Emblems
    if config.capture.emblems {
        switchToTab(1)
        switchToTab(0)
        switchToTab(1)
        Sleep 450
        ; Slice through the middle since they're so large
        emblems := screenshot(76, 369, width, 117)
        emblemsGradeProgress := screenshot(76, 566, width, 18, padding := 5)
    }

    logger.info("Capture took " A_TickCount - captureStartTime " ms.")

    switchToTab(-1) ; Display all scores while we wait.

    ; Composite images vertically
    images := [emblems, emblemsGradeProgress, matchXp, scoreTop, scoreBottom, scoreboard, scoreMatchTotal]

    totalWidth := scaled.scaleX(width)
    totalHeight := 0
    for img in images {
        if (img = 0)
            continue
        totalHeight += Gdip_GetImageHeight(img)
    }

    composite := Gdip_CreateBitmap(totalWidth, totalHeight)
    g := Gdip_GraphicsFromImage(composite)

    yOffset := 0
    for img in images {
        if (img = 0)
            continue
        Gdip_DrawImage(g, img, 0, yOffset, Gdip_GetImageWidth(img), Gdip_GetImageHeight(img))
        yOffset += Gdip_GetImageHeight(img)
        Gdip_DisposeImage(img)
    }

    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH-mm-ss")
    dir := EnvGet("USERPROFILE") "\Pictures\dbd-matches"
    if !DirExist(dir)
        DirCreate(dir)

    filename := dir "\" timestamp ".jpg"
    Gdip_SaveBitmapToFile(composite, filename)
    Gdip_DeleteGraphics(g)
    Gdip_DisposeImage(composite)
}

/**
 * Scales the coords to the current window size and captures a screenshot.
 */
screenshot(x, y, w, h, padding := 0) {
    ; Apply padding
    h := h + padding * 2
    y -= padding

    ; Apply scaling
    x := scaled.scaleX(x)
    y := scaled.scaleY(y)
    w := scaled.scaleX(w)
    h := scaled.scaleY(h)

    hwnd := WinExist("DeadByDaylight")
    ; There is no Gdip function to capture a window, so
    ; we have to find the window client area relative to the screen.
    pt := Buffer(8, 0)
    DllCall("ClientToScreen", "ptr", hwnd, "ptr", pt)
    wx := NumGet(pt, 0, "int")
    wy := NumGet(pt, 4, "int")
    return Gdip_BitmapFromScreen(wx + x "|" wy + y "|" w "|" h)
}

/**
 * Switches to a tab in the tally screen.
 * Player score is tab 0. Left of that is tab -1. Right is 1.
 */
switchToTab(dest) {
    global tabIndex

    logger.debug("switchToTab " dest)

    while tabIndex != dest {
        thisArrow := tabIndex > dest ? tallyLeftArrowWhite : tallyRightArrowWhite
        clickTabArrow(thisArrow)

        ; Update state
        tabIndex := tabIndex + (tabIndex > dest ? -1 : 1)
        lastAction := A_TickCount
    }
}

clickTabArrow(xy) {
    static lastClick := A_TickCount
    elapsed := A_TickCount - lastClick
    minActionDurationMs := 20

    ; If this function is called multiple times in a row,
    ; ensure there's ample time between the previous click and our first.
    if A_TickCount - lastClick < 20 {
        ; DBD seems to have some debounce per button
        ; Ensure we've waited enough time before repeating the click
        Sleep minActionDurationMs - elapsed
    }

    ; DBD debounces when you click the same arrow twice in a row in a short period.
    ; We can get around this by clicking on a blank region first.
    coords.click(Coords2K(xy.x, xy.y + 50))
    Sleep 40
    coords.click(xy)
    lastClick := A_TickCount
}

/**
 * Clicks the CONTINUE button after a short delay.
 * Cancels the click if the users moves the mouse during the delay.
 */
clickContinueWithDelay() {
    global config
    coords.mouseMove(tallyContinueButtonRed)
    MouseGetPos(&oldX, &oldY)
    ToolTip "Clicking CONTINUE... Wiggle to cancel."
    Sleep config.continueGracePeriodMs
    MouseGetPos(&newX, &newY)
    if (oldX = newX and oldY = newY) {
        coords.click(tallyContinueButtonRed)
    }
    ToolTip
}

deleteOldestScreenshots() {
    global config

    ; Map is sorted: https://www.reddit.com/r/AutoHotkey/comments/qkxaog/small_hacks_to_sort_associative_array_by_integers/
    fileMap := Map()
    loop files config.screenshot.dir "\*.jpg"
        fileMap[A_LoopFileTimeModified] := A_LoopFileFullPath

    i := 1
    excess := fileMap.Count - config.screenshot.limit
    for time, name in fileMap {
        if i > excess
            break

        try {
            logger.info("Deleting old screenshot: " name)
            FileDelete name
        }
        catch Error as e
            logger.warn("Failed to delete file: " name " - " e.Message)
        i++
    }
}
