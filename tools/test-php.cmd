@echo off
REM Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

call %~dp0_test-prepare.cmd php

echo Compiling...
haxe %~dp0..\tests.hxml -php target\php
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
%PHP5_HOME%\php "%~dp0..\target\php\index.php"
