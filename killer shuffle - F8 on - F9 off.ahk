#Persistent
#SingleInstance Force

; Dances forward and backwards in place, maintaining chase with survivors.
; Stops automatically if DBD loses focus or any of WASD are pressed.

global IsEnabled, IsWDown, IsSDown

; Start dancing
#IfWinActive, DeadByDaylight
~F8::
    IsEnabled := true

    Loop
    {
        ; Step Forward
        disableIfUnfocused()
        If (!IsEnabled)
            Break
        SendInput, % "{w down}"
        IsWDown := true
        Sleep, 70  ; Hold the key down
        If (!IsEnabled)
            Break
        IsWDown := false
        If (!IsEnabled)
            Break
        SendInput, % "{w up}"

        Sleep, 50

        ; Step Back
        disableIfUnfocused()
        If (!IsEnabled)
            Break
        SendInput, % "{s down}"
        IsSDown := true
        Sleep, 50  ; Hold the key down
        If (!IsEnabled)
            Break
        IsSDown := false
        SendInput, % "{s up}"
    }
Return

; WASD key down handlers with pass-through
; WS need special handling.
; For example, we do not want to send W up if the user starts holding W.
~w::
resetS()
disable()
return
~s::
resetW()
disable()
return
~a::
~d::
resetAndDisable()
return

resetAndDisable() {
   resetW()
   resetS()
   disable()
}
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

disableIfUnfocused() {
    WinGetTitle, title, A
    if (Trim(title) != "DeadByDaylight")
        disable()
}