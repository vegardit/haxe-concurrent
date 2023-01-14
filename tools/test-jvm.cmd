@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

call %~dp0_test-prepare.cmd java hxjava

echo Compiling...
haxe %~dp0..\tests.hxml -D jvm -java target\java
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
java -jar "%~dp0..\target\java\TestRunner-Debug.jar"
