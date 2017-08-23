@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\cs" rd /s /q "%CDP%dump\cs"
if exist "%CDP%..\target\cs" rd /s /q "%CDP%..\target\cs"

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

haxelib list | findstr hxcs >NUL
if errorlevel 1 (
    echo Installing [hxcs]...
    haxelib install hxcs
)

echo Compiling...
pushd .
cd "%CDP%.."
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
  -lib haxe-doctest ^
  -cp "src" ^
  -cp "test" ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
  -cs "%CDP%..\target\cs"
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
mono "%CDP%..\target\cs\bin\TestRunner-Debug.exe"
