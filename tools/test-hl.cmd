@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, http://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

pushd .

REM cd into project root
cd %~dp0..

echo Cleaning...
if exist dump\hl rd /s /q dump\hl
if exist target\hl rd /s /q target\hl

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling...
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
  -lib haxe-doctest ^
  -cp src ^
  -cp test ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
  -hl target\hl\TestRunner.hl
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
hl "%~dp0..\target\hl\TestRunner.hl"
