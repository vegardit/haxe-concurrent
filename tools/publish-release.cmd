@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

REM creates a new release in GitHub and haxelib.org

where zip.exe /Q
if %errorlevel% neq 0 (
    echo Required command 'zip' not found. Download from http://www.info-zip.org/Zip.html#Downloads
    exit /b 1
)

where wget.exe /Q
if %errorlevel% neq 0 (
    echo Required command 'wget' not found. Download from https://eternallybored.org/misc/wget/
    exit /b 1
)

if [%GITHUB_ACCESS_TOKEN%] == [] (
    echo Required environment variable GITHUB_ACCESS_TOKEN is not set!
    exit /b 1
)

setlocal
set DRAFT=false
set PREPRELEASE=false

REM cd into project root
pushd .
cd %~dp0..

REM extract GIT URL from haxelib.json
for /f "tokens=*" %%a in ( 'findstr url haxelib.json' ) do (set textLine=%%a)
set REPO_URL=%textLine:"url": "=%
set REPO_URL=%REPO_URL:",=%
set REPO_URL=%REPO_URL:"=%
echo REPO_URL=%REPO_URL%

REM extract repo name from haxelib.json
set REPO_NAME=%REPO_URL:https://github.com/=%
echo REPO_NAME=%REPO_NAME%

REM extract project version from haxelib.json
for /f "tokens=*" %%a in ( 'findstr version haxelib.json' ) do (set textLine=%%a)
set PROJECT_VERSION=%textLine:"version": "=%
set PROJECT_VERSION=%PROJECT_VERSION:",=%
set PROJECT_VERSION=%PROJECT_VERSION:"=%
echo PROJECT_VERSION=%PROJECT_VERSION%

REM extract release note from haxelib.json
for /f "tokens=*" %%a in ( 'findstr releasenote haxelib.json' ) do (set textLine=%%a)
set RELEASE_NOTE=%textLine:"releasenote": "=%
set RELEASE_NOTE=%RELEASE_NOTE:",=%
set RELEASE_NOTE=%RELEASE_NOTE:"=%
echo RELEASE_NOTE=%RELEASE_NOTE%

if not exist target mkdir target

REM create haxelib release
if exist target\haxelib-upload.zip (
    del target\haxelib-upload.zip
)
echo Building haxelib release...
zip target\haxelib-upload.zip src extraParams.hxml haxelib.json LICENSE.txt CONTRIBUTING.md README.md -r -9 || goto :eof

REM create github release https://developer.github.com/v3/repos/releases/#create-a-release
echo Creating GitHub release https://github.com/%REPO_NAME%/releases/tag/v%PROJECT_VERSION%...
(
  echo {
  echo "tag_name":"v%PROJECT_VERSION%",
  echo "name":"v%PROJECT_VERSION%",
  echo "target_commitish":"master",
  echo "body":"%RELEASE_NOTE%",
  echo "draft":%DRAFT%,
  echo "prerelease":%PREPRELEASE%
  echo }
)>target\github_release.json
wget -qO- --post-file=target/github_release.json "https://api.github.com/repos/%REPO_NAME%/releases?access_token=%GITHUB_ACCESS_TOKEN%" || goto :eof

REM submit haxelib release
echo Submitting haxelib release...
haxelib submit target\haxelib-upload.zip

:eof
popd
endlocal
