@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\neko" rd /s /q "%CDP%dump\neko"
if exist "%CDP%..\target\neko" rd /s /q "%CDP%..\target\neko"

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
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
  -neko "target\neko\TestRunner.n"
set rc=%errorlevel%
popd
if not %rc% == 0 goto :eof

echo Testing...
neko "%CDP%..\target\neko\TestRunner.n"
