@echo off

rem =====
rem For more information on ScriptTiger and more ScriptTiger scripts visit the following URL:
rem https://scripttiger.github.io/
rem Or visit the following URL for the latest information on this ScriptTiger script:
rem https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate
rem =====

rem Enable delayed expansion to be used during for loops and other parenthetical groups
setlocal ENABLEDELAYEDEXPANSION

rem Script version number
set V=1.45

rem Set Resource and target locations
set CACHE=Unified-Hosts-AutoUpdate
set SCACHE=%SystemRoot%\TEMP\%CACHE%
set CACHE=%TEMP%\%CACHE%
set CTEMP=%CACHE%\ctemp
set VERSION=%~dp0VERSION
set IGNORE=%~dp0ignore.txt
set CUSTOM=%~dp0custom.txt
set README=%~dp0README.md
set UPDATE=%~dp0Update.cmd
set CMD=Hosts_Update.cmd
set CMDDIR=%~dp0
set LOCK=%~dp0lock
set LOGD=%~dp0log.txt
set SELF=%~f0
set GHD=raw.githubusercontent.com
set GH=https://%GHD%/ScriptTiger/Unified-Hosts-AutoUpdate
set HOSTS=%SYSTEMROOT%\System32\drivers\etc\hosts
set CHOSTS=%CACHE%\hosts
set BASE=https://raw.githubusercontent.com/StevenBlack/hosts/master
set TASKER=%SYSTEMROOT%\System32\schtasks.exe
set TN=Unified Hosts AutoUpdate
set HASHER=%SYSTEMROOT%\System32\certutil.exe
set NET=1
set EXIT=0
set DFC=0

rem Grab local version and commit
for /f "tokens=1,2" %%0 in ('type "%VERSION%"') do (
	set OLD=%%0
	set COMMIT=%%1
)

rem Turn on script updates by default, then determine and set user preference
rem If script updates disabled, also disable default logging mechanism
set UPDATES=1
if /i "%OLD:~-1%"=="X" (
	set UPDATES=0
	set LOG=nul
	call :Echo "Script updates currently disabled"
)

rem Strip out emergency status if present in local version
if "%OLD:~,1%"=="X" (
	set OLD=%OLD:~1%
	echo !OLD! %COMMIT%>"%VERSION%"
)

rem Combine local version info to single string
set OLD=%V%%OLD%%COMMIT%

rem Skip options if script is coming back from being updated
set OPTION=.%~1
if "%OPTION%"=="./U" goto Skip_Options

rem Remember arguments
set ARGS=%*

rem Check options and shift over
:Options
set OPTION=.%~1
if "%OPTION:~,2%"=="./" (
	set OPTION=%~1
	set OPTION=!OPTION:"=!
	if /i "!OPTION!"=="/dfc" set DFC=1
	if /i "!OPTION!"=="/log" set LOG=!LOGD!
	if /i "!OPTION:~,5!"=="/log:" set LOG=!OPTION:~5!
	shift
	goto Options
)

:Skip_Options

rem Set logging mechanism
if exist "%LOCK%" (
	set /p LOG=<"%LOCK%"
	set LOG=!LOG:"=!
)
if "%LOG%"=="" set LOG=nul

echo %DATE% @ %TIME%: [%SELF% %ARGS%]>>"!LOG!"
call :Echo "Initializing..."

rem Check if script is returning from being updated and finish update process
if "%~1"=="/U" (
	cls
	call :Echo "The updated script has been loaded"
	echo %NEW% %COMMIT%>"%VERSION%"
	if exist "%README%" del /q "%README%"
	call :Download %GH%/%COMMIT%/README.md "%README%" readme || goto Failed_Download
) else (

	rem If the URL is sent as a parameter, set the URL variable and turn the script to quiet mode with no prompts
	rem Initialize QUIET to off/0
	if "%1"=="" (
		set URLD=
		set QUIET=0
		if exist "%LOCK%" del /q "%LOCK%"
	) else (
		set URLD=%1
		set QUIET=1
		if not "%2"=="" set NEWCOMP=%2
		if "%LOG%"=="nul" if "%UPDATES%"=="1" (
			set LOG=%LOGD%
			echo %DATE% @ %TIME%: [%SELF% %ARGS%]>"!LOG!"
			echo %DATE% @ %TIME%: Initializing...>>"!LOG!"
		)
	)
)

