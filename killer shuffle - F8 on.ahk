#Persistent
#SingleInstance Force

if (FileExist("icons/shuffle.ico"))
    Menu, Tray, Icon, icons/shuffle.ico

; Dances forward and backwards in place, maintaining chase with survivors.
; Stops automatically if DBD loses focus or any of WASD are pressed.

global IsEnabled, IsWDown, IsSDown

; Start dancing
#IfWinActive, DeadByDaylight
~F8::
    IsEnabled := true
    Loop
    {
        If (!IsEnabled)
            Break

        holdKey("w", 70, IsWDown)

        Sleep, 50

        holdKey("s", 50, IsSDown)
    }
Return

holdKey(key, holdTime, ByRef isKeyDown) {
    ; If DBD loses focus, stop. Don't spam "wswsws" to other windows.
    WinGetTitle, title, A
    if (Trim(title) != "DeadByDaylight") {
        disable()
        return
    }
    If (!IsEnabled)
        return

    ; Send the key down event
    SendInput, % "{" key " down}"
    isKeyDown := true
    Sleep, holdTime  ; Hold the key down for the specified time

    If (!IsEnabled)
        return
    ; Reset key state and send key up event
    isKeyDown := false
    SendInput, % "{" key " up}"
}

; WASD key down handlers with pass-through
; WS need special handling.
; For example, we do not want to send W up if the user starts holding W.
~w::
disable()
resetS()
return
~s::
disable()
resetW()
return
~a::
~d::
disable()
resetW()
resetS()
return

resetW() {
    if (IsWDown) {
        SendInput, % "{w up}"
        IsWDown := false
    }
}
resetS() {
    if (IsSDown) {
        SendInput, % "{s up}"
        IsSDown := false
    }
}
disable() {
    IsEnabled := false
}
