@echo off
echo Cleaning...
if exist dump\neko rd /s /q dump\neko
if exist target\neko rd /s /q target\neko

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
-neko target/neko/TestRunner.n || goto :eof

echo Testing...
neko target/neko/TestRunner.n