rem Check for admin rights, exit if none present
"%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\Prefetch\" > nul || goto Admin

rem Set order of precedence for downloaders and set downloader strings
set DOWNLOADER=0
call :Execute bitsadmin /list && set DOWNLOADER=1
call :Execute powershell $host.version && set DOWNLOADER=2
if %DOWNLOADER%==2 (
	set DOWNLOADER=PowerShell
	set DOWNLOADER_FROM=powershell invoke-webrequest
	set DOWNLOADER_TO= -outfile
	set Q='
)
if %DOWNLOADER%==1 (
	set DOWNLOADER=BITS
	set DOWNLOADER_FROM=bitsadmin /transfer ""
	set DOWNLOADER_TO=
	set Q="
)
if %DOWNLOADER%==0 goto Downloader

rem Create temporary cache if does not exist
if not exist "%CACHE%" md "%CACHE%"

rem If not in quiet mode, check general connectivity
if not !QUIET!==1 (
	call :Echo "Checking connectivity to %GHD%..."
	call :Execute ping -n 10 -w 2000 %GHD% || goto Connectivity
	call :Echo "%GHD% reached successfully"
)

if "%UPDATES%"=="0" goto Skip_Script_Update

rem Begin version checks
call :Echo "Your current script version is %V%" ^
"Checking for script updates..."

rem Grab remote script VERSION file
rem On error, report connectivity problem
if !QUIET!==1 (
	call :Download %GH%/master/VERSION "%CTEMP%" version || goto Failed_Download
) else call :Execute %DOWNLOADER_FROM% %GH%/master/VERSION %DOWNLOADER_TO% %Q%%CTEMP%%Q% || goto Downloader_Connectivity

rem Grab remote script version and commit
for /f "tokens=1,2" %%0 in ('type "%CTEMP%"') do (
	set NEW=%%0
	set COMMIT=%%1
)

rem Check for emergency stop status
if "%NEW:~,1%"=="X" (
	call :Echo "**We are currently working to fix a problem**" ^
	"**Please try again later**"
	set ERROR=Currently disabled due to maintenance, please try again later
	set EXIT=4
	goto Exit
)

rem If the version info doesn't match, automatically update and continue with updated script
if not "%OLD%"=="%NEW%%NEW%%COMMIT%" (
	call :Echo "A new script update is available^^^!" ^
	"Updating script..."
	timeout /t 3 /nobreak > nul
	call :Download %GH%/%COMMIT%/%CMD% "%UPDATE%" update || goto Failed_Download
	timeout /t 3 /nobreak > nul
	"%UPDATE%" /U
) else call :Echo "Your script is up to date"

:Skip_Script_Update

rem Check to see if the Windows version is compatible with the scripted scheduler
rem Check to see if there is currently a scheduled update task
rem If there is, ask if they want to keep it
if not !QUIET!==1 (
	if exist "%TASKER%" (
		set TASK=0
		for /f "tokens=*" %%0 in ('schtasks ^| findstr "Unified.Hosts.AutoUpdate"') do set TASK=1
		if !TASK!==1 (
			call :Echo "You currently have a scheduled task already in place"
			choice.exe /m "Would you like to run the current task now?"
			if !errorlevel!==1 goto Run
			choice.exe /m "Would you like to keep the current task?"
			if !errorlevel!==2 call :Unschedule
		)
	) else set TASK=2
)

