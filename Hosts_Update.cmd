@echo off

rem Check for admin rights, and exit if none present
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\Prefetch\" || goto Admin

rem Enable delayed expansion to be used during for loops and other parenthetical groups
setlocal ENABLEDELAYEDEXPANSION

rem Set Resource and target locations
set VERSION=%~dp0VERSION
set IGNORE=%~dp0ignore.txt
set README=%~dp0README.md
set SELF=%~0
set GH=https://raw.githubusercontent.com/ScriptTiger/Unified-Hosts-AutoUpdate/master
set WGETP=%~dp0wget\x!PROCESSOR_ARCHITECTURE:~-2!\wget.exe
set WGET="%WGETP%" -O- -q -t 0 --retry-connrefused -c -T 0
set HOSTS=C:\Windows\System32\drivers\etc\hosts
set BASE=https://raw.githubusercontent.com/StevenBlack/hosts/master
set TASKER=C:\Windows\System32\schtasks.exe
set XML=%TEMP%UHAU.xml

rem Check if script is returning from being updated and finish update process
if "%1"=="/U" (
	cls
	echo The updated script has been loaded
	echo %NEW%>"%VERSION%"
	%WGET% %GH%/README.md | more > "%README%"
	set UPDATE=1
) else (
	rem If the URL is sent as a parameter, set the URL variable and turn the script to quiet mode with no prompts
	rem Initialize QUIET to off/0

	set QUIET=0
	if not "%1"=="" (
		set URL=%1
		set QUIET=1
	)
)

rem Make sure Wget can be found
if not exist "%WGETP%" goto Wget

rem Begin version checks
echo Checking for script updates...

rem Grab remote script version
rem On error, report connectivity problem
(for /f %%0 in ('%WGET% %GH%/VERSION') do set NEW=%%0) || goto Connectivity

rem Check for emergency stop status
if "%NEW:~,1%"=="X" (
	echo.
	echo **We are currently working to fix a problem**
	echo **Please try again later**
	if not !QUIET!==1 pause
	exit
)

rem Grab local script version
set /p OLD=<"%VERSION%"

rem Strip out emergency status if present in local version
if "%OLD:~,1%"=="X" (
	echo %OLD:~1%>"%VERSION%"
)

rem If the versions don't match, automatically update and continue with updated script
if not "%OLD%"=="%NEW%" (
	echo A new script update is available^^!
	echo Updating script...
	timeout /t 3 /nobreak > nul&%WGET% %GH%/Hosts_Update.cmd | more > "%~0"&timeout /t 3 /nobreak > nul&"%~0" /U
) else echo Your script is up to date

rem Check to see if the Windows version is compatible with the scripted scheduler
rem Check to see if there is currently a scheduled update task
rem If there is, ask if they want to keep it
if not !QUIET!==1 (
	if exist "%TASKER%" (
		set TASK=0
		for /f "tokens=*" %%0 in ('schtasks ^| findstr "Unified Hosts AutoUpdate"') do set TASK=1
		if !TASK!==1 (
			echo You currently have a scheduled task already in place
			choice /m "Would you like to keep it?"
			if !errorlevel!==2 schtasks /delete /tn "Unified Hosts AutoUpdate" /f
		)
	) else (
		set TASK=2
	)
)

