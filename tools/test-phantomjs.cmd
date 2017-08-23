@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\js" rd /s /q "%CDP%dump\js"
if exist "%CDP%..\target\js" rd /s /q "%CDP%..\target\js"

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling...
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
-lib haxe-doctest ^
-cp "%CDP%..\src" ^
-cp "%CDP%..\test" ^
-dce full ^
-debug ^
-D dump=pretty ^
-js "%CDP%..\target\js\TestRunner.js" || goto :eof

echo Testing...
phantomjs "%CDP%..\target\js\TestRunner.js"