rem If the ignore list doesn't exist, make one
rem This CANNOT be empty
if not exist "%IGNORE%" (
	(
		echo # Ignore list written in literal expressions
		echo # These changes will take effect automatically the next scheduled update
		echo # To force changes now, run Hosts_Update.cmd with the "update anyway" option
		echo # If you decide to delete the below entries, DO NOT delete these above comment lines
		echo # If this file is left completely empty, the script will break
		echo # Uncomment the below entry to allow the analytics.google.com domain
		echo #0.0.0.0 analytics.google.com
	) > "%IGNORE%"
)

rem If the custom list doesn't exist, make one
if not exist "%CUSTOM%" (
	(
		echo # Custom entries managed by ScriptTiger's Unified Hosts AutoUpdate
		echo # These custom entries are in standard hosts file format
		echo #	102.54.94.97	rhino.acme.com
		echo #	38.25.63.10	x.acme.com
		echo #	127.0.0.1	localhost
		echo #	::1		localhost
		echo #	0.0.0.0		block.me
	) > "%CUSTOM%"
)

rem Grab hash of current ignore and custom list and hash recorded in hosts file
if exist "%HASHER%" (
	set HASH=1
	for /f "tokens=*" %%0 in ('certutil -hashfile "%IGNORE%" MD5 ^| findstr /v :') do set NEWIGNORE=%%0
	set NEWIGNORE=!NEWIGNORE: =!
	for /f "tokens=1,2 delims=:" %%0 in ('findstr /b #.Ignore.list: "%HOSTS%"') do (
		set OLDIGNORE=%%1
		set OLDIGNORE=!OLDIGNORE:~1!
	)
	for /f "tokens=*" %%0 in ('certutil -hashfile "%CUSTOM%" MD5 ^| findstr /v :') do set NEWCUSTOM=%%0
	set NEWCUSTOM=!NEWCUSTOM: =!
	for /f "tokens=1,2 delims=:" %%0 in ('findstr /b #.Custom.list: "%HOSTS%"') do (
		set OLDCUSTOM=%%1
		set OLDCUSTOM=!OLDCUSTOM:~1!
	)
) else set HASH=0

rem If the compression wasn't sent as a parameter, grab the preset compression level from the local hosts file, or default to 1
set OLDCOMP=1
for /f "tokens=1,2 delims=:" %%0 in ('findstr /b #.Compression: "%HOSTS%"') do (
	set OLDCOMP=%%1
	set OLDCOMP=!OLDCOMP:~1!
)
if "%NEWCOMP%"=="" set NEWCOMP=%OLDCOMP%

rem Initialize MARKED to 0 for no markings yet verified
set MARKED=0

rem Check for begin and end tags in hosts file
for /f "tokens=*" %%0 in (
	'findstr /b /i "####.BEGIN.UNIFIED.HOSTS.#### ####.END.UNIFIED.HOSTS.####" "%HOSTS%"'
) do (
	if !MARKED!==1 if /i "%%0"=="#### END UNIFIED HOSTS ####" (set MARKED=2) else (set MARKED=-1)
	if /i "%%0"=="#### BEGIN UNIFIED HOSTS ####" set MARKED=1
)

rem Assess tags as correct, incorrect, or absent
rem If there are no tags, offer to install them
rem Check to see if the file is null-terminating before appending extra white space
if !MARKED!==0 (
	call :Echo "The Unified Hosts has not yet been marked in your local hosts file"
	if not !QUIET!==1 (
		choice.exe /m "Automatically insert the Unified Hosts at the bottom of your local hosts?"
		if !ERRORLEVEL!==2 goto Mark
	)
	if /i not "%URLD%"=="remove" (
		for /f "tokens=1* delims=:" %%0 in ('findstr /n .* "%HOSTS%"') do set NTF=%%1
		if not "!NTF!"=="" echo.>>"%HOSTS%"
		echo #### BEGIN UNIFIED HOSTS ####>>"%HOSTS%"
		echo #### END UNIFIED HOSTS ####>>"%HOSTS%"
		goto update
	) else goto Exit
)

