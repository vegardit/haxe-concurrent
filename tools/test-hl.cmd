@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

call %~dp0_test-prepare.cmd hl

echo Compiling...
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
  -lib haxe-doctest ^
  -cp src ^
  -cp test ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
  -hl target\hl\TestRunner.hl
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
hl "%~dp0..\target\hl\TestRunner.hl"
