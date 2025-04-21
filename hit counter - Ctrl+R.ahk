#Persistent
#NoEnv
#SingleInstance Force
#IfWinActive DeadByDaylight

; Counts how many times M1 was pressed repeatedly with a debouce time of ~STBFL=8.
; Useful track the number of self-heal rotations in Reactive Healing builds.
;
; Hides the counter if there are no M1s for the specified duration.
; Usually this means that the rective portion is done.
global HideTimerAfterNoHitsForMs := 15000

SetBatchLines, -1
SendMode Input
if (FileExist("icons/reactive.ico"))
    Menu, Tray, Icon, icons/reactive.ico

global counter := 0
global lastHitTimestamp := 0

; Create GUI
Gui +LastFound +AlwaysOnTop +ToolWindow -Caption +Disabled
Gui, Color, 0  ; Set background to black
Gui, Font, cWhite s60 Bold
Gui, Add, Text, vCounterText w300 BackgroundTrans, % 0

Gui, +LastFound  ; Mark this GUI as the "last found" window
WinSet, TransColor, 0  ; set black as transparent
return

~^-::
if (counter > 0)
    setCounter(counter - 1)
Return

~^=::
setCounter(counter + 1)
Return

; Show and reset the counter
~^r::
    setCounter(0)
    lastHitTimestamp := 0 ; Allow M1 to register immediately.
return

~LButton::
    now := A_TickCount
    millisSinceLastHit := now - lastHitTimestamp
    ; STBFL=8 is ~2000 ms
    if (millisSinceLastHit > 2000) {
        lastHitTimestamp := now
        setCounter(counter + 1)
    }
return

setCounter(value) {
    OutputDebug, Setting counter to %value%
    counter := value
    if (value = 0) {
        Gui, Hide
    } else {
        Gui, Show, x70 y400 NoActivate
        SetTimer, ResetCounter, %HideTimerAfterNoHitsForMs%
        GuiControl,, CounterText, % counter
    }
}

ResetCounter:
SetTimer,, Off
setCounter(0)
OutputDebug, Resetting counter because no hits within %HideTimerAfterNoHitsForMs%.
return
