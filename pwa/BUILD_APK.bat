@echo off
echo ============================================
echo   LLM ORDUSU - APK OLUSTURMA
echo ============================================
echo.

REM Node.js kontrolu
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [HATA] Node.js bulunamadi!
    echo Lutfen Node.js yukleyin: https://nodejs.org
    pause
    exit /b 1
)

echo [1/5] Bagimliliklar yukleniyor...
call npm install

echo [2/5] Capacitor Android ekleniyor...
call npx cap add android

echo [3/5] Web dosyalari kopyalaniyor...
call npx cap copy android

echo [4/5] Android Studio aciliyor...
echo Android Studio'da: Build > Build Bundle(s) / APK(s) > Build APK(s)
call npx cap open android

echo.
echo ============================================
echo   Islem tamamlandi!
echo ============================================
echo.
echo APK dosyasi su klasorde olusturulacak:
echo android\app\build\outputs\apk\debug\app-debug.apk
echo.
pause