rem If the ignore list doesn't exist, make one
rem This CANNOT be empty
if not exist "%IGNORE%" (
	(
		echo # Ignore list written in literal expressions
		echo # These changes will take effect the next time the Unified Hosts is updated
		echo # To force changes now, run Hosts_Update.cmd with the "update anyway" option
		echo # If you decide to delete the below entries, DO NOT delete these above comment lines
		echo # If this file is left completely empty, the script will break
		echo 127.0.0.1 localhost
		echo 127.0.0.1 localhost.localdomain
		echo 127.0.0.1 local
		echo 255.255.255.255 broadcasthost
		echo ::1 localhost
		echo fe80::1%%lo0 localhost
		echo 0.0.0.0 0.0.0.0
	) > "%IGNORE%"
)

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
	echo The Unified Hosts has not yet been marked in your local hosts file
	if not !QUIET!==1 (
		choice /m "Automatically insert the Unified Hosts at the bottom of your local hosts?"
		if !ERRORLEVEL!==2 goto Mark
	)
	for /f "tokens=1* delims=:" %%0 in ('findstr /n .* "%HOSTS%"') do set NTF=%%1
	if not "!NTF!"=="" echo.>>"%HOSTS%"
	echo #### BEGIN UNIFIED HOSTS ####>>"%HOSTS%"
	echo #### END UNIFIED HOSTS ####>>"%HOSTS%"
	goto update
)

if !MARKED!==2 (
	echo The Unified Hosts is already installed in your local hosts file
	if not !QUIET!==1 (
		choice /M "Would you like to continue to update it?"
		if !errorlevel!==2 (
			choice /M "Would you like to remove the Unified Hosts from your local hosts file?"
			if !errorlevel!==1 (
				set REMOVE=1
				call :File
				echo The Unified Host has been removed
				call :Flush
				goto Notepad
			)
			exit
		)
	)
) else (goto Mark)

echo Checking for Unified Hosts updates...

rem Initialize OLD to NUL in case markings are present but not Unified Hosts
set OLD=NUL

rem rem Grab date and URL from the Unified Hosts inside of the local hosts file
for /f "tokens=*" %%0 in (
	'findstr /b "#.Date: #.Fetch.the.latest.version.of.this.file:" "%HOSTS%"'
) do (
	set LINE=%%0
	if "!LINE:~,8!"=="# Date: " set OLD=%%0
	if "!LINE:~,8!"=="# Fetch " (
		set OLD=!OLD!%%0
		if not !QUIET!==1 (
			set URL=%%0
			set URL=!URL:~41!
		)
	)
)

rem If the markings are there but no Unified Hosts, skip the rest of the check and continue to update
if "%OLD%"=="NUL" goto Update

rem Grab date and URL from remote Unified Hosts
for /f "tokens=*" %%0 in (
	'^(%WGET% %URL% ^| findstr /b "#.Date: #.Fetch.the.latest.version.of.this.file:"^)'
) do (
	set LINE=%%0
	if "!LINE:~,8!"=="# Date: " set NEW=%%0
	if "!LINE:~,8!"=="# Fetch " set NEW=!NEW!%%0
)

rem If the remote and local dates and URLs are not the same, update
if "%OLD%"=="%NEW%" (
	if !QUIET!==1 exit
	echo You already have the latest version.
	choice /M "Would you like to update anyway?"
	if !errorlevel!==2 exit
) else (
	echo A new Unified Hosts update is available^^!
)

rem Function to update current local hosts with current Unified Hosts
:Update

if not !QUIET!==1 (

	if "%URL:~-6%"=="/hosts" (
		echo Your current preset is to use the following Unified Hosts:
		echo %URL%
		choice /m "Would you like to just stick with that?"
		if !errorlevel!==1 goto Skip_Choice
	)

	echo The Unified Hosts will automatically block malware and adware.
	choice /m "Would you also like to block other categories?"
	if !errorlevel!==1 (

		set CAT=

		choice /m "Would you also like to block fake news?"
		if !errorlevel!==1 set CAT=_fakenews_

		choice /m "Would you also like to block gambling?"
		if !errorlevel!==1 set CAT=!CAT!_gambling_

		choice /m "Would you also like to block porn?"
		if !errorlevel!==1 set CAT=!CAT!_porn_

		choice /m "Would you also like to block social?"
		if !errorlevel!==1 set CAT=!CAT!_social_

		if not "!CAT!"=="" (
			set CAT=!CAT:__=-!
			set CAT=!CAT:_=!
			set URL=%BASE%/alternates/!CAT!/hosts
		) else (set URL=%BASE%/hosts)
	) else (set URL=%BASE%/hosts)
)

