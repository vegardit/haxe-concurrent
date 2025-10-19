@echo off
REM SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
REM SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
REM SPDX-License-Identifier: Apache-2.0

call %~dp0_test-prepare.cmd php

echo Compiling...
haxe %~dp0..\tests.hxml -php target\php
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
php "%~dp0..\target\php\index.php"
