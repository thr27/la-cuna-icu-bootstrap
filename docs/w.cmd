@ECHO OFF
:REM to install, run this in c:\batch
:REM curl -o w.cmd https://thr27.github.io/la-cuna-icu-bootstrap/w.cmd
SETLOCAL
:# Bootstrap windows ansible
if (%1) == () echo Usage: %0 "SETUP"
if (%1) == () goto :eof

mkdir "C:\tmp\ansible"

rem Definition of heredoc macro
setlocal DisableDelayedExpansion
set LF=^


::Above 2 blank lines are required - do not remove
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"
set heredoc=for %%n in (1 2) do if %%n==2 (%\n%
       for /F "tokens=1,2" %%a in ("!argv!") do (%\n%
          if "%%b" equ "" (call :heredoc %%a) else call :heredoc %%a^>%%b%\n%
          endlocal ^& goto %%a%\n%
       )%\n%
    ) else setlocal EnableDelayedExpansion ^& set argv=

set url=https://raw.githubusercontent.com/ansible/ansible-documentation/refs/heads/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
set file=c:\batch\ConfigureRemotingForAnsible.ps1
set downloadScript="%TEMP%\DownloadScript.ps1"

if not exist c:\batch\nul mkdir c:\batch

%heredoc% :download_script %downloadScript%
function DownloadFile([string]$url, [string]$file) {
     $downloadRequired = $true
     if ((test-path $file)) {
         $localModified = (Get-Item $file).LastWriteTime  
         $webRequest = [System.Net.HttpWebRequest]::Create($url);
         $webRequest.Method = "HEAD";
         $webResponse = $webRequest.GetResponse()
         $remoteLastModified = ($webResponse.LastModified) -as [DateTime]  
         $webResponse.Close()
         if ($remoteLastModified -gt $localModified) {
             Write-Host "$file is out of date"
         } else {
             $downloadRequired = $false
         }
     }
     if ($downloadRequired) {
         $clnt = new-object System.Net.WebClient
         Write-Host "Downloading from $url to $file"
         $clnt.DownloadFile($url, $file)
     } else {
         Write-Host "$file is up to date."
     }
 }
 DownloadFile $args[0] $args[1]
:download_script
if (%1) == (INST_WINRM) goto :INST_WINRM
if (%1) == (PS7_INSTALL) goto :PS7_INSTALL
if (%1) == (WSUS_UPDATE) goto :WSUS_UPDATE

:INST_WINRM
powershell.exe -ExecutionPolicy ByPass -File %downloadScript% %url% %file%

if exist %file% (
    powershell.exe -ExecutionPolicy ByPass -File %file% -Verbose -CertValidityDays 3650 -ForceNewSSLCert -SkipNetworkProfileCheck
)
if (%1) == (INST_WINRM) goto :eof

:PS7_INSTALL
set url=https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi
set file=c:\batch\PowerShell-7.4.6-win-x64.msi
powershell.exe -ExecutionPolicy ByPass -File %downloadScript% %url% %file%

if exist %file% (
    msiexec.exe /package %file% /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1
)
if (%1) == (PS7_INSTALL) goto :eof

:WSUS_UPDATE
set url=https://thr27.github.io/la-cuna-icu-bootstrap/wsus_update.vbs
set file=c:\batch\wsus_update.vbs

powershell.exe -ExecutionPolicy ByPass -File %downloadScript% %url% %file%
if exist %file% (
    cscript.exe %file%  
)
if (%1) == (WSUS_UPDATE) goto :eof

goto :eof
:heredoc label
set "skip="
for /F "delims=:" %%a in ('findstr /N "%1" "%~F0"') do (
   if not defined skip (set skip=%%a) else set /A lines=%%a-skip-1
)
for /F "skip=%skip% delims=" %%a in ('findstr /N "^" "%~F0"') do (
   set "line=%%a"
   echo(!line:*:=!
   set /A lines-=1
   if !lines! == 0 exit /B
)
exit /B
rem -------------------------

:eof
