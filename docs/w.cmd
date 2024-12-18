@ECHO OFF
SETLOCAL
:# Bootstrap windows ansible
if (%1) == () echo Usage: %0 "OK"
if (%1) == () goto :eof



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
set tempFile="%TEMP%\DownloadScript.ps1"

if not exist c:\batch\nul mkdir c:\batch

%heredoc% :download_script %tempFile%
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
 DownloadFile '!url!' '!file!' 
:download_script

type %tempFile%
powershell.exe -ExecutionPolicy ByPass -File %tempFile%

if exist %file% (
    powershell.exe -ExecutionPolicy ByPass -File %file% -Verbose -CertValidityDays 3650 -ForceNewSSLCert -SkipNetworkProfileCheck
)

rem del %tempFile
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
