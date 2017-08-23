@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\hl" rd /s /q "%CDP%dump\hl"
if exist "%CDP%..\target\hl" rd /s /q "%CDP%..\target\hl"

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling and Testing...
pushd .
cd "%CDP%.."
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
  -lib haxe-doctest ^
  -cp "src" ^
  -cp "test" ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
  -hl "target\hl\TestRunner.hl"
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

hl "%CDP%..\target\hl\TestRunner.hl"