rem If the URL is still not complete by this point, just set the default as the basic Unified Hosts with no extensions
if not "%URL:~-6%"=="/hosts" set URL=%BASE%/hosts

:Skip_Choice

echo Updating the hosts file...
call :File

echo Your Unified Hosts has been updated
call :Flush

if not !QUIET!==1 (
	if !TASK!==0 call :Schedule
	if !TASK!==2 (
		echo Your version of Windows isn't compatible with this script's task scheduler
		echo In your task scheduler, schedule a task to execute this script
		echo Following the script's path, send the URL of the blacklist you want:
		echo "%~0" %URL%
		choice /m "Would you like to open the Task Scheduler now?"
		if !errorlevel!==1 start taskschd.msc
	)
	goto Notepad
)
exit

rem File writing function
:File

rem To be disabled later to skip old hosts section, and then re-enable to continue after #### END UNIFIED HOSTS ####
set WRITE=1

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
				if not !REMOVE!==1 (
					echo %%b
					for /f "tokens=*" %%0 in (
						'^(%WGET% %URL% ^| findstr /l /v /g:"%IGNORE%"^)'
					) do @echo %%0
				)
				set WRITE=0
			)
		)
		if /i "%%b"=="#### END UNIFIED HOSTS ####" (
			if not !REMOVE!==1 echo %%b
			set WRITE=1
		)
	)
) > %TEMP%hosts

rem Wait some time to make sure all the processes are done accessing the hosts
rem Overwrite the old hosts with the new one
timeout /t 3 /nobreak > nul
copy "%TEMP%hosts" "%HOSTS%" /y > nul

exit /b

rem Schedule task function
:Schedule
echo You don't yet have a scheduled task to automatically update daily
choice /m "Would you like to create a scheduled task now?"
if !errorlevel!==2 exit /b
(
	echo ^<?xml version="1.0" encoding="UTF-16"?^>
	echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
	echo ^<RegistrationInfo^>
	echo ^<URI^>\Unified Hosts AutoUpdate^</URI^>
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
	echo ^<Command^>"%SELF%"^</Command^>
	echo ^<Arguments^>%URL%^</Arguments^>
	echo ^</Exec^>
	echo ^</Actions^>
	echo ^</Task^>
) > "%XML%"
schtasks /create /ru "SYSTEM" /tn "Unified Hosts AutoUpdate" /xml "%XML%"
exit /b

rem Flush the DNS cache
:Flush
echo Flushing local DNS cache...
ipconfig /flushdns > nul
exit /b

rem Ask to see hosts file before exiting
:Notepad
choice /m "Would you like to open your current hosts file before exiting?"
if !errorlevel!==1 start notepad "%HOSTS%"
exit

rem Error handling functions

:Connectivity
echo.
echo This script cannot connect to the Internet^^!
echo This script requires and active Internet connection to update your hosts file^^!
if not !QUIET!==1 pause
exit

:Wget
echo Wget cannot be found
echo You can do either of the following
echo 1.] Put the Wget directory in the same directory as this script
echo 2.] Edit the "WGETP" variable of this script
if not !QUIET!==1 pause
exit

:Admin
echo You must run this with administrator privileges!
if not !QUIET!==1 pause
exit

:Mark
if !MARKED!==-1 echo "#### END UNIFIED HOSTS ####" not properly marked in hosts file^^!
echo.
echo Hosts is not properly marked
echo Please ensure the following lines mark where to insert the blacklist:
echo.
echo #### BEGIN UNIFIED HOSTS ####
echo #### END UNIFIED HOSTS ####
echo.
echo Notes: You should only have to mark this once
echo Updates automatically overwite between the above lines
if not !QUIET!==1 goto Notepad
exit
