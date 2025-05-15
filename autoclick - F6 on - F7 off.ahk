#Requires AutoHotkey v2.0
#SingleInstance
#HotIf WinActive("DeadByDaylight", )
if (FileExist("icons/autopurchase.ico"))
  TraySetIcon("icons/autopurchase.ico")

clickHoldTime := 50 ; in milliseconds

IsEnabled := false

; Stop the clicking
~F7::
  {
    global
    IsEnabled := false
    Return
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
      Sleep(clickHoldTime)
      Click("up, Left")
    }
    Return
  }
