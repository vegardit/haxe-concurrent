@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, http://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

pushd .

REM cd into project root
cd %~dp0..

echo Cleaning...
if exist dump\cpp rd /s /q dump\cpp
::if exist target\cpp rd /s /q target\cpp

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

haxelib list | findstr hxcpp >NUL
if errorlevel 1 (
    echo Installing [hxcpp]...
    haxelib install hxcpp
)

echo Compiling...
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
  -lib haxe-doctest ^
  -cp src ^
  -cp test ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
  -D HXCPP_CHECK_POINTER ^
  -cpp target\cpp
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
"%~dp0..\target\cpp\TestRunner-Debug.exe"
