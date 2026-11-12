@echo off
chcp 65001 >nul
title Build — CSV GitHub Uploader

echo.
echo  =======================================================
echo   Build: CSV / Excel -^> GitHub Uploader  (Windows)
echo  =======================================================
echo.

:: Controlla Python
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERRORE] Python non trovato nel PATH.
    echo  Scaricalo da: https://www.python.org/downloads/
    echo  Spunta "Add Python to PATH" durante l'installazione.
    pause & exit /b 1
)
echo  [OK] Python trovato:
python --version
echo.

:: Installa dipendenze
echo  [1/3] Installazione dipendenze...
python -m pip install --upgrade pip --quiet
python -m pip install customtkinter pandas openpyxl PyGithub pyinstaller --quiet --upgrade
if %ERRORLEVEL% neq 0 (
    echo  [ERRORE] Installazione dipendenze fallita.
    pause & exit /b 1
)
echo  [OK] Dipendenze installate.
echo.

:: Pulizia
echo  [2/3] Pulizia build precedente...
if exist "dist\CSVGitHubUploader.exe" del /q "dist\CSVGitHubUploader.exe"
if exist "build" rmdir /s /q "build"
echo  [OK] Pulizia completata.
echo.

:: Build
echo  [3/3] Compilazione in corso (2-5 minuti)...
python -m PyInstaller app.spec --noconfirm --clean
if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERRORE] Build fallita.
    pause & exit /b 1
)

if not exist "dist\CSVGitHubUploader.exe" (
    echo  [ERRORE] File .exe non trovato.
    pause & exit /b 1
)

echo.
echo  =======================================================
echo   BUILD COMPLETATA!
echo   File: dist\CSVGitHubUploader.exe
echo   Distribuisci solo il .exe - nessun Python richiesto.
echo  =======================================================
echo.
echo  Premi un tasto per aprire la cartella dist...
pause >nul
explorer dist
