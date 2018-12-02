@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

call %~dp0_test-prepare.cmd flash

echo Compiling...
haxe %~dp0..\tests.hxml ^
  -D no-swf-compress ^
  -D swf-script-timeout=180 ^
  -swf-version 11.5 ^
  -swf target\flash\TestRunner.swf
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

REM enable Flash logging
(
    echo ErrorReportingEnable=1
    echo TraceOutputFileEnable=1
) > "%HOME%\mm.cfg"

REM add the flash target directory as trusted source to prevent "Only trusted local files may cause the Flash Player to exit."
call :normalize_path %~dp0..\target
set target_dir_absolute=%RETVAL%
(
    echo %target_dir_absolute%\flash
) > "%HOME%\AppData\Roaming\Macromedia\Flash Player\#Security\FlashPlayerTrust\HaxeDoctest.cfg"

echo Testing...
for /f "delims=" %%A in ('where flashplayer_*_sa_debug.exe') do set "flashplayer_path=%%A"
%flashplayer_path% "%~dp0..\target\flash\TestRunner.swf"
set rc=%errorlevel%

REM printing log file
type "%HOME%\AppData\Roaming\Macromedia\Flash Player\Logs\flashlog.txt"

exit /b %rc%

:normalize_path
  SET RETVAL=%~dpfn1
  exit /b