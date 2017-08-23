@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\php" rd /s /q "%CDP%dump\php"
if exist "%CDP%..\target\php7" rd /s /q "%CDP%..\target\php7"

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
-D php7 ^
-php "%CDP%..\target\php7" || goto :eof

echo Testing...
%PHP7_HOME%\php "%CDP%..\target\php7\index.php"
