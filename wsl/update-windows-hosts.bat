@echo off

set SCRIPT_FILE=%0
set SCRIPT_DIR=%~dp0
set SOURCE_HOSTS=%SCRIPT_DIR%..\..\..\temp\windows-etc-hosts
set TARGET_HOSTS=%WINDIR%\System32\drivers\etc\hosts

set SHORTCUT_DIR=%USERPROFILE%\Desktop
set SHORTCUT_FILE=%SHORTCUT_DIR%\Sync WSL-Workspace hosts.lnk
set SHORTCUT_WORK_DIR=%SCRIPT_DIR%
if "%SHORTCUT_WORK_DIR:~-1%" == "\" (
    set SHORTCUT_WORK_DIR=%SHORTCUT_WORK_DIR:~0,-1%
)

set ICON_DIR=%USERPROFILE%\ico
set ICON_BASENAME=refresh.ico
set ICON_FILE=%ICON_DIR%\%ICON_BASENAME%

if not exist "%SHORTCUT_FILE%" (
    if not exist "%ICON_DIR%\" (
        echo Creating directory "%ICON_DIR%\"
        md "%ICON_DIR%\"
    )
    if not exist "%ICON_FILE%" (
        echo Copiando "%ICON_FILE%"
        copy "%SCRIPT_DIR%\%ICON_BASENAME%" "%ICON_FILE%"
    )

    if not exist "%SHORTCUT_DIR%\" (
        echo Creating directory "%SHORTCUT_DIR%\"
        md "%SHORTCUT_DIR%\"
    )
    echo Creating desktop shorcut
    "%SCRIPT_DIR%\shortcut.exe" /A:C /F:"%SHORTCUT_FILE%" /I:"%ICON_FILE%" /T:"%SCRIPT_FILE%" /W:"%SHORTCUT_WORK_DIR%"
)

if not exist "%SOURCE_HOSTS%" (
    echo ERROR: File not found, %SOURCE_HOSTS%
    pause
    goto END
)

copy "%SOURCE_HOSTS%" "%TARGET_HOSTS%"

:END
