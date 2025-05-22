#Include Yunit\Yunit.ahk
#Include Yunit\Window.ahk
#Include Yunit\StdOut.ahk
#Include Yunit\JUnit.ahk
#Include Yunit\OutputDebug.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\Gdip_All.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk

Yunit.Use(YunitWindow, YunitJUnit, YunitOutputDebug, YunitStdOut).Test(AutospenderTests)

class AutospenderTests {
    bloodweb_1440_level49() => assertBloodwebLevel(49, A_ScriptDir "\screenshots\bloodweb\bloodweb_1440_level49.png")
    bloodweb_1440_level49_reshade() => assertBloodwebLevel(49, A_ScriptDir "\screenshots\bloodweb\bloodweb_1440_level49_reshade.png")
    ; FIXME: bloodweb_1080_level21() => assertBloodwebLevel(21, A_ScriptDir "\screenshots\bloodweb\bloodweb_1080_level21.png")
    ; FIXME: bloodweb_1080_level21_reshade() => assertBloodwebLevel(21, A_ScriptDir "\screenshots\bloodweb\bloodweb_1080_level21_reshade.png")
}

assertBloodwebLevel(expectedLevel, screenshotPath) {
    level := testGetBloodwebLevel(screenshotPath)
    Yunit.Assert(level == expectedLevel, "level=" level " expected=" expectedLevel)
}
testGetBloodwebLevel(screenshotPath) {
    global dbdWindow, ops
    pToken := Gdip_Startup()
    pBitmap := Gdip_CreateBitmapFromFile(screenshotPath)

    dbdWindow := DbdTestWindow(pBitmap)
    ops := TestOps(pBitmap)
    scaled := ScaledOps(ops)
    level := getBloodwebLevel()

    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
    return level
}