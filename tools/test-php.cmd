@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\php" rd /s /q "%CDP%dump\php"
if exist "%CDP%..\target\php" rd /s /q "%CDP%..\target\php"

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
-php "%CDP%..\target\php" || goto :eof

echo Testing...
%PHP5_HOME%\php "%CDP%..\target\php\index.php"
