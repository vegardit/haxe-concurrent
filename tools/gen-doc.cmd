@echo off
REM Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

REM generates API documentation using dox at <project_root>\target\site

setlocal

set TOP_LEVEL_PACKAGE=hx.concurrent
set OWNER=https://vegardit.com

REM cd into project root
pushd .
cd %~dp0..

REM extract GIT URL from haxelib.json
for /f "tokens=*" %%a in ( 'findstr url haxelib.json' ) do (set textLine=%%a)
set REPO_URL=%textLine:"url": "=%
set REPO_URL=%REPO_URL:",=%
set REPO_URL=%REPO_URL:"=%
echo REPO_URL=%REPO_URL%

REM extract project version from haxelib.json
for /f "tokens=*" %%a in ( 'findstr version haxelib.json' ) do (set textLine=%%a)
set PROJECT_VERSION=%textLine:"version": "=%
set PROJECT_VERSION=%PROJECT_VERSION:",=%
set PROJECT_VERSION=%PROJECT_VERSION:"=%
echo PROJECT_VERSION=%PROJECT_VERSION%

REM extract project name from haxelib.json
for /f "tokens=*" %%a in ( 'findstr name haxelib.json' ) do (set textLine=%%a)
set PROJECT_NAME=%textLine:"name": "=%
set PROJECT_NAME=%PROJECT_NAME:",=%
set PROJECT_NAME=%PROJECT_NAME:"=%

REM extract project description from haxelib.json
for /f "tokens=*" %%a in ( 'findstr description haxelib.json' ) do (set textLine=%%a)
set PROJECT_DESCRIPTION=%textLine:"description": "=%
set PROJECT_DESCRIPTION=%PROJECT_DESCRIPTION:",=%
set PROJECT_DESCRIPTION=%PROJECT_DESCRIPTION:"=%

haxelib list | findstr dox >NUL
if %errorlevel% neq 0 (
    echo Installing [dox]...
    haxelib install dox
)

if exist target\site (
    echo Cleaning target\site...
    del target\doc.xml >NUL
    rd /s /q target\site
)

echo Analyzing source code...
haxe -cp src --no-output -D doc-gen -xml target\doc.xml --macro include('%TOP_LEVEL_PACKAGE%') || goto :eof

REM https://github.com/HaxeFoundation/dox/wiki/Commandline-arguments-overview
echo Generating HTML files...
haxelib run dox ^
 --title "%PROJECT_NAME% %PROJECT_VERSION% API documentation" ^
 --toplevel-package "%TOP_LEVEL_PACKAGE%" ^
 -D description "%PROJECT_NAME%: %PROJECT_DESCRIPTION%" ^
 -D source-path "%REPO_URL%/tree/master/src" ^
 -D themeColor 0x1690CC ^
 -D version "%PROJECT_VERSION%" ^
 -D website "%OWNER%" ^
 -ex "^%TOP_LEVEL_PACKAGE:.=\.%\.internal" ^
 -i target\doc.xml ^
 -o target\site || goto :eof

set INDEX_HTML=%CD%\target\site\index.html

echo.
echo Documentation generated at [file:///%INDEX_HTML:\=/%]...

:eof
popd
endlocal