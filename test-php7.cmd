@echo off
echo Cleaning...
if exist dump\php rd /s /q dump\php
if exist target\php7 rd /s /q target\php7

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
-D php7 ^
-php target\php7 || goto :eof

echo Testing...
%PHP7_HOME%\php target\php7\index.php
