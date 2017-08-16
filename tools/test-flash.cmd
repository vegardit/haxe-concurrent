@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\flash" rd /s /q "%CDP%dump\flash"
if exist "%CDP%..\target\flash" rd /s /q "%CDP%..\target\flash"

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling...
haxe -main hx.concurrent.TestRunner ^
-swf-version 11.5 ^
-lib haxe-doctest ^
-cp "%CDP%..\src" ^
-cp "%CDP%..\test" ^
-dce full ^
-debug ^
-D dump=pretty ^
-swf "%CDP%..\target\flash\TestRunner.swf" || goto :eof

echo Testing...
flashplayer_24_sa_debug "%CDP%..\target\flash\TestRunner.swf"
