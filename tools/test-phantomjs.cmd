@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

call %~dp0_test-prepare.cmd js phantomjs

echo Compiling...
haxe %~dp0..\tests.hxml -lib phantomjs -js target\js\TestRunner.js
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing [Direct Execution]...
phantomjs "%~dp0..\target\js\TestRunner.js"
