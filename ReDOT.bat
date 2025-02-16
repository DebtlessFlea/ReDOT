@echo off
setlocal enabledelayedexpansion

title ReDOT v1.0

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb runAs" >nul 2>&1
    exit /b
)
echo Running as administrator.
echo.

cd /d "%~dp0"

if not exist settings.ini (
    echo No settings found! Creating settings.ini...
    echo %CD% > settings.ini
)

echo Launching settings window.
start /wait notepad settings.ini

echo.
echo Available directories:
set /a index=0
for /f "delims=" %%d in (settings.ini) do (
    set /a index+=1
    set "line=%%d"
    if "!line:~-1!"=="\" set "line=!line:~0,-1!"
    if not exist "!line!" (
         echo Directory "!line!" was not found.
         pause
         exit /b
    )
    set "dir[!index!]=!line!"
    echo !index!. !line!
)
if %index%==0 (
    echo No directories found in settings.ini. Using script directory.
    echo %CD% > settings.ini
    set /a index=1
    set "dir[1]=%CD%"
    set "line=%CD%"
    if "%line:~-1%"=="\" set "line=%line:~0,-1%"
    echo 1. !line!
)

set /a check_all_index=index+1
echo !check_all_index!. [Check all directories]

echo.
set /p dir_choice="Select a directory number: "
if "%dir_choice%"=="%check_all_index%" goto check_all
if not defined dir[%dir_choice%] (
    echo Invalid directory selection.
    pause
    goto cleanup
)

call set "target_dir=%%dir[%dir_choice%]%%"
if not exist "%target_dir%" (
    echo Directory does not exist: "%target_dir%"
    pause
    goto cleanup
)

set /p file_pattern="Enter the extension to search (e.g., .mp3): "
goto extension_mode

:check_all
echo.
set /p file_pattern="Enter the extension to search (e.g., .mp3): "
set "found_any=0"
echo Checking all directories for !file_pattern!...
for /l %%i in (1,1,%index%) do (
    if defined dir[%%i] (
        set "current_dir=!dir[%%i]!"
        pushd "!current_dir!" 2>nul
        dir /b /a-d "*!file_pattern!" 2>nul | findstr /r /c:"." >nul && (
            echo Found in: !current_dir!
            set "found_any=1"
        )
        popd
    )
)
if !found_any! equ 0 (
    echo No matching files found in any directory.
    pause
    goto cleanup
)

echo.
set /p rename_all="Rename matching files in these directories? (Y/N): "
if /i "!rename_all!"=="Y" (
    if "!file_pattern:~0,1!"== "." (
         set /p new_extension="Enter new extension (.opus): "
         for /l %%i in (1,1,%index%) do (
             if defined dir[%%i] (
                 set "current_dir=!dir[%%i]!"
                 pushd "!current_dir!" 2>nul
                 dir /b /a-d "*!file_pattern!" > "%temp%\filelist.txt"
                 for /f "delims=" %%F in (%temp%\filelist.txt) do (
                      ren "%%F" "%%~nF!new_extension!"
                 )
                 popd
             )
         )
    ) else (
         echo The extension must start with a dot.
         pause
         goto cleanup
    )
    echo Renaming complete.
)
pause
goto cleanup

:extension_mode
echo.
echo Scanning for files ending with !file_pattern! in "%target_dir%"...
pushd "%target_dir%"
set "found=0"
for /f "delims=" %%F in ('dir /b /a-d *!file_pattern! 2^>nul') do (
    set /a found+=1
)
popd
if !found! equ 0 (
    echo No files ending with !file_pattern! were found in "%target_dir%".
    pause
    goto cleanup
)
echo Found !found! file(s) ending with !file_pattern!.
echo.
set /p new_extension="Enter new extension (.opus): "

call :rename "%target_dir%" "!file_pattern!" "!new_extension!"
echo Renaming complete.
goto cleanup

:rename
pushd %~1
for /f "delims=" %%F in ('dir /b /a-d *%~2 2^>nul') do (
    ren "%%F" "%%~nF%~3"
)
popd
exit /b

:cleanup
echo.
set /p del_choice="Do you want to delete the settings.ini file? (Y/N): "
if /I "%del_choice%"=="Y" (
    echo Deleting settings file...
    del settings.ini
) else (
    echo Keeping settings file.
)
pause
exit /b
