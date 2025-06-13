#Requires AutoHotkey v2+
#Include logging.ahk

doWithRetriesUntil(actionName, predicateName, maxDurationMs := 500) {
    startTime := A_TickCount  ; Get the current time (in milliseconds)
    action := %actionName%
    predicate := %predicateName%

    while (A_TickCount - startTime < maxDurationMs) {
        action.Call()

        ; Check several times before repeating the action.
        ; Checking instantly isn't enough time, but the action is often slow,
        ; so we don't want to repeat the action if we don't need to.
        loop 5 {
            if (predicate.Call()) {
                duration := A_TickCount - startTime
                logger.info(predicate.Name . " took " . duration . " ms.")
                return
            }
            Sleep(10)
        }
    }

    logger.warn("Failed waiting for " . predicate.Name . " after " . maxDurationMs . " ms.")
    ; Exit()
}

waitUntil(predicateName, maxDurationMs := 500) => doWithRetriesUntil("doNothing", predicateName, maxDurationMs)

doNothing() {
    ; used as a noop for doWithRetriesUntil(action, predicate)
}
