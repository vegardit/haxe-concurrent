@echo off
set CDP=%~dp0
set PWD
setlocal

set TOP_LEVEL_PACKAGE=hx.concurrent
set OWNER=http://vegardit.com

REM extract GIT URL from haxelib.json
for /f "tokens=*" %%a in ( 'findstr url "%CDP%haxelib.json"' ) do (set textLine=%%a)
set REPO_URL=%textLine:"url": "=%
set REPO_URL=%REPO_URL:",=%
set REPO_URL=%REPO_URL:"=%
echo REPO_URL=%REPO_URL%

REM extract project version from haxelib.json
for /f "tokens=*" %%a in ( 'findstr version "%CDP%haxelib.json"' ) do (set textLine=%%a)
set PROJECT_VERSION=%textLine:"version": "=%
set PROJECT_VERSION=%PROJECT_VERSION:",=%
set PROJECT_VERSION=%PROJECT_VERSION:"=%

REM extract project name from haxelib.json
for /f "tokens=*" %%a in ( 'findstr name "%CDP%haxelib.json"' ) do (set textLine=%%a)
set PROJECT_NAME=%textLine:"name": "=%
set PROJECT_NAME=%PROJECT_NAME:",=%
set PROJECT_NAME=%PROJECT_NAME:"=%

REM extract project description from haxelib.json
for /f "tokens=*" %%a in ( 'findstr description "%CDP%haxelib.json"' ) do (set textLine=%%a)
set PROJECT_DESCRIPTION=%textLine:"description": "=%
set PROJECT_DESCRIPTION=%PROJECT_DESCRIPTION:",=%
set PROJECT_DESCRIPTION=%PROJECT_DESCRIPTION:"=%

haxelib list | findstr dox >NUL
if %errorlevel% neq 0 (
    echo Installing [dox]...
    haxelib install dox
)

if exist "%CDP%target\site" (
    echo Cleaning %CDP%target\site...
    rd /s /q "%CDP%target\site"
)

echo Analyzing source code...
set PWD=%CD%
cd %CDP%
haxe -cp "src" --no-output -D doc-gen -xml "%CDP%target/doc.xml" --macro include('%TOP_LEVEL_PACKAGE%')
cd %PWD%

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
 -ex "^%OWNER:.=\.%\.internal" ^
 -i "%CDP%target\doc.xml" ^
 -o "%CDP%target\site"

set pwd=%~dp0
echo.
echo Documentation generated at [file:///%pwd:\=/%target/site/index.html]...

endlocal
