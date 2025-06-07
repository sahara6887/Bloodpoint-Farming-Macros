#Requires AutoHotkey v2+

#Include autoupdate.ahk
#Include colors.ahk
#Include dbd.ahk
#Include logging.ahk
#Include retries.ahk
#Include scaling.ahk

#SingleInstance
Persistent

SetMouseDelay(-1) ; Make cursor move instantly rather than mimicking user behavior

setTrayIcon(file) {
    if (FileExist(file))
        TraySetIcon(file)
}
