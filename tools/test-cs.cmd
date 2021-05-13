@echo off
REM Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

call %~dp0_test-prepare.cmd cs hxcs

echo Compiling...
haxe %~dp0..\tests.hxml -cs target\cs
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
mono "%~dp0..\target\cs\bin\TestRunner-Debug.exe"
