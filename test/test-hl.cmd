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
haxe -main hx.concurrent.TestRunner ^
-lib haxe-doctest ^
-cp "%CDP%..\src" ^
-cp "%CDP%..\test" ^
-dce full ^
-debug ^
-D dump=pretty ^
-hl "%CDP%..\target/hl/TestRunner.hl"

hl "%CDP%..\target/hl/TestRunner.hl"