if !MARKED!==2 (
	call :Echo "The Unified Hosts is already installed in your local hosts file"
	if not !QUIET!==1 (
		choice.exe /M "Would you like to continue to update it?"
		if !errorlevel!==2 (
			choice.exe /M "Would you like to remove the Unified Hosts from your local hosts file?"
			if !errorlevel!==1 (
				call :File 1
				call :Flush
				goto View_Hosts
			)
			goto Exit
		)
	)
) else goto Mark

call :Echo "Checking for Unified Hosts updates..."

rem Initialize OLD to NUL in case markings are present but not Unified Hosts
set OLD=NUL

rem Grab date and URL from the Unified Hosts inside of the local hosts file
set URL=
for /f "tokens=*" %%0 in (
	'findstr /b "#.Date:. #.Fetch.the.latest.version.of.this.file:.%BASE%/....." "%HOSTS%"'
) do (
	set LINE=%%0
	if "!LINE:~,8!"=="# Date: " set OLD=%%0
	if "!LINE:~,8!"=="# Fetch " (
		set URL=!LINE:~41!
		if not !QUIET!==1 set URLD=!URL!
	)
)

rem If the old URL doesn't match the new URL of a scheduled task, update
if !QUIET!==1 if not "%URLD%"=="%URL%" goto Update

rem If the markings are there but no Unified Hosts, skip the rest of the check and continue to update
if "%OLD%"=="NUL" goto Update

if %NET%==0 goto Update

rem Grab date from remote Unified Hosts
if not "%URLD%"=="" (
	if !QUIET!==1 (
		call :Download %URLD% "%CTEMP%" benchmark || goto Failed_Download
	) else call :Execute %DOWNLOADER_FROM% %URLD% %DOWNLOADER_TO% %Q%%CTEMP%%Q% || goto Downloader_Connectivity
	if !NET!==0 goto Update
	for /f "tokens=*" %%0 in (
		'findstr /b "#.Date:. #.Fetch.the.latest.version.of.this.file:.%BASE%/....." "%CTEMP%"'
	) do (
		set LINE=%%0
		if "!LINE:~,8!"=="# Date: " set NEW=%%0
	)
) else set NEW=NUL

rem If the ignore list, custom list, or compression level is not applied to the hosts file, upate
if !HASH!==1 if not "!NEWIGNORE!!NEWCUSTOM!!NEWCOMP!"=="!OLDIGNORE!!OLDCUSTOM!!OLDCOMP!" (
	call :Echo "Your current ignore list, custom list, or compression level needs to be applied."
	goto Update
)

rem If the remote and local dates and URLs are not the same, update
if "%OLD%"=="%NEW%" (
	if !QUIET!==1 goto Exit
	call :Echo "You already have the latest version."
	choice.exe /M "Would you like to update anyway?"
	if !errorlevel!==2 goto Exit
) else call :Echo "A new Unified Hosts update is available^^^!"

rem Function to update current local hosts with current Unified Hosts
:Update

if not !QUIET!==1 (

	if "%URL:~-6%"=="/hosts" (
		call :Echo "Your current preset is to use the following Unified Hosts:" ^
		"%URL%"
		choice.exe /m "Would you like to just stick with that?"
		if !errorlevel!==1 goto Skip_Choice
	)

	call :Echo "The Unified Hosts will automatically block malware and adware."
	choice.exe /m "Would you also like to block other categories?"
	if !errorlevel!==1 (

		set CAT=

		choice.exe /m "Would you also like to block fake news?"
		if !errorlevel!==1 set CAT=_fakenews_

		choice.exe /m "Would you also like to block gambling?"
		if !errorlevel!==1 set CAT=!CAT!_gambling_

		choice.exe /m "Would you also like to block porn?"
		if !errorlevel!==1 set CAT=!CAT!_porn_

		choice.exe /m "Would you also like to block social?"
		if !errorlevel!==1 set CAT=!CAT!_social_

		if not "!CAT!"=="" (
			set CAT=!CAT:__=-!
			set CAT=!CAT:_=!
			set URL=%BASE%/alternates/!CAT!/hosts
		) else set URL=%BASE%/hosts
	) else set URL=%BASE%/hosts
)

