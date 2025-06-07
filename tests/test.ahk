#Include Lib\test_includes.ahk
#Include AutoUpdateTests.ahk
#Include AutospenderTests.ahk

Yunit
    .Use(YunitJUnit, YunitOutputDebug, YunitStdOut, YunitExitOnTestFailure)
    .Test(
        AutoSpenderTests,
        AutoUpdateTests,
    )