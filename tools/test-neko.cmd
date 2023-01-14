@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

call %~dp0_test-prepare.cmd neko

echo Compiling...
haxe %~dp0..\tests.hxml -neko target\neko\TestRunner.n
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
neko "%~dp0..\target\neko\TestRunner.n"
