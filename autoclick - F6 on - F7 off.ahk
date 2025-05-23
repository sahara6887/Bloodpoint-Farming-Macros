#Requires AutoHotkey v2+
#Include Lib\common.ahk
#HotIf WinActive("DeadByDaylight")

setTrayIcon("icons/autopurchase.ico")

IsEnabled := false

; Stop the clicking
~F7::
  {
    global
    IsEnabled := false
  }

; Start the clicking
~F6::
  {
    global
    IsEnabled := true

    Loop
    {
      If (!IsEnabled)
        Break
      Click("down, Left")
      Sleep(50)
      Click("up, Left")
    }
  }
