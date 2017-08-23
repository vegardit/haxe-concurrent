@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\java" rd /s /q "%CDP%dump\java"
if exist "%CDP%..\target\java" rd /s /q "%CDP%..\target\java"

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

haxelib list | findstr hxjava >NUL
if errorlevel 1 (
    echo Installing [hxjava]...
    haxelib install hxjava
)

echo Compiling...
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
-lib haxe-doctest ^
-cp "%CDP%..\src" ^
-cp "%CDP%..\test" ^
-dce full ^
-debug ^
-D dump=pretty ^
-java "%CDP%..\target\java" || goto :eof

echo Testing...
java -jar "%CDP%..\target\java\TestRunner-Debug.jar"
