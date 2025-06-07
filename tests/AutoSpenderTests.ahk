#Requires AutoHotkey v2.0

#Include Lib\test_includes.ahk
#Include Lib\fakes.ahk
#Include ..\Lib\Gdip_All.ahk
#Include ..\Lib\dbd.ahk
#Include ..\Lib\scaling.ahk

if (A_ScriptFullPath = A_LineFile)
    Yunit
        .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
        .Test(AutoSpenderTests)

class AutoSpenderTests {
    __New() {
        this.pToken := Gdip_Startup()
    }

    __Delete() {
        Gdip_Shutdown(this.pToken)
    }

    test_getBloodwebLevel_Level49_1440() => assertFor("bloodweb\bloodweb_1440_level49.png", () => getBloodwebLevel() == 49)
    test_getBloodwebLevel_Level49Reshade1440() => assertFor("bloodweb\bloodweb_1440_level49_reshade.png", () => getBloodwebLevel() == 49)
    test_getBloodwebLevel_Level21_1080() => assertFor("bloodweb\bloodweb_1080_level21.png", () => getBloodwebLevel() == 21)
    test_getBloodwebLevel_Level21Reshade1080() => assertFor("bloodweb\bloodweb_1080_level21_reshade.png", () => getBloodwebLevel() == 21)

    test_isSettingsOpen_Abandon1440() => assertFor("settings\matchdetailsAbandon1440.png", isSettingsOpen.Bind())
    test_isSettingsOpen_Quit1440() => assertFor("settings\matchdetailsQuit1440.png", isSettingsOpen.Bind())
    test_isSettingsOpen_Graphics1080() => assertFor("settings\graphics1080.png", isSettingsOpen.Bind())

    test_isDbdFinishedLoading_1440() => assertFor("mainmenu\mainmenu_1440.png", isDbdFinishedLoading.Bind())
    test_isDbdFinishedLoading_1080() => assertFor("mainmenu\mainmenu_1080.png", isDbdFinishedLoading.Bind())
    test_isDbdFinishedLoading_Bloodweb1440() => assertFor("bloodweb\bloodweb_1440_level49.png", isDbdFinishedLoading.Bind())

    test_isHookSpaceOptionAvailable_1440() => assertFor("match\matchHook1440.png", isHookSpaceOptionAvailable.Bind())
    test_isHookSpaceOptionAvailable_1080() => assertFor("match\matchHook1080.png", isHookSpaceOptionAvailable.Bind())
    test_isHookSpaceOptionAvailable_1440Reshade() => assertFor("match\matchHookReshade1440.png", isHookSpaceOptionAvailable.Bind())
    test_isHookSpaceOptionAvailable_1080Reshade() => assertFor("match\matchHookReshade1080.png", isHookSpaceOptionAvailable.Bind())

    test_isAbandonEscapeOptionVisible_1440() => assertFor("match\matchAbandonEsc1440.png", isAbandonEscapeOptionVisible.Bind())

    test_isSettingsGraphicsTabSelected_1440() => assertFor("settings\graphics1440.png", isSettingsGraphicsTabSelected.Bind())
    test_isSettingsGraphicsTabSelected_1080() => assertFor("settings\graphics1080.png", isSettingsGraphicsTabSelected.Bind())
    test_isSettingsGraphicsTabSelected_matchdetails1440() => assertFor("settings\matchdetailsQuit1440.png", () => !isSettingsGraphicsTabSelected())

    test_isSettingsGraphicsFpsMenuOpen_1440() => assertFor("settings\graphicsFpsMenu1440.png", isSettingsGraphicsFpsMenuOpen.Bind())
    test_isSettingsGraphicsFpsMenuOpen_1080() => assertFor("settings\graphicsFpsMenu1080.png", isSettingsGraphicsFpsMenuOpen.Bind())
    test_isSettingsGraphicsFpsMenuOpen_NotOpen1440() => assertFor("settings\graphics1440.png", () => !isSettingsGraphicsFpsMenuOpen())

    test_isAbandonConfirmOpen_1440() => assertFor("settings\confirmAbandon1440.png", isAbandonConfirmOpen.Bind())

    test_isReadiedUp_No1440() => assertFor("pregame\unready1440.png", () => !isReadiedUp())
    test_isReadiedUp_No1080() => assertFor("pregame\unready1080.png", () => !isReadiedUp())
    test_isReadiedUp_Yes1440() => assertFor("pregame\readiedUp1440.png", isReadiedUp.Bind())
    test_isReadiedUp_Yes1080() => assertFor("pregame\readiedUp1080.png", isReadiedUp.Bind())
    test_isReadiedUp_YesReshade1440() => assertFor("pregame\readiedUpReshade1440.png", isReadiedUp.Bind())
    test_isReadiedUp_YesReshade1080() => assertFor("pregame\readiedUpReshade1080.png", isReadiedUp.Bind())
    test_isReadiedUp_NoKiller1440() => assertFor("pregame\unreadyKiller1440.png", () => !isReadiedUp())
    test_isReadiedUp_YesKiller1440() => assertFor("pregame\readiedUpKiller1440.png", () => isReadiedUp())

    test_isReadyButtonVisible_1440() => assertFor("pregame\unready1440.png", isReadyButtonVisible.Bind())
    test_isReadyButtonVisible_1080() => assertFor("pregame\unready1080.png", isReadyButtonVisible.Bind())
    test_isReadyButtonVisible_Reshade1440() => assertFor("pregame\unreadyReshade1440.png", isReadyButtonVisible.Bind())
    test_isReadyButtonVisible_Reshade1080() => assertFor("pregame\unreadyReshade1080.png", isReadyButtonVisible.Bind())
    test_isReadyButtonVisible_Hover1440() => assertFor("pregame\unreadyHover1440.png", isReadyButtonVisible.Bind())
    test_isReadyButtonVisible_HoverReshade1440() => assertFor("pregame\unreadyHoverReshade1440.png", isReadyButtonVisible.Bind())
    test_isReadyButtonVisible_Killer1440() => assertFor("pregame\unreadyKiller1440.png", isReadyButtonVisible.Bind())
}

setupFakeWindow(screenshotPath) {
    global dbdWindow, ops, scaled
    pBitmap := Gdip_CreateBitmapFromFile(screenshotPath)
    dbdWindow := DbdTestWindow(pBitmap)
    ops := TestOps(pBitmap)
    return pBitmap
}

assertBloodwebLevel(expectedLevel, screenshotPath) {
    pBitmap := setupFakeWindow(screenshotPath)
    level := getBloodwebLevel()
    Gdip_DisposeImage(pBitmap)
    Yunit.Assert(level == expectedLevel, "level=" level " expected=" expectedLevel)
}

assertFor(screenshot, predicate) {
    screenshotPath := A_ScriptDir "\screenshots\" screenshot
    pBitmap := setupFakeWindow(screenshotPath)
    Yunit.Assert(predicate.Call())
    Gdip_DisposeImage(pBitmap)
}
