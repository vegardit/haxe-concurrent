@echo off
REM Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

pushd .

REM cd into project root
cd %~dp0..

echo Cleaning...
if exist dump\flash rd /s /q dump\flash
if exist target\flash rd /s /q target\flash

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling...
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
  -lib haxe-doctest ^
  -cp src ^
  -cp test ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
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

echo Testing...
flashplayer_27_sa_debug "%~dp0..\target\flash\TestRunner.swf"
set rc=%errorlevel%

REM printing log file
type "%HOME%\AppData\Roaming\Macromedia\Flash Player\Logs\flashlog.txt"

exit /b %rc%
