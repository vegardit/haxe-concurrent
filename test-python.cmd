@echo off
echo Cleaning...
if exist dump\python rd /s /q dump\python
if exist target\python rd /s /q target\python

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
-python target\python\TestRunner.py || goto :eof

echo Testing...
python target\python\TestRunner.py
