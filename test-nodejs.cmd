@echo off
echo Cleaning...
if exist dump\js rd /s /q dump\js
if exist target\js rd /s /q target\js

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
-D nodejs ^
-js target\js\TestRunner.js || goto :eof

echo Testing...
node target\js\TestRunner.js