:Skip_Choice

if not !QUIET!==1 (
	call :Echo "Your hosts file can be from 1 to 9 domains per line." ^
	"1 is standard, more than 1 is a level of compression." ^
	"If you choose a level of compression, please expect the update to take longer." ^
	"Your current compression level is %OLDCOMP%."
	choice.exe /m "Would you like to just stick with that?"
	if !errorlevel!==2 (
		choice.exe /c 123456789 /n /m "New compression level?"
		set NEWCOMP=!errorlevel!
	) else set NEWCOMP=%OLDCOMP%
)

if %NET%==0 goto Skip_Hosts_Update

if /i "%URLD%"=="remove" (
	call :Echo "Removing the Unified Hosts from the hosts file..."
	call :File 1
) else (
	call :Echo "Updating the hosts file..."
	call :File 0
)
call :Flush

:Skip_Hosts_Update

if not !QUIET!==1 (
	if !TASK!==1 (
		call :Echo "You currently have a scheduled task already in place" ^
		"Creating a new one will overwrite the previous task with your new settings"
		call :Schedule
	)
	if !TASK!==0 (
		call :Echo "You don't have a scheduled task to automatically update daily"
		if %NET%==0 (
			call :Echo "Please remember, you are currently in interactive offline mode" ^
			"Without a scheduled task, this script will not perform any changes"
		)
		call :Schedule
	)
	if !TASK!==2 (
		call :Echo "Your version of Windows isn't compatible with this script's task scheduler" ^
		"In your task scheduler, schedule a task to execute this script" ^
		"Following the script's path, send the URL of the blacklist you want:" ^
		""%SELF%" %URL%"
		choice.exe /m "Would you like to open the Task Scheduler now?"
		if !errorlevel!==1 start taskschd.msc
	)
	goto View_Hosts
)
goto Exit

rem File writing function
:File

rem If updating/installing, download the target hosts file to cache if not already downloaded
if %1==0 if not "%URLD%"=="%URL%" (
	if !QUIET!==1 set URL=%URLD%
	call :Download !URL! "%CTEMP%" hosts || goto Failed_Download
)

rem To be disabled later to skip old hosts section, and then re-enable to continue after #### END UNIFIED HOSTS ####
set WRITE=1

rem Categorize line as comment or domain
set TYPE=

rem Previous line category
set PTYPE=

rem If compression is enabled, don't compress until the end of the Unified Hosts header
set COUNT1=0

rem Count domains while building globs
set COUNT2=0

rem Variable to store globbed line
set GLOB=

rem Rewrite the hosts file to a temporary file and inject new Unified Hosts after #### BEGIN UNIFIED HOSTS ####
rem Filter Unified Hosts to remove white space and entries from ignore list
(
	for /f "tokens=1* delims=:" %%a in (
		'findstr /n .* "%HOSTS%"'
	) do (
		if !WRITE!==1 (
			if "%%b"=="" (echo.) else (
				if /i not "%%b"=="#### BEGIN UNIFIED HOSTS ####" echo %%b
			)
			if /i "%%b"=="#### BEGIN UNIFIED HOSTS ####" (
				if %1==0 (
					echo %%b
					echo # Managed by ScriptTiger's Unified Hosts AutoUpdate
					echo # https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate
					if !HASH!==1 (
						echo # Ignore list: %NEWIGNORE%
						echo # Custom list: %NEWCUSTOM%
						echo # Compression: %NEWCOMP%
					)
					echo #
					for /f "tokens=1,2*" %%0 in (
						'findstr /l /v /g:"%IGNORE%" "%CTEMP%"'
					) do (
						set WORD1=%%0
						set WORD2=%%1
						if "%%2"=="" (
							set LINE=%%0 %%1
						) else set LINE=%%0 %%1 %%2
						if "!LINE!"=="# Custom host records are listed here." set COUNT1=1
						if !COUNT1! geq 1 (
							if !NEWCOMP! geq 2 (
								call :Compress
							) else echo !LINE!
						) else echo !LINE!
					)
					if "!PTYPE!"=="COMMENT" echo !GLOB:~1!
					if "!PTYPE!"=="DOMAIN" echo 0.0.0.0!GLOB!
				)
				set WRITE=0
			)
		)
		if /i "%%b"=="#### END UNIFIED HOSTS ####" (
			if %1==0 (
				echo #
				type "%CUSTOM%"
				for /f "tokens=1* delims=:" %%0 in ('findstr /n .* "%CUSTOM%"') do set NTF=%%1
				if not "!NTF!"=="" echo.
				echo %%b
			)
			set WRITE=1
		)
	)
) > "%CHOSTS%"

