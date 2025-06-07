#Requires AutoHotkey v2.0

#Include Yunit\Yunit.ahk
#Include Yunit\Window.ahk
#Include Yunit\StdOut.ahk
#Include Yunit\JUnit.ahk
#Include Yunit\OutputDebug.ahk
#Include ..\Lib\autoupdate.ahk
#Include ..\Lib\files.ahk

class AutoUpdateTests {
    test_autoupdateScenario() {
        repoDir := A_Temp "\FakeZipTests"
        zipFile := repoDir "\repo.zip"
        tau := TestAutoUpdate(zipFile)

        ; Setup a dummy repo with known files.
        DirCreateOverwrite(repoDir)
        FileOverwite("original", repoDir "\example.ahk")

        createZip() {
            if FileExist(zipFile)
                FileDelete zipFile

            ; Use Windows tar to create a zip archive of tempRepoDir
            RunWait(
                'tar -a -c -f "' zipFile '" -C "' repoDir '" *',
                ,
                LaunchOpt := "Hide"
            )
        }
        createZip()

        Yunit.Assert(!tau.isGitRepo())
        Yunit.Assert(tau.isUpdateTime())
        tau.UpdateIfNewVersion()

        exampleMacro := tau.installDir "\example.ahk"
        Yunit.assert(FileExist(exampleMacro), "macro in update was not copied")
        Yunit.assert(FileRead(exampleMacro) = "original")

        ; Add a new macro to the installation
        localMacro := tau.installDir "\local.ahk"
        FileAppend("macro that doesn't exist in the repo", localMacro)
        
        ; Try to update, but the recent update should prevent it.
        Yunit.Assert(!tau.isUpdateTime(), "should not update again after an update")
        tau.UpdateIfNewVersion()
        Yunit.assert(FileExist(localMacro)) ; still exists

        ; Remove the last update file so we can do more updates.
        tau.removeLastUpdateFile()
        Yunit.Assert(tau.isUpdateTime())

        ; Zip hasn't changed, so nothing should happen
        tau.UpdateIfNewVersion()
        Yunit.assert(FileExist(localMacro)) ; still exists


        ; Change the zip
        FileAppend("+update", repoDir "\example.ahk")
        createZip()

        ; Trigger a run again.
        tau.removeLastUpdateFile()
        tau.UpdateIfNewVersion()

        Yunit.assert(!FileExist(localMacro), "Files not present in zip should be removed")
        Yunit.assert(FileRead(exampleMacro) = "original+update")
    }
}

class TestAutoUpdate extends AutoUpdate {
    root := A_Temp "\TestAutoUpdate"

    __New(zipFile) {
        DirCreateOverwrite(this.root)

        this.installDir := this.root "/install"
        DirCreate(this.installDir)

        this.stateDir := this.root "/state"
        DirCreate(this.stateDir)

        this.url := zipFile
    }
    __Delete() {
        DirDelete(this.root, true)
    }
    doesUserAgreeToUpdate() => true ; no MsgBox
    reportSuccess() => true ; no MsgBox
    getLatestEtag() => FileGetTime(this.url, "M") "-" FileGetSize(this.url)
    downloadZip(zipFile) => FileCopy(this.url, zipFile, Overwrite := true)
    removeLastUpdateFile() => FileDelete(this.lastUpdateCheckFile)
}
