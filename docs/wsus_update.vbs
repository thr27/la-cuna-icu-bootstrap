ssDefault = 0
ssManagedServer   = 1
ssWindowsUpdate   = 2
ssOthers          = 3
intSearchStartChar = 1

dim strTitle

Set updateSession = CreateObject("Microsoft.Update.Session")
Set updateSearcher = updateSession.CreateupdateSearcher()

updateSearcher.ServerSelection = ssDefault
Set searchResult = updateSearcher.Search("IsInstalled=0 and IsHidden=0")

WScript.Echo "List of applicable items on the machine:"

For I = 0 To searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
    WScript.Echo I + 1 & "> " & update.Title
Next

If searchResult.Updates.Count = 0 Then
    WScript.Echo "There are no applicable updates."
    WScript.Quit
End If

WScript.Echo vbCRLF & "Creating collection of updates to download:"

Set updatesToDownload = CreateObject("Microsoft.Update.UpdateColl")

For I = 0 to searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
    addThisUpdate = false
    If update.InstallationBehavior.CanRequestUserInput = true Then
        WScript.Echo I + 1 & "> skipping: " & update.Title & " because it requires user input"
    Else
        If update.EulaAccepted = false Then
            WScript.Echo I + 1 & "> note: " & update.Title & " has a license agreement that must be accepted:"
            WScript.Echo update.EulaText
            WScript.Echo "Auto accept this license agreement ..."
            WScript.Echo 
            update.AcceptEula()
            addThisUpdate = true
        Else
            addThisUpdate = true
        End If
    End If
    If addThisUpdate = true Then
        WScript.Echo I + 1 & "> adding: " & update.Title 
        updatesToDownload.Add(update)
    End If
Next

If updatesToDownload.Count = 0 Then
    WScript.Echo "All applicable updates were skipped."
    WScript.Quit
End If
    
WScript.Echo vbCRLF & "Downloading updates..."

Set downloader = updateSession.CreateUpdateDownloader() 
downloader.Updates = updatesToDownload
downloader.Download()

Set updatesToInstall = CreateObject("Microsoft.Update.UpdateColl")

rebootMayBeRequired = false

WScript.Echo vbCRLF & "Successfully downloaded updates:"

For I = 0 To searchResult.Updates.Count-1
    set update = searchResult.Updates.Item(I)
    If update.IsDownloaded = true Then
        WScript.Echo I + 1 & "> " & update.Title 
        updatesToInstall.Add(update)	
        If update.InstallationBehavior.RebootBehavior > 0 Then
            rebootMayBeRequired = true
        End If
    End If
Next

If updatesToInstall.Count = 0 Then
    WScript.Echo "No updates were successfully downloaded."
    WScript.Quit
End If

If rebootMayBeRequired = true Then
    WScript.Echo vbCRLF & "These updates may require a reboot."
End If

WScript.Echo  vbCRLF & "Updates are installed now ..."
WScript.Echo 

WScript.Echo "Installing updates..."
Set installer = updateSession.CreateUpdateInstaller()
installer.Updates = updatesToInstall
Set installationResult = installer.Install()

'Output results of install
WScript.Echo "Installation Result: " & _
installationResult.ResultCode 
WScript.Echo "Reboot Required: " & _ 
installationResult.RebootRequired & vbCRLF 
WScript.Echo "Listing of updates installed " & _
"and individual installation results:" 

For I = 0 to updatesToInstall.Count - 1
    WScript.Echo I + 1 & "> " & _
    updatesToInstall.Item(i).Title & _
    ": " & installationResult.GetUpdateResult(i).ResultCode 		
Next

If rebootMayBeRequired = true Then
    WScript.Quit(1)
Else
    WScript.Quit(0)
End If