rem Wait some time to make sure all the processes are done accessing the hosts
rem Overwrite the old hosts with the new one
timeout /t 3 /nobreak > nul

:Write
call :Execute copy "%CHOSTS%" "%HOSTS%" /y

rem Make sure the hosts file was placed correctly and take action accordingly
if !errorlevel!==0 (
	if %1==1 (
		call :Echo "The Unified Hosts has been removed"
	) else (
		call :Echo "Your Unified Hosts has been updated"
	)
) else (
	call :Echo "WARNING: There was a problem writing to your hosts file" ^
	"The two most common causes are:" ^
	"1.] It is being used by another application" ^
	"2.] It is intentionally locked by an antivirus or similar application"
	if not !QUIET!==1 (
		choice.exe /m "Would you like to try writing to your hosts file again?"
		if !errorlevel!==1 goto Write
	)
)
exit /b

rem Compression function
:Compress
if "!WORD1:~,1!"=="#" set TYPE=COMMENT
if "!WORD1!"=="0.0.0.0" set TYPE=DOMAIN
if not "!TYPE!"=="!PTYPE!" (
	if "!GLOB:~,2!"==" #" (
		echo !GLOB:~1!
	) else (
		if not "!GLOB!"=="" echo 0.0.0.0!GLOB!
	)
	set COUNT2=0
	set GLOB=
)
if "!TYPE!"=="COMMENT" (
	set GLOB=!GLOB! !LINE!
	set COUNT2=0
)
if "!TYPE!" == "DOMAIN" (
	set GLOB=!GLOB! !WORD2!
	set /a COUNT2=!COUNT2!+1
	if !COUNT2!==!NEWCOMP! (
		echo 0.0.0.0!GLOB!
		set GLOB=
		set COUNT2=0
	)
)
set PTYPE=!TYPE!
set TYPE=
exit /b

