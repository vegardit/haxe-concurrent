@echo off
REM Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

call %~dp0_test-prepare.cmd java hxjava

echo Compiling...
haxe %~dp0..\tests.hxml -D jvm -java target\java
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
java -jar "%~dp0..\target\java\TestRunner-Debug.jar"
