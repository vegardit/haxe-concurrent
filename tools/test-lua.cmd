@echo off
REM Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

call %~dp0_test-prepare.cmd lua

echo Compiling...
haxe %~dp0..\tests.hxml -D luajit -lua target\lua\TestRunner.lua
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
lua "%~dp0..\target\lua\TestRunner.lua"
