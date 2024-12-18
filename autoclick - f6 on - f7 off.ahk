#SingleInstance Force
#IfWinActive DeadByDaylight

clickHoldTime := 50 ; in milliseconds

IsEnabled := false

; Stop the clicking
~F7::
  IsEnabled := false
Return

; Start the clicking
~F6::
  IsEnabled := true

  Loop
  {
    If (!IsEnabled)
        Break
    Click down, Left
    Sleep, clickHoldTime
    Click up, Left
  }
Return