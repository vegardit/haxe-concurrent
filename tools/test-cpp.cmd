@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

call %~dp0_test-prepare.cmd cpp hxcpp

echo Compiling...
haxe %~dp0..\tests.hxml -D HXCPP_CHECK_POINTER -cpp target\cpp
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
"%~dp0..\target\cpp\TestRunner-Debug.exe"
