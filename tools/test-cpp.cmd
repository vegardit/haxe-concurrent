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
pushd .
cd "%CDP%.."
haxe extraParams.hxml -main hx.concurrent.TestRunner ^
  -lib haxe-doctest ^
  -cp "src" ^
  -cp "test" ^
  -dce full ^
  -debug ^
  -D HXCPP_CHECK_POINTER ^
  -D dump=pretty ^
  -cpp "target\cpp"
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
"%CDP%..\target\cpp\TestRunner-Debug.exe"