rem Schedule task function
:Schedule
choice.exe /m "Would you like to create a new scheduled task now?"
if !errorlevel!==2 exit /b
if !TASK!==1 call :Unschedule
(
	echo ^<?xml version="1.0" encoding="UTF-16"?^>
	echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
	echo ^<RegistrationInfo^>
	echo ^<URI^>\%TN%^</URI^>
	echo ^</RegistrationInfo^>
	echo ^<Triggers^>
	echo ^<CalendarTrigger^>
	echo ^<StartBoundary^>2000-01-01T03:00:00^</StartBoundary^>
	echo ^<ExecutionTimeLimit^>PT30M^</ExecutionTimeLimit^>
	echo ^<Enabled^>true^</Enabled^>
	echo ^<ScheduleByDay^>
	echo ^<DaysInterval^>1^</DaysInterval^>
	echo ^</ScheduleByDay^>
	echo ^</CalendarTrigger^>
	echo ^</Triggers^>
	echo ^<Principals^>
	echo ^<Principal id="Author"^>
	echo ^<UserId^>S-1-5-18^</UserId^>
	echo ^<RunLevel^>HighestAvailable^</RunLevel^>
	echo ^</Principal^>
	echo ^</Principals^>
	echo ^<Settings^>
	echo ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
	echo ^<DisallowStartIfOnBatteries^>true^</DisallowStartIfOnBatteries^>
	echo ^<StopIfGoingOnBatteries^>true^</StopIfGoingOnBatteries^>
	echo ^<AllowHardTerminate^>true^</AllowHardTerminate^>
	echo ^<StartWhenAvailable^>true^</StartWhenAvailable^>
	echo ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
	echo ^<IdleSettings^>
	echo ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
	echo ^<RestartOnIdle^>false^</RestartOnIdle^>
	echo ^</IdleSettings^>
	echo ^<AllowStartOnDemand^>true^</AllowStartOnDemand^>
	echo ^<Enabled^>true^</Enabled^>
	echo ^<Hidden^>false^</Hidden^>
	echo ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^>
	echo ^<WakeToRun^>false^</WakeToRun^>
	echo ^<ExecutionTimeLimit^>PT30M^</ExecutionTimeLimit^>
	echo ^<Priority^>7^</Priority^>
	echo ^</Settings^>
	echo ^<Actions Context="Author"^>
	echo ^<Exec^>
	echo ^<Command^>%CMD%^</Command^>
	echo ^<Arguments^>%URL% %NEWCOMP%^</Arguments^>
	echo ^<WorkingDirectory^>%CMDDIR%^</WorkingDirectory^>
	echo ^</Exec^>
	echo ^</Actions^>
	echo ^</Task^>
) > "%CTEMP%"
schtasks /create /ru "SYSTEM" /tn "%TN%" /xml "%CTEMP%"
set TASK=1
exit /b

:Unschedule
schtasks /delete /tn "%TN%" /f
set TASK=0
exit /b

rem Flush the DNS cache
:Flush
call :Echo "Flushing local DNS cache..."
call :Execute ipconfig /flushdns
exit /b

rem Ask to see hosts file before exiting
:View_Hosts
rem If running in interactive offline mode and a scheduled task exists, run task before opening notepad
if !NET!==0 if !TASK!==1 goto Run

choice.exe /m "Would you like to open your current hosts file before exiting?"
if !errorlevel!==2 goto Exit
call :View_TextFile "%HOSTS%"
goto Exit

rem Function to view text files
:View_TextFile
set PROGID=
set CMDVIEWTEXT=
call :Execute reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.txt\UserChoice /v PROGID
if !errorlevel!==0 (
	for /f "tokens=3" %%a in (
		'reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.txt\UserChoice /v PROGID'
	) do set PROGID=%%a
	if "!PROGID:~,13!"=="Applications\" (
		for /f "tokens=2*" %%a in (
			'reg query HKCR\!PROGID!\shell\open\command'
		) do set CMDVIEWTEXT=%%b
	) else (
		for /f "tokens=2 delims==" %%a in (
			'ftype !PROGID!'
		) do set CMDVIEWTEXT=%%a
	)
	for /f "tokens=* usebackq" %%a in (
		`echo "!CMDVIEWTEXT:%%1=%1!"`
	) do start "" %%~a
) else start notepad %1
exit /b

rem Function to handle script exits
:Exit
rem Clean up temporary files if they exist
if exist "%CACHE%" (
	call :Echo "Cleaning temporary files..."
	if not exist "%LOCK%" echo ----->>"%LOG%"
	rmdir /s /q "%CACHE%"
)

rem Display any error dialog if applicable
if not %EXIT%==0 (
	if %QUIET%==1 (
		(
			echo ***** Unified Hosts AutoUpdate *****
			echo.
			echo ERROR: %ERROR%^^!
			echo.
			if not "%LOG%"=="nul" (
				echo Refer to your log file for more information:
				echo "%LOG%"
			) else echo Refer to the README for debugging tips, such as using the /log argument.
		) | msg * /time:86400
	) else (
		if "%LOG%"=="nul" (
			echo Refer to the README for debugging tips, such as using the /log argument.
			if %DFC%==0 pause
		) else (
			choice.exe /m "Would you like to open your log file before exiting?"
			if !errorlevel!==1 call :View_TextFile "%LOG%"
		)
	)
)

