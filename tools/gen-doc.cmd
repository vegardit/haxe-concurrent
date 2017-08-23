@echo off
REM @author Sebastian Thomschke, Vegard IT GmbH
REM
REM generates API documentation using dox at <project_root>\target\site

setlocal

set TOP_LEVEL_PACKAGE=hx.concurrent
set OWNER=https://vegardit.com

set CDP=%~dp0

pushd .
cd "%CDP%..\target"
set TARGET=%CD%
popd

REM extract GIT URL from haxelib.json
for /f "tokens=*" %%a in ( 'findstr url "%CDP%..\haxelib.json"' ) do (set textLine=%%a)
set REPO_URL=%textLine:"url": "=%
set REPO_URL=%REPO_URL:",=%
set REPO_URL=%REPO_URL:"=%
echo REPO_URL=%REPO_URL%

REM extract project version from haxelib.json
for /f "tokens=*" %%a in ( 'findstr version "%CDP%..\haxelib.json"' ) do (set textLine=%%a)
set PROJECT_VERSION=%textLine:"version": "=%
set PROJECT_VERSION=%PROJECT_VERSION:",=%
set PROJECT_VERSION=%PROJECT_VERSION:"=%

REM extract project name from haxelib.json
for /f "tokens=*" %%a in ( 'findstr name "%CDP%..\haxelib.json"' ) do (set textLine=%%a)
set PROJECT_NAME=%textLine:"name": "=%
set PROJECT_NAME=%PROJECT_NAME:",=%
set PROJECT_NAME=%PROJECT_NAME:"=%

REM extract project description from haxelib.json
for /f "tokens=*" %%a in ( 'findstr description "%CDP%..\haxelib.json"' ) do (set textLine=%%a)
set PROJECT_DESCRIPTION=%textLine:"description": "=%
set PROJECT_DESCRIPTION=%PROJECT_DESCRIPTION:",=%
set PROJECT_DESCRIPTION=%PROJECT_DESCRIPTION:"=%

haxelib list | findstr dox >NUL
if %errorlevel% neq 0 (
    echo Installing [dox]...
    haxelib install dox
)

if exist "%TARGET%\site" (
    echo Cleaning %TARGET%\site...
    rd /s /q "%TARGET%\site"
)

echo Analyzing source code...
haxe -cp "%CDP%..\src" --no-output -D doc-gen -xml "%TARGET%\doc.xml" --macro include('%TOP_LEVEL_PACKAGE%')

REM https://github.com/HaxeFoundation/dox/wiki/Commandline-arguments-overview
echo Generating HTML files...
haxelib run dox ^
 --title "%PROJECT_NAME% %PROJECT_VERSION% API documentation" ^
 --toplevel-package "%TOP_LEVEL_PACKAGE%" ^
 -D description "%PROJECT_NAME%: %PROJECT_DESCRIPTION%" ^
 -D source-path "%REPO_URL%/tree/master/src" ^
 -D themeColor 0x00658F ^
 -D version "%PROJECT_VERSION%" ^
 -D website "%OWNER%" ^
 -ex "^%TOP_LEVEL_PACKAGE:.=\.%\.internal" ^
 -i "%TARGET%\doc.xml" ^
 -o "%TARGET%\site"

echo.
echo Documentation generated at [file:///%TARGET:\=/%/site/index.html]...

endlocal
