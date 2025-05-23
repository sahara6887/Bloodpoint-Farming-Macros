#Requires AutoHotkey v2+

; View OutputDebug messages with https://learn.microsoft.com/en-us/sysinternals/downloads/debugview

logger := LoggerOps()

class LoggerOps {
    write(msg) {
        OutputDebug(msg "`n")
    }
    warn(msg) {
        this.write(msg)
    }
    info(msg) {
        this.write(msg)
    }
    debug(msg) {
        ; this.write(msg)
    }
    trace(msg) {
        ; this.write(msg)
    }
}
