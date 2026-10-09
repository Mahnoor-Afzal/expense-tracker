@echo off
echo Fixing Path and Building APK...
set "FLUTTER_ROOT=C:\FLUTTE~1\sdk\flutter"
set "PATH=C:\FLUTTE~1\sdk\flutter\bin;%PATH%"
cd /d "%~dp0"
call flutter clean
call flutter pub get
call flutter build apk --release
echo.
echo If build was successful, your APK is in: build\app\outputs\flutter-apk\app-release.apk
pause