@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

call %~dp0_test-prepare.cmd hl

echo Compiling...
haxe %~dp0..\tests.hxml -hl target\hl\TestRunner.hl
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
hl "%~dp0..\target\hl\TestRunner.hl"
