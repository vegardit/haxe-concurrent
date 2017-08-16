@echo off
echo Cleaning...
if exist dump\php rd /s /q dump\php
if exist target\php rd /s /q target\php

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
-php target\php || goto :eof

echo Testing...
%PHP5_HOME%\php target\php\index.php
