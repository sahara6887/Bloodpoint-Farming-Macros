#SingleInstance Force
#IfWinActive DeadByDaylight

clickHoldTime := 50 ; in milliseconds

IsEnabled := false

; Stop the clicking
~F9::
  IsEnabled := false
Return

; Start the clicking
~F8::
  IsEnabled := true

  ; Loop to simulate holding and clicking at desired speed
  outer:
  Loop
  {
      If (!IsEnabled)
        Break outer

      SendInput, % "{w down}"
      Sleep, 70  ; Hold the key down
      SendInput, % "{w up}"

      Sleep, 100

      SendInput, % "{s down}"
      Sleep, 50  ; Hold the key down
      SendInput, % "{s up}"
  }
Return