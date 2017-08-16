@echo off
echo Cleaning...
if exist dump\flash rd /s /q dump\flash
if exist target\flash rd /s /q target\flash

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling...
haxe -main hx.concurrent.TestRunner ^
-swf-version 11.5 ^
-lib haxe-doctest ^
-cp src ^
-cp test ^
-dce full ^
-debug ^
-D dump=pretty ^
-swf target/flash/TestRunner.swf || goto :eof

echo Testing...
flashplayer_24_sa_debug target/flash/TestRunner.swf
