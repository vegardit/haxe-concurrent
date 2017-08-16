@echo off
echo Cleaning...
if exist dump\hl rd /s /q dump\hl
if exist target\hl rd /s /q target\hl

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

echo Compiling and Testing...
haxe -main hx.concurrent.TestRunner ^
-lib haxe-doctest ^
-cp src ^
-cp test ^
-dce full ^
-debug ^
-D dump=pretty ^
-hl target/hl/TestRunner.hl

hl target/hl/TestRunner.hl