rem Set the DFC switch if applicable
if %DFC%==1 set EXIT=/b %EXIT%

rem If not locked and a downloaded update is available, replace the old script with the new one and exit
if exist "%LOCK%" (del /q "%LOCK%"
) else if exist "%UPDATE%" del /q "%CMDDIR%%CMD%"&ren "%UPDATE%" "%CMD%"&exit %EXIT%
exit %EXIT%

rem Function for running a scheduled task from script before exiting
:Run
rem Lock the running script from being replaced by an update during the triggered task
rem Unlock later and replace running script with update if exists before exit
echo "%LOG:"=%">"%LOCK%"
call :Echo "Activating update task..."
schtasks /run /tn "%TN%"
call :Echo "Update task is running..."
:Run_Wait
timeout /t 5 /nobreak > nul
if not exist "%LOCK%" (
	call :Echo "Update task has completed"
	set TASK=3
	goto View_Hosts
)
goto Run_Wait

rem Function to handle downloads
:Download
set DOWNLOAD=%1
set RETRY=0
set TIMER=10
:Retry
call :Execute %DOWNLOADER_FROM% %1 %DOWNLOADER_TO% %Q%%~2%Q% && (call :Echo "Downloaded %3 successfully" & exit /b)
if !RETRY!==6 exit /b 1
set /a RETRY=!RETRY!+1
call :Echo "Waiting !TIMER! seconds before retry..."
set /a TIMER=!TIMER!*2
timeout /t !TIMER! /nobreak > nul
call :Echo "Download Retry !RETRY!: %3..."
goto Retry

rem Function to handle script output
:Echo
echo %~1>con
echo %DATE% @ %TIME%: %~1>>"%LOG%"
shift
if not "%~1"=="" goto Echo
exit /b

rem Function to log executions
:Execute
echo %DATE% @ %TIME%: Executing: %*>>"%LOG%"
%*>>"%LOG%" || exit /b 1
exit /b

rem Error handling functions

:Connectivity
call :Echo "Your system cannot connect to %GHD%^^^!"
if !QUIET!==1 (
	set ERROR=Your system cannot connect to %GHD%
	set EXIT=5
	goto Exit
)
call :Echo "You are now in interactive offline mode"
set NET=0
goto Skip_Script_Update

:Downloader
call :Echo "Neither BITS nor PowerShell can be found" ^
"This script requires either BITS or PowerShell in order to function"
set ERROR=Neither BITS nor PowerShell installed
set EXIT=6
goto Exit

:Downloader_Connectivity
call :Echo "%DOWNLOADER% cannot connect to %GHD%^^^!"
if !QUIET!==1 (
	set ERROR=D%DOWNLOADER% cannot connect to %GHD%
	set EXIT=7
	goto Exit
)
call :Echo "You are now in interactive offline mode"
set NET=0
goto Skip_Script_Update

:Failed_Download
call :Echo "%DOWNLOADER% failed downloading %DOWNLOAD%^^^!"
set ERROR=%DOWNLOADER% failed downloading %DOWNLOAD%
set EXIT=8
goto Exit

:Admin
call :Echo "You must run this with administrator privileges^^^!"
set ERROR=Must be run with administrative permissions
set EXIT=1
goto Exit

:Mark
if !MARKED!==-1 (
	call :Echo ""#### END UNIFIED HOSTS ####" not properly marked in hosts file^^^!"
	set ERROR="""#### END UNIFIED HOSTS ####""" not properly marked in hosts file
	set EXIT=2
) else (
	set ERROR=Hosts file is not properly marked
	set EXIT=3
)
call :Echo "Hosts file is not properly marked" ^
"Please ensure the following lines mark where to insert the blacklist:" ^
"#### BEGIN UNIFIED HOSTS ####" ^
"#### END UNIFIED HOSTS ####" ^
"Notes: You should only have to mark this once" ^
"Updates automatically overwite between the above lines"
if not !QUIET!==1 goto View_Hosts
goto Exit
