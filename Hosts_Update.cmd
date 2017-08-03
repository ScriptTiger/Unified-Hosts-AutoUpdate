@echo off

rem Check for admin rights, and exit if none present
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\Prefetch\" || goto Admin

rem Enabledelayed expansion to be used during for loops
setlocal ENABLEDELAYEDEXPANSION

rem Set Resource and target locations
set WGETP=%~dp0wget\x!PROCESSOR_ARCHITECTURE:~-2!\wget.exe
set WGET="%WGETP%" -O- -q -t 0 --retry-connrefused -c -T 0
set HOSTS=C:\Windows\System32\drivers\etc\hosts

rem If the URL is not sent to the script as a parameter, set the base URL and make the script interactive
if "%1"=="" (set URL=https://raw.githubusercontent.com/StevenBlack/hosts/master) else (set URL=%1)

rem Make sure Wget can be found
if not exist "%WGETP%" goto Wget

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
	if "%1"=="" (
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
	if "%1"=="" (
		choice /M "Would you like to continue to update it?"
		if !errorlevel!==2 (
			choice /M "Would you like remove the Unified Hosts from your local hosts file?"
			if !errorlevel!==1 goto Remove
			)
		)
	) else (goto Mark)

echo Checking Unified Hosts version...

rem Grab date from remote Unified Hosts
for /f "tokens=*" %%0 in ('%WGET% %URL%/hosts ^| findstr #.Date:') do set NEW=%%0

rem rem Grab date from the Unified Hosts inside of the local hosts file
for /f "tokens=*" %%0 in ('findstr #.Date: "%HOSTS%"') do set OLD=%%0

rem If the remote and local dates are not the same, update
if "%OLD%"=="%NEW%" (
	if not "%1"=="" exit
	echo You already have the latest version.
	choice /M "Would you like to update anyway?"
	if !errorlevel!==1 (goto Update) else (exit)
) else (
	echo Your version is out of date
	
goto Update
)

:Wget
echo Wget cannot be found
echo You can do either of the following
echo 1.] Put the Wget directory in the same directory as this script
echo 2.] Edit the "WGETP" variable of this script
if "%1"=="" pause
exit

:Admin
echo You must run this with administrator privileges!
if "%1"=="" pause
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
if "%1"=="" pause
exit

:Remove
set REMOVE=1
call :File
echo The Unified Host has been removed
if "%1"=="" pause
exit

:Update

rem If the generic URL is in place and not a specific one, prompt the user to select one
if not "%URL:~-6%"=="/hosts" (

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
			set URL=!URL!/alternates/!CAT!
			)
		set URL=!URL!/hosts
	) else (set URL=!URL!/hosts)
)

echo Updating the hosts file...
call :File

echo Your Unified Hosts has been updated
if "%1"=="" pause
exit

rem File writing function
:File

rem To be disabled later to skip old hosts section, and then re-enable to continue after #### END UNIFIED HOSTS ####
set WRITE=1

rem Rewrite the hosts file to a temporary file and inject new Unified Hosts after #### BEGIN UNIFIED HOSTS ####
rem Filter Unified Hosts to remove localhost/loopback entries, invalid entries, and white space
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
						'^(%WGET% %URL% ^| findstr /b /r /v "127[.]0[.]0[.]1 255[.]255[.]255[.]255 ::1 fe80:: 0[.]0[.]0[.]0.[0-9][0-9]*[.][0-9][0-9]*[.][0-9][0-9]*[.][0-9][0-9]*"^)'
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

rem Overwrite the old hosts with the new one
copy "%TEMP%hosts" "%HOSTS%" /y > nul

exit /b