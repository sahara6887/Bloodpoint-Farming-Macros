#Include Yunit\Yunit.ahk
#Include Yunit\Window.ahk
#Include Yunit\StdOut.ahk
#Include Yunit\JUnit.ahk
#Include Yunit\OutputDebug.ahk
#Include ..\autospend - F6.ahk
#Include ..\Lib\Gdip_All.ahk
#Include Lib\fakes.ahk

Yunit.Use(YunitWindow, YunitJUnit, YunitOutputDebug, YunitStdOut).Test(AutospenderTests)

class AutospenderTests {
    bloodweb_1440_level49() => assertBloodwebLevel(49, A_ScriptDir "\screenshots\bloodweb\bloodweb_1440_level49.png")
    bloodweb_1440_level49_reshade() => assertBloodwebLevel(49, A_ScriptDir "\screenshots\bloodweb\bloodweb_1440_level49_reshade.png")
    bloodweb_1080_level21() => assertBloodwebLevel(21, A_ScriptDir "\screenshots\bloodweb\bloodweb_1080_level21.png")
    bloodweb_1080_level21_reshade() => assertBloodwebLevel(21, A_ScriptDir "\screenshots\bloodweb\bloodweb_1080_level21_reshade.png")
}

assertBloodwebLevel(expectedLevel, screenshotPath) {
    level := getBloodwebLevel(screenshotPath)
    Yunit.Assert(level == expectedLevel, "level=" level " expected=" expectedLevel)
}
getBloodwebLevel(screenshotPath) {
    global dbd
    pToken := Gdip_Startup()
    pBitmap := Gdip_CreateBitmapFromFile(screenshotPath)

    dbd := DbdTestWindow(pBitmap)
    spender := Autospender(TestOps(pBitmap))
    level := spender.getBloodwebLevel()

    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
    return level
}
