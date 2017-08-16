@echo off
setlocal

set TOP_LEVEL_PACKAGE=hx.threads
set OWNER=http://vegardit.com

REM extract project version from haxelib.json
for /f "tokens=*" %%a in ( 'findstr version haxelib.json' ) do (set textLine=%%a)
set PROJECT_VERSION=%textLine:"version": "=%
set PROJECT_VERSION=%PROJECT_VERSION:",=%

REM extract project name from haxelib.json
for /f "tokens=*" %%a in ( 'findstr name haxelib.json' ) do (set textLine=%%a)
set PROJECT_NAME=%textLine:"name": "=%
set PROJECT_NAME=%PROJECT_NAME:",=%

REM extract project description from haxelib.json
for /f "tokens=*" %%a in ( 'findstr description haxelib.json' ) do (set textLine=%%a)
set PROJECT_DESCRIPTION=%textLine:"description": "=%
set PROJECT_DESCRIPTION=%PROJECT_DESCRIPTION:",=%

haxelib list | findstr dox >NUL
if %errorlevel% neq 0 (
    echo Installing [dox]...
    haxelib install dox
)

if exist target\site (
    echo Cleaning target/site...
    rd /s /q target\site
)

echo Analyzing source code...
haxe -cp src --no-output -D doc-gen -xml target/doc.xml --macro include('%TOP_LEVEL_PACKAGE%')

REM https://github.com/HaxeFoundation/dox/wiki/Commandline-arguments-overview
echo Generating HTML files...
haxelib run dox ^
  --title "%PROJECT_NAME% %PROJECT_VERSION% API documentation" ^
  --toplevel-package "%TOP_LEVEL_PACKAGE%" ^
  -D themeColor 0x27B33A ^
  -D version "%RELEASE_VERSION%" ^
  -D description "%PROJECT_NAME%: %PROJECT_DESCRIPTION%" ^
  -D website "%COPYRIGHT%" ^
  -ex "^%OWNER:.=\.%\.internal" ^
  -i target/doc.xml ^
  -o target/site

set pwd=%~dp0
echo.
echo Documentation generated at [file:///%pwd:\=/%target/site/index.html]...

endlocal
