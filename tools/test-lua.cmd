@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\lua" rd /s /q "%CDP%dump\lua"
if exist "%CDP%..\target\lua" rd /s /q "%CDP%..\target\lua"

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
-D luajit ^
-lua "%CDP%..\target\lua\TestRunner.lua" || goto :eof

echo Testing...
lua "%CDP%..\target\lua\TestRunner.lua"
