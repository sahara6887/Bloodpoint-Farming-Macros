#Include Yunit\Yunit.ahk
#Include Yunit\Window.ahk
#Include Yunit\StdOut.ahk
#Include Yunit\JUnit.ahk
#Include Yunit\OutputDebug.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\Gdip_All.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk

logger := TestLogger()

; Yunit.Use(YunitWindow, YunitJUnit, YunitOutputDebug, YunitStdOut).Test(AutospenderTests)
Yunit.Use(YunitJUnit, YunitOutputDebug, YunitStdOut).Test(AutospenderTests)

class AutospenderTests {
    __New() {
        this.pToken := Gdip_Startup()
    }

    __Delete() {
        Gdip_Shutdown(this.pToken)
    }

    testBloodweb1440Level49() => assertBloodwebLevel(49, A_ScriptDir "\screenshots\bloodweb\bloodweb_1440_level49.png")
    testBloodweb1440Level49Reshade() => assertBloodwebLevel(49, A_ScriptDir "\screenshots\bloodweb\bloodweb_1440_level49_reshade.png")
    ; FIXME: bloodweb_1080_level21() => assertBloodwebLevel(21, A_ScriptDir "\screenshots\bloodweb\bloodweb_1080_level21.png")
    ; FIXME: bloodweb_1080_level21_reshade() => assertBloodwebLevel(21, A_ScriptDir "\screenshots\bloodweb\bloodweb_1080_level21_reshade.png")

    testSettingsMatchDetailsAbandon() => assertIsSettingsOpen(A_ScriptDir "\screenshots\settings\matchdetails_abandon_1440.png")
    testSettingsMatchDetailsQuit() => assertIsSettingsOpen(A_ScriptDir "\screenshots\settings\matchdetails_quit_1440.png")

    testIsDbdFinishedLoadingMainMenu1440() => assertisDbdFinishedLoading(A_ScriptDir "\screenshots\mainmenu\mainmenu_1440.png")
    testIsDbdFinishedLoadingMainMenu1080() => assertisDbdFinishedLoading(A_ScriptDir "\screenshots\mainmenu\mainmenu_1080.png")
    testIsDbdFinishedLoadingBloodweb1440() => assertisDbdFinishedLoading(A_ScriptDir "\screenshots\bloodweb\bloodweb_1440_level49.png")
}

setupFakeWindow(screenshotPath) {
    global dbdWindow, ops, scaled
    pBitmap := Gdip_CreateBitmapFromFile(screenshotPath)
    dbdWindow := DbdTestWindow(pBitmap)
    ops := TestOps(pBitmap)
    scaled := ScaledOps(ops)
    return pBitmap
}

assertBloodwebLevel(expectedLevel, screenshotPath) {
    pBitmap := setupFakeWindow(screenshotPath)
    level := getBloodwebLevel()
    Gdip_DisposeImage(pBitmap)
    Yunit.Assert(level == expectedLevel, "level=" level " expected=" expectedLevel)
}

assertIsSettingsOpen(screenshotPath) {
    pBitmap := setupFakeWindow(screenshotPath)
    Yunit.Assert(isSettingsOpen())
    Gdip_DisposeImage(pBitmap)
}

assertisDbdFinishedLoading(screenshotPath) {
    pBitmap := setupFakeWindow(screenshotPath)
    Yunit.Assert(isDbdFinishedLoading())
    Gdip_DisposeImage(pBitmap)
}