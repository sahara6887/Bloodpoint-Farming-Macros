#Requires AutoHotkey v2.0

#Include ..\..\Lib\Gdip_All.ahk

class DbdTestWindow extends DbdWindowOps {
    __New(pBitmap) {
        if !pBitmap
            throw Error("DbdTestWindow requires a pBitmap")
        this.pBitmap := pBitmap
    }
    checkScale() {
        this._width := Gdip_GetImageWidth(this.pBitmap)
        this._height := Gdip_GetImageHeight(this.pBitmap)
    }
}

class TestOps extends WindowOps {
    __New(pBitmap) {
        if !pBitmap
            throw Error("TestOps requires a pBitmap")
        this.pBitmap := pBitmap
    }

    getColor(x, y) {
        return Gdip_GetPixel(this.pBitmap, x, y) & 0xFFFFFF
    }
}
class TestLogger extends LoggerOps {
    write(level, msg) {
        path := "?"
        line := "?"
        method := "?"
        filename := "?"
        try {
            throw Error("Capture stack")
        } catch as e {
            lines := StrSplit(e.Stack, "`n")
            if lines.Length >= 2 {
                match := ""
                if RegExMatch(lines[3], "(.*?) \((\d+)\) : \[([^]]*)\] .*", &match) {
                    path := match[1]
                    line := match[2]
                    method := match[3]
                    filename := RegExReplace(path, "^.*?\\Bloodpoint-Farming-Macros\\", "")
                }
            }
        }
        vsCodeRef := ".\" filename ":" line
        FileAppend(method ": " msg " [" vsCodeRef "]`n", "*")
    }
    warn(msg) => this.write("warn", msg)
    info(msg) => this.write("info", msg)
    debug(msg) => this.write("debug", msg)
    trace(msg) => this.write("trace", msg)
}

/**
 * Yunit doesn't support exit codes, so we need to implement our own to fail in CI.
 */
class YunitExitOnTestFailure {
    failed := false
    Update(Category, TestName, Result) {
        if Result is Error {
            this.failed := true
        }
    }

    __Delete() {
        ; We don't want to exit if we are running in the IDE--only in CI.
        ; Env var set via github actions
        if (this.failed and EnvGet("YUNIT_EXIT_ON_TEST_FAILURE") == "1") {
            logger.warn("Tests failed, exiting with code 1")
            ExitApp(1)
        }
    }
}
