@echo off
REM Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

call %~dp0_test-prepare.cmd cpp hxcpp

echo Compiling...
haxe %~dp0..\tests.hxml -D HXCPP_CHECK_POINTER -cpp target\cpp
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
"%~dp0..\target\cpp\TestRunner-Debug.exe"
