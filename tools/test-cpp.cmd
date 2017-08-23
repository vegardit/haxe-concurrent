@echo off
set CDP=%~dp0

echo Cleaning...
if exist "%CDP%dump\cpp" rd /s /q "%CDP%dump\cpp"
::if exist "%CDP%..\target\cpp" rd /s /q "%CDP%..\target\cpp"

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

haxelib list | findstr hxcpp >NUL
if errorlevel 1 (
    echo Installing [hxcpp]...
    haxelib install hxcpp
)

echo Compiling...
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
-lib haxe-doctest ^
-cp "%CDP%..\src" ^
-cp "%CDP%..\test" ^
-dce full ^
-debug ^
-D HXCPP_CHECK_POINTER ^
-D dump=pretty ^
-cpp "%CDP%..\target\cpp" || goto :eof

echo Testing...
"%CDP%..\target\cpp\TestRunner-Debug.exe"
