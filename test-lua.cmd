@echo off
echo Cleaning...
if exist dump\lua rd /s /q dump\lua
if exist target\lua rd /s /q target\lua

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling...
haxe -main hx.concurrent.TestRunner ^
-lib haxe-doctest ^
-cp src ^
-cp test ^
-dce full ^
-debug ^
-D dump=pretty ^
-D luajit ^
-lua target/lua/TestRunner.lua || goto :eof

echo Testing...
lua target/lua/TestRunner.lua
