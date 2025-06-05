#Requires AutoHotkey v2.0
#Include logging.ahk

getRootDir() {
    SplitPath(A_LineFile, , &libDir)
    return libDir "/.."
}

UpdateIfNewVersion(
    installDir := getRootDir(),
    url := "https://bloodpointfarming.github.io/Bloodpoint-Farming-Macros/Bloodpoint-Farming-Macros.zip"
) {
    ; If we're in a git repository, skip auto-update.
    if FileExist(installDir "/.git") {
        logger.info("Running from git repo. Skipping auto-update. Use git pull instead.")
        return true
    }

    ; Store last update info in %appdata%\Bloodpoint-Farming-Macros
    stateDir := A_AppData "/Bloodpoint-Farming-Macros"
    DirCreate(stateDir)
    etagFile := stateDir "/etag.txt"
    lastUpdateCheckFile := stateDir "/last_update_check.txt"

    zipFile := A_Temp "\Bloodpoint-Farming-Macros.zip"
    etag := ""
    oldEtag := ""
    isUrlHttps := RegExMatch(url, "^https://") ; as opposed to test file paths like C:\whatever.zip

    /**
     * Set the last update check time to now.
     */
    recordUpdateCheck() {
        if FileExist(lastUpdateCheckFile)
            FileDelete lastUpdateCheckFile
        FileAppend(A_Now, lastUpdateCheckFile)
    }

    if FileExist(lastUpdateCheckFile) {
        lastUpdateCheck := FileRead(lastUpdateCheckFile)
        if DateDiff(A_Now, lastUpdateCheck, "Hours") < 12 {
            logger.info("Last update check was less than 12 hours ago. Skipping update check.")
            recordUpdateCheck()
            return true
        }
    } else {
        ; Record the attempt early. If update fails later, don't retry until next update period.
        ; User should NOT be forced to deal with this immediately.
        recordUpdateCheck()
    }

    try {
        ; Check for updates via latest ETag.
        if isUrlHttps {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open("HEAD", url, false)
            whr.Send()
            etag := whr.GetResponseHeader("ETag")
            etag := RegExReplace(etag, "[^a-zA-Z0-9]", "")
            logger.debug("ETag from server: " etag)
        } else {
            etag := FileGetTime(url, "M")
        }

        ; Get the ETag for our current version (if recorded)
        if FileExist(etagFile) {
            oldEtag := FileRead(etagFile)
            logger.debug("ETag from file: " oldEtag)
        }

        ; Is latest version already installed?
        if etag = oldEtag {
            logger.info("No update needed.")
            return true
        }

        ; Ask user to confirm the update
        response := MsgBox("Macro updates are available. Update now?", "Macro Updates Available", 0x4 | 0x20)
        if response != "Yes" {
            logger.info("User declined update.")
            return true
        }

        ; Download update
        if isUrlHttps {
            Download(url, zipFile)
            logger.debug("Downloaded new ZIP to " zipFile)
        } else {
            FileCopy(url, zipFile, Overwrite := true)
        }

        ; Clear old directory contents. Ignore failures due to locked files.
        if DirExist(installDir) {
            loop files installDir "\*", "FR" {
                try {
                    if A_LoopFileAttrib ~= "D" {
                        DirDelete(A_LoopFilePath, Recurse := true)
                    } else {
                        FileDelete(A_LoopFilePath)
                    }
                }
            }
        }

        ; Unzip new macros into place
        DirCopy(zipFile, installDir, Overwrite := true)

        ; Record the new ETag
        FileAppend(etag, etagFile)

        logger.debug("Update complete.")

        ; Remove the temp zip file
        FileDelete zipFile

        ; Feedback for the user
        if FileExist(A_ScriptFullPath) {
            ; Update was successful and script is still in the same location.
            MsgBox("Update complete. Reloading to pick up the changes.", "Update Complete")
            Reload()
        } else {
            ; Script probably moved to a new location.
            MsgBox("Update complete. Please restart the script.", "Update Complete")
            Exit()
        }
        
    } catch Error as e {
        logger.error("Error during update on " e.File ":" e.Line " " e.Message "`n" e.Stack)
        MsgBox("Update failed on line " e.Line ". Giving up for now. Won't try again for at least 12 hours.", "Update Failed", 0x10)
        return false
    }
    return true
}

UpdateIfNewVersion()
