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
        return Gdip_GetPixel(this.pBitmap, x, y)
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
            ; Get the second line of the stack trace, which is the caller
            lines := StrSplit(e.Stack, "`n")
            if lines.Length >= 2 {
                ; Example line: "▶ SomeFunc() (file.ahk:12)"
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
