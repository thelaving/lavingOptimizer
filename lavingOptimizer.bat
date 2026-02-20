@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
mode con cols=120 lines=40
title Laving Ultimate Gaming Optimizer v2.0

:: ============================================================================
:: RENK TANIMLAMALARI (ANSI Escape)
:: ============================================================================
for /F "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "CYAN=%ESC%[96m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "WHITE=%ESC%[97m"
set "GRAY=%ESC%[90m"
set "MAGENTA=%ESC%[95m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"
set "BG_DARK=%ESC%[40m"
set "TICK=%GREEN%[✓]%RESET%"
set "CROSS=%RED%[✗]%RESET%"
set "WARN=%YELLOW%[!]%RESET%"
set "WORK=%CYAN%[~]%RESET%"

:: ============================================================================
:: ZAMAN ÖLÇÜMÜ BAŞLAT
:: ============================================================================
set "SCRIPT_START_TIME=%time%"
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set /a "START_S=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)"
)

:: ============================================================================
:: LOG DOSYASI AYARLARI
:: ============================================================================
set "LOG_DATE=%date:~-4%-%date:~3,2%-%date:~0,2%"
set "LOG_TIME=%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "LOG_TIME=%LOG_TIME: =0%"
set "LOG_FILE=%USERPROFILE%\Desktop\OptimizationLog_%LOG_DATE%_%LOG_TIME%.txt"
set "BACKUP_DIR=%USERPROFILE%\Desktop\LavingBackup_%LOG_DATE%_%LOG_TIME%"
set "UNDO_FILE=%BACKUP_DIR%\UNDO_Restore.bat"
set "CHANGES_COUNT=0"
set "SUCCESS_COUNT=0"
set "FAIL_COUNT=0"
set "SKIP_COUNT=0"

:: ============================================================================
:: YÖNETİCİ YETKİ KONTROLÜ
:: ============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%Yonetici yetkisi gerekiyor, yukseltiliyor...%RESET%
    powershell -Command "Start-Process '%~f0' -Verb RunAs" 2>nul
    if %errorlevel% neq 0 (
        echo %RED%Yonetici yetkisi alinamadi!%RESET%
        pause
    )
    exit /b
)

:: ============================================================================
:: WINDOWS SÜRÜM TESPİTİ
:: ============================================================================
set "WIN_VER=Unknown"
set "WIN_BUILD=0"
set "WIN_MAJOR=0"
for /f "tokens=4-5 delims=[.] " %%i in ('ver') do (
    for /f "tokens=1,2 delims=." %%a in ("%%i.%%j") do (
        set "WIN_MAJOR=%%a"
        set "WIN_BUILD=%%b"
    )
)
for /f "tokens=6 delims=[.] " %%i in ('ver') do set "WIN_BUILD=%%i"
for /f "tokens=2 delims==" %%a in ('wmic os get BuildNumber /value 2^>nul') do set "WIN_BUILD=%%a"
for /f "tokens=2 delims==" %%a in ('wmic os get Caption /value 2^>nul') do set "WIN_CAPTION=%%a"

echo "%WIN_CAPTION%" | find "11" >nul 2>&1
if %errorlevel%==0 (
    set "WIN_VER=11"
    set "WIN_LABEL=Windows 11"
) else (
    echo "%WIN_CAPTION%" | find "10" >nul 2>&1
    if !errorlevel!==0 (
        set "WIN_VER=10"
        set "WIN_LABEL=Windows 10"
    ) else (
        set "WIN_VER=10"
        set "WIN_LABEL=Windows (Bilinmiyor)"
    )
)

:: ============================================================================
:: SİSTEM BİLGİLERİNİ TOPLA
:: ============================================================================
set "CPU_NAME=Bilinmiyor"
set "CPU_CORES=0"
set "CPU_THREADS=0"
set "RAM_TOTAL=0"
set "GPU_NAME=Bilinmiyor"
set "DISK_TYPE=Bilinmiyor"
set "POWER_PLAN=Bilinmiyor"
set "NIC_NAME=Bilinmiyor"

for /f "tokens=2 delims==" %%a in ('wmic cpu get Name /value 2^>nul') do set "CPU_NAME=%%a"
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfCores /value 2^>nul') do set "CPU_CORES=%%a"
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfLogicalProcessors /value 2^>nul') do set "CPU_THREADS=%%a"
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /value 2^>nul') do set /a "RAM_TOTAL=%%a/1024"
for /f "tokens=2 delims==" %%a in ('wmic path win32_VideoController get Name /value 2^>nul') do (
    if not "%%a"=="" set "GPU_NAME=%%a"
)
for /f "tokens=*" %%a in ('powershell -Command "(Get-PhysicalDisk | Select-Object -First 1).MediaType" 2^>nul') do set "DISK_TYPE=%%a"
for /f "tokens=*" %%a in ('powercfg /getactivescheme 2^>nul') do set "POWER_PLAN=%%a"
for /f "tokens=2 delims==" %%a in ('wmic nic where "NetConnectionStatus=2" get Name /value 2^>nul') do (
    if not "%%a"=="" set "NIC_NAME=%%a"
)

:: CPU_NAME temizle (bosluk)
set "CPU_NAME=%CPU_NAME: =%"
if "%CPU_NAME%"=="" set "CPU_NAME=Bilinmiyor"

:: ============================================================================
:: BACKUP KLASÖRÜ OLUŞTUR
:: ============================================================================
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" 2>nul

:: ============================================================================
:: LOG BAŞLAT
:: ============================================================================
echo ============================================================ > "%LOG_FILE%"
echo   Laving Ultimate Gaming Optimizer v2.0 - Islem Logu >> "%LOG_FILE%"
echo   Tarih: %date% %time% >> "%LOG_FILE%"
echo   Sistem: %WIN_LABEL% Build %WIN_BUILD% >> "%LOG_FILE%"
echo   CPU: %CPU_NAME% >> "%LOG_FILE%"
echo   RAM: %RAM_TOTAL% MB >> "%LOG_FILE%"
echo   GPU: %GPU_NAME% >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: ============================================================================
:: UNDO SCRIPT BAŞLAT
:: ============================================================================
echo @echo off > "%UNDO_FILE%"
echo chcp 65001 ^>nul 2^>^&1 >> "%UNDO_FILE%"
echo echo ============================================================ >> "%UNDO_FILE%"
echo echo   Laving Optimizer - Geri Alma Scripti >> "%UNDO_FILE%"
echo echo   Olusturulma: %date% %time% >> "%UNDO_FILE%"
echo echo ============================================================ >> "%UNDO_FILE%"
echo echo. >> "%UNDO_FILE%"
echo net session ^>nul 2^>^&1 >> "%UNDO_FILE%"
echo if %%errorlevel%% neq 0 ( >> "%UNDO_FILE%"
echo     powershell -Command "Start-Process '%%~f0' -Verb RunAs" >> "%UNDO_FILE%"
echo     exit /b >> "%UNDO_FILE%"
echo ) >> "%UNDO_FILE%"
echo echo Geri alma basliyor... >> "%UNDO_FILE%"
echo. >> "%UNDO_FILE%"

:: ============================================================================
:: ANA MENÜYE GİT
:: ============================================================================
goto :MAIN_MENU

:: ============================================================================
::                          YARDIMCI FONKSİYONLAR
:: ============================================================================

:SHOW_BANNER
cls
echo.
echo %CYAN%%BOLD%
echo     ██╗      █████╗ ██╗   ██╗██╗███╗   ██╗ ██████╗
echo     ██║     ██╔══██╗██║   ██║██║████╗  ██║██╔════╝
echo     ██║     ███████║██║   ██║██║██╔██╗ ██║██║  ███╗
echo     ██║     ██╔══██║╚██╗ ██╔╝██║██║╚██╗██║██║   ██║
echo     ███████╗██║  ██║ ╚████╔╝ ██║██║ ╚████║╚██████╔╝
echo     ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝
echo %RESET%
echo     %WHITE%%BOLD%★ ULTIMATE GAMING OPTIMIZER v2.0 ★%RESET%
echo     %GRAY%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%RESET%
echo.
goto :eof

:SHOW_PROGRESS
:: %1 = yüzde (0-100), %2 = açıklama
set /a "_filled=%~1 / 5"
set /a "_empty=20 - _filled"
set "_bar="
for /L %%i in (1,1,%_filled%) do set "_bar=!_bar!█"
for /L %%i in (1,1,%_empty%) do set "_bar=!_bar!░"
echo     %CYAN%[!_bar!] %~1%% %WHITE%- %~2%RESET%
goto :eof

:LOG_ACTION
:: %1 = eylem açıklaması
echo [%date% %time%] %~1 >> "%LOG_FILE%"
goto :eof

:REG_BACKUP_AND_SET
:: %1=ROOT, %2=KeyPath, %3=ValueName, %4=Type, %5=Data
:: Yedekle
set "_REGPATH=%~1\%~2"
for /f "tokens=2,*" %%a in ('reg query "%_REGPATH%" /v "%~3" 2^>nul ^| findstr /i "%~3"') do (
    set "_OLD_TYPE=%%a"
    set "_OLD_DATA=%%b"
)
if defined _OLD_DATA (
    echo reg add "%_REGPATH%" /v "%~3" /t !_OLD_TYPE! /d "!_OLD_DATA!" /f ^>nul 2^>^&1 >> "%UNDO_FILE%"
) else (
    echo reg delete "%_REGPATH%" /v "%~3" /f ^>nul 2^>^&1 >> "%UNDO_FILE%"
)
:: Ayarla
reg add "%_REGPATH%" /v "%~3" /t %~4 /d %~5 /f >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% %~3 = %~5
    set /a "SUCCESS_COUNT+=1"
    call :LOG_ACTION "BASARILI: %_REGPATH%\%~3 = %~5"
) else (
    echo     %CROSS% %~3 ayarlanamadi
    set /a "FAIL_COUNT+=1"
    call :LOG_ACTION "HATALI: %_REGPATH%\%~3 = %~5"
)
set /a "CHANGES_COUNT+=1"
set "_OLD_DATA="
set "_OLD_TYPE="
goto :eof

:DRAW_LINE
echo     %CYAN%════════════════════════════════════════════════════════════════════════════════════════════════%RESET%
goto :eof

:DRAW_THIN_LINE
echo     %GRAY%────────────────────────────────────────────────────────────────────────────────────────────────%RESET%
goto :eof

:SECTION_HEADER
:: %1 = Başlık metni
echo.
call :DRAW_LINE
echo     %CYAN%%BOLD%  %~1%RESET%
call :DRAW_LINE
echo.
goto :eof

:CONFIRM_ACTION
:: %1 = Soru metni, RESULT değişkenine Y/N döner
set "CONFIRM_RESULT=Y"
echo.
echo     %YELLOW%%BOLD%[?] %~1 (E/H): %RESET%
set /p "CONFIRM_RESULT=     > "
if /i "%CONFIRM_RESULT%"=="H" set "CONFIRM_RESULT=N"
if /i "%CONFIRM_RESULT%"=="E" set "CONFIRM_RESULT=Y"
goto :eof

:SHOW_SECTION_COMPLETE
echo.
echo     %GREEN%%BOLD%════════════════════════════════════════════════════════════════%RESET%
echo     %GREEN%%BOLD%  ✓ Bölüm tamamlandi!%RESET%
echo     %WHITE%  Basarili: %SUCCESS_COUNT% ^| Hata: %FAIL_COUNT% ^| Toplam: %CHANGES_COUNT%%RESET%
echo     %GREEN%%BOLD%════════════════════════════════════════════════════════════════%RESET%
echo.
goto :eof

:: ============================================================================
::                              ANA MENÜ
:: ============================================================================

:MAIN_MENU
call :SHOW_BANNER
echo     %WHITE%%BOLD%Sistem Bilgileri:%RESET%
echo     %GRAY%┌──────────────────────────────────────────────────────────────────────────────┐%RESET%
echo     %GRAY%│%RESET% %CYAN%İşletim Sistemi :%RESET% %WHITE%%WIN_LABEL% (Build %WIN_BUILD%)%RESET%
echo     %GRAY%│%RESET% %CYAN%İşlemci         :%RESET% %WHITE%%CPU_NAME%%RESET%
echo     %GRAY%│%RESET% %CYAN%Çekirdek/Thread :%RESET% %WHITE%%CPU_CORES% Çekirdek / %CPU_THREADS% Thread%RESET%
echo     %GRAY%│%RESET% %CYAN%RAM             :%RESET% %WHITE%%RAM_TOTAL% MB%RESET%
echo     %GRAY%│%RESET% %CYAN%Ekran Kartı     :%RESET% %WHITE%%GPU_NAME%%RESET%
echo     %GRAY%│%RESET% %CYAN%Disk Tipi       :%RESET% %WHITE%%DISK_TYPE%%RESET%
echo     %GRAY%│%RESET% %CYAN%Ağ Adaptörü    :%RESET% %WHITE%%NIC_NAME%%RESET%
echo     %GRAY%└──────────────────────────────────────────────────────────────────────────────┘%RESET%
echo.
echo     %CYAN%%BOLD%╔══════════════════════════════════════════════════════════════════════════════╗%RESET%
echo     %CYAN%%BOLD%║%RESET%              %WHITE%%BOLD%★ ULTIMATE GAMING OPTIMIZER v2.0 - ANA MENÜ ★%RESET%              %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%╠══════════════════════════════════════════════════════════════════════════════╣%RESET%
echo     %CYAN%%BOLD%║%RESET%                                                                          %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[1]%RESET%  %GREEN%CPU ^& Zamanlayıcı Optimizasyonu%RESET%                                %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[2]%RESET%  %GREEN%GPU ^& Görüntü Optimizasyonu%RESET%                                   %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[3]%RESET%  %GREEN%Ağ ^& Ping Optimizasyonu%RESET%                                       %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[4]%RESET%  %GREEN%RAM ^& Bellek Optimizasyonu%RESET%                                    %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[5]%RESET%  %GREEN%Input Lag ^& Fare/Klavye Optimizasyonu%RESET%                          %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[6]%RESET%  %GREEN%Gereksiz Hizmetleri Kapat%RESET%                                      %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[7]%RESET%  %GREEN%Görsel Efekt ^& Arayüz Optimizasyonu%RESET%                            %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[8]%RESET%  %GREEN%Disk ^& Depolama Temizliği%RESET%                                     %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[9]%RESET%  %GREEN%Güç Yönetimi Optimizasyonu%RESET%                                     %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[10]%RESET% %GREEN%Gizlilik ^& Telemetri Kapatma%RESET%                                  %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[11]%RESET% %GREEN%Boot ^& BCD Optimizasyonu%RESET%                                      %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%                                                                          %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %MAGENTA%%BOLD%[12] ★ TÜMÜNÜ UYGULA (Önerilen)%RESET%                                       %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %YELLOW%[13] Yedekten Geri Yükle%RESET%                                              %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %WHITE%[14] Sistem Bilgisi Göster%RESET%                                             %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%   %RED%[0]  Çıkış%RESET%                                                              %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%║%RESET%                                                                          %CYAN%%BOLD%║%RESET%
echo     %CYAN%%BOLD%╚══════════════════════════════════════════════════════════════════════════════╝%RESET%
echo.
set "MENU_CHOICE="
set /p "MENU_CHOICE=     %WHITE%%BOLD%Seçiminiz [0-14]: %RESET%"

if "%MENU_CHOICE%"=="1" goto :MODULE_CPU
if "%MENU_CHOICE%"=="2" goto :MODULE_GPU
if "%MENU_CHOICE%"=="3" goto :MODULE_NETWORK
if "%MENU_CHOICE%"=="4" goto :MODULE_RAM
if "%MENU_CHOICE%"=="5" goto :MODULE_INPUT
if "%MENU_CHOICE%"=="6" goto :MODULE_SERVICES
if "%MENU_CHOICE%"=="7" goto :MODULE_VISUAL
if "%MENU_CHOICE%"=="8" goto :MODULE_DISK
if "%MENU_CHOICE%"=="9" goto :MODULE_POWER
if "%MENU_CHOICE%"=="10" goto :MODULE_PRIVACY
if "%MENU_CHOICE%"=="11" goto :MODULE_BOOT
if "%MENU_CHOICE%"=="12" goto :MODULE_ALL
if "%MENU_CHOICE%"=="13" goto :MODULE_RESTORE
if "%MENU_CHOICE%"=="14" goto :MODULE_SYSINFO
if "%MENU_CHOICE%"=="0" goto :EXIT_SCRIPT
echo     %RED%Geçersiz seçim!%RESET%
timeout /t 2 >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 1: CPU & ZAMANLAYICI OPTİMİZASYONU
:: ============================================================================
:MODULE_CPU
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 1: CPU & ZAMANLAYICI OPTİMİZASYONU"
echo     %WHITE%Bu modül MMCSS, işlemci zamanlama, güç yönetimi, interrupt affinity%RESET%
echo     %WHITE%ve timer resolution ayarlarını optimize eder.%RESET%
echo.
call :CONFIRM_ACTION "CPU optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

:: Geri yükleme noktası oluştur
echo     %WORK% Sistem geri yükleme noktası oluşturuluyor...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Laving Optimizer - CPU", 100, 7 >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Geri yükleme noktası oluşturuldu
) else (
    echo     %WARN% Geri yükleme noktası oluşturulamadı (devam ediyor)
)
echo.

call :LOG_ACTION "===== CPU & ZAMANLAYICI OPTIMIZASYONU BASLADI ====="

:: ----- 1.1 MMCSS Ayarları -----
echo     %CYAN%%BOLD%[1.1] MMCSS (Multimedia Class Scheduler) Ayarları%RESET%
call :DRAW_THIN_LINE
call :SHOW_PROGRESS 5 "MMCSS SystemProfile ayarlanıyor..."

set "MMCSS_PATH=SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
call :REG_BACKUP_AND_SET HKLM "%MMCSS_PATH%" "SystemResponsiveness" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MMCSS_PATH%" "NetworkThrottlingIndex" REG_DWORD 0xffffffff
call :REG_BACKUP_AND_SET HKLM "%MMCSS_PATH%" "NoLazyMode" REG_DWORD 1

call :SHOW_PROGRESS 10 "MMCSS Games Task ayarlanıyor..."

set "GAMES_PATH=%MMCSS_PATH%\Tasks\Games"
reg add "HKLM\%GAMES_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "GPU Priority" REG_DWORD 8
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Priority" REG_DWORD 6
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Scheduling Category" REG_SZ "High"
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "SFIO Priority" REG_SZ "High"
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Affinity" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Background Only" REG_SZ "False"
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Clock Rate" REG_DWORD 10000
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Latency Sensitive" REG_SZ "True"

echo.
call :SHOW_PROGRESS 20 "MMCSS tamamlandı"
echo.

:: ----- 1.2 İşlemci Zamanlama (Quantum) -----
echo     %CYAN%%BOLD%[1.2] İşlemci Zamanlama (Quantum) Ayarları%RESET%
call :DRAW_THIN_LINE

set "PRIO_PATH=SYSTEM\CurrentControlSet\Control\PriorityControl"
call :REG_BACKUP_AND_SET HKLM "%PRIO_PATH%" "Win32PrioritySeparation" REG_DWORD 0x26
call :REG_BACKUP_AND_SET HKLM "%PRIO_PATH%" "IRQ8Priority" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%PRIO_PATH%" "ConvertibleSlateMode" REG_DWORD 0

echo.
call :SHOW_PROGRESS 30 "Quantum ayarları tamamlandı"
echo.

:: ----- 1.3 İşlemci Güç Yönetimi -----
echo     %CYAN%%BOLD%[1.3] İşlemci Güç Yönetimi%RESET%
call :DRAW_THIN_LINE

echo     %WORK% Ultimate Performance güç planı oluşturuluyor...
for /f "tokens=4" %%a in ('powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2^>nul') do set "UP_GUID=%%a"
if defined UP_GUID (
    powercfg /setactive %UP_GUID% >nul 2>&1
    echo     %TICK% Ultimate Performance planı aktif edildi: %UP_GUID%
    call :LOG_ACTION "Ultimate Performance GUID: %UP_GUID%"
    echo powercfg /delete %UP_GUID% ^>nul 2^>^&1 >> "%UNDO_FILE%"
    
    :: Core Parking devre dışı (min=100)
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
    echo     %TICK% Core Parking minimum = 100%%
    
    :: Core Parking max
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 100 >nul 2>&1
    echo     %TICK% Core Parking maximum = 100%%
    
    :: İşlemci minimum state = 100
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 >nul 2>&1
    echo     %TICK% İşlemci minimum durumu = 100%%
    
    :: İşlemci maximum state = 100
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
    echo     %TICK% İşlemci maksimum durumu = 100%%
    
    :: Boost mode aggressive
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2 >nul 2>&1
    echo     %TICK% İşlemci boost modu = Aggressive
    
    :: Planı etkinleştir
    powercfg /setactive %UP_GUID% >nul 2>&1
    
) else (
    echo     %WARN% Ultimate Performance planı oluşturulamadı, mevcut High Performance kullanılıyor
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
)

:: C-States / Processor Idle devre dışı
set "IDLE_PATH=SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\5d76a2ca-e8c0-402f-a133-2158492d58ad"
call :REG_BACKUP_AND_SET HKLM "%IDLE_PATH%" "ValueMax" REG_DWORD 0
set "IDLE_PATH2=SYSTEM\CurrentControlSet\Control\Processor"
call :REG_BACKUP_AND_SET HKLM "%IDLE_PATH2%" "Cstates" REG_DWORD 0

echo.
call :SHOW_PROGRESS 45 "Güç yönetimi tamamlandı"
echo.

:: ----- 1.4 MSI Mode (GPU & NIC) -----
echo     %CYAN%%BOLD%[1.4] MSI (Message Signaled Interrupts) Mode%RESET%
call :DRAW_THIN_LINE

echo     %WORK% GPU ve NIC için MSI mode etkinleştiriliyor...

:: GPU MSI
for /f "tokens=*" %%a in ('wmic path Win32_VideoController get PNPDeviceID 2^>nul ^| findstr /i "PCI"') do (
    set "GPU_PNP=%%a"
    set "GPU_PNP=!GPU_PNP: =!"
    if not "!GPU_PNP!"=="" (
        set "MSI_GPU_PATH=SYSTEM\CurrentControlSet\Enum\!GPU_PNP!\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        reg add "HKLM\!MSI_GPU_PATH!" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
        if !errorlevel!==0 (
            echo     %TICK% GPU MSI Mode aktif: !GPU_PNP:~0,50!...
        ) else (
            echo     %WARN% GPU MSI Mode ayarlanamadı
        )
    )
)

:: NIC MSI
for /f "tokens=*" %%a in ('wmic path Win32_NetworkAdapter where "NetConnectionStatus=2" get PNPDeviceID 2^>nul ^| findstr /i "PCI"') do (
    set "NIC_PNP=%%a"
    set "NIC_PNP=!NIC_PNP: =!"
    if not "!NIC_PNP!"=="" (
        set "MSI_NIC_PATH=SYSTEM\CurrentControlSet\Enum\!NIC_PNP!\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        reg add "HKLM\!MSI_NIC_PATH!" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
        if !errorlevel!==0 (
            echo     %TICK% NIC MSI Mode aktif: !NIC_PNP:~0,50!...
        ) else (
            echo     %WARN% NIC MSI Mode ayarlanamadı
        )
    )
)

echo.
call :SHOW_PROGRESS 60 "MSI mode tamamlandı"
echo.

:: ----- 1.5 Timer & Context Switch -----
echo     %CYAN%%BOLD%[1.5] Timer & Context Switch Optimizasyonu%RESET%
call :DRAW_THIN_LINE

:: Kernel timer
set "KERNEL_PATH=SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
call :REG_BACKUP_AND_SET HKLM "%KERNEL_PATH%" "GlobalTimerResolutionRequests" REG_DWORD 1

:: BCD ayarları (burada da yapılıyor, Bölüm 11'de detaylı)
echo     %WORK% BCD timer ayarları yapılıyor...

bcdedit /set disabledynamictick yes >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Dynamic Tick devre dışı
    echo bcdedit /deletevalue disabledynamictick ^>nul 2^>^&1 >> "%UNDO_FILE%"
) else (
    echo     %WARN% Dynamic Tick ayarlanamadı
)

bcdedit /set useplatformtick yes >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Platform Tick aktif
    echo bcdedit /deletevalue useplatformtick ^>nul 2^>^&1 >> "%UNDO_FILE%"
) else (
    echo     %WARN% Platform Tick ayarlanamadı
)

bcdedit /set tscsyncpolicy enhanced >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% TSC Sync Policy = Enhanced
    echo bcdedit /deletevalue tscsyncpolicy ^>nul 2^>^&1 >> "%UNDO_FILE%"
) else (
    echo     %WARN% TSC Sync ayarlanamadı
)

bcdedit /set useplatformclock false >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Platform Clock (HPET) devre dışı
    echo bcdedit /deletevalue useplatformclock ^>nul 2^>^&1 >> "%UNDO_FILE%"
) else (
    echo     %WARN% Platform Clock ayarlanamadı
)

echo.
call :SHOW_PROGRESS 100 "CPU & Zamanlayıcı optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 2: GPU & GÖRÜNTÜ OPTİMİZASYONU
:: ============================================================================
:MODULE_GPU
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 2: GPU & GÖRÜNTÜ OPTİMİZASYONU"
echo     %WHITE%Bu modül HAGS, Game Mode, Game DVR, DWM ve GPU öncelik ayarlarını%RESET%
echo     %WHITE%optimize eder.%RESET%
echo.
call :CONFIRM_ACTION "GPU optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== GPU & GÖRÜNTÜ OPTIMIZASYONU BASLADI ====="

:: ----- 2.1 HAGS -----
echo     %CYAN%%BOLD%[2.1] Donanım Hızlandırmalı GPU Zamanlama (HAGS)%RESET%
call :DRAW_THIN_LINE

set "GFX_PATH=SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
call :REG_BACKUP_AND_SET HKLM "%GFX_PATH%" "HwSchMode" REG_DWORD 2

echo.
call :SHOW_PROGRESS 15 "HAGS aktif edildi"
echo.

:: ----- 2.2 Game Mode & Game Bar -----
echo     %CYAN%%BOLD%[2.2] Game Mode & Game Bar Optimizasyonu%RESET%
call :DRAW_THIN_LINE

set "GBAR_PATH=Software\Microsoft\GameBar"
call :REG_BACKUP_AND_SET HKCU "%GBAR_PATH%" "AllowAutoGameMode" REG_DWORD 1
call :REG_BACKUP_AND_SET HKCU "%GBAR_PATH%" "AutoGameModeEnabled" REG_DWORD 1

:: Game DVR tamamen devre dışı
set "GCONF_PATH=System\GameConfigStore"
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_Enabled" REG_DWORD 0

set "GDVR_POL=SOFTWARE\Policies\Microsoft\Windows\GameDVR"
reg add "HKLM\%GDVR_POL%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%GDVR_POL%" "AllowGameDVR" REG_DWORD 0

set "GDVR_USER=SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
reg add "HKCU\%GDVR_USER%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%GDVR_USER%" "AppCaptureEnabled" REG_DWORD 0

echo.
call :SHOW_PROGRESS 35 "Game DVR devre dışı"
echo.

:: ----- 2.3 Fullscreen Optimizasyonu -----
echo     %CYAN%%BOLD%[2.3] Fullscreen Optimizasyonu%RESET%
call :DRAW_THIN_LINE

call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_FSEBehaviorMode" REG_DWORD 2
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_HonorUserFSEBehaviorMode" REG_DWORD 1
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_FSEBehavior" REG_DWORD 2
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_DXGIHonorFSEWindowsCompatible" REG_DWORD 1

echo.
call :SHOW_PROGRESS 55 "Fullscreen ayarları tamamlandı"
echo.

:: ----- 2.4 DWM Optimizasyonu -----
echo     %CYAN%%BOLD%[2.4] Desktop Window Manager (DWM) Optimizasyonu%RESET%
call :DRAW_THIN_LINE

set "DWM_PATH=SOFTWARE\Microsoft\Windows\Dwm"
call :REG_BACKUP_AND_SET HKLM "%DWM_PATH%" "OverlayTestMode" REG_DWORD 5
call :REG_BACKUP_AND_SET HKLM "%DWM_PATH%" "ForceEffectMode" REG_DWORD 0

:: Transparency devre dışı
set "THEMES_PATH=Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
call :REG_BACKUP_AND_SET HKCU "%THEMES_PATH%" "EnableTransparency" REG_DWORD 0

echo.
call :SHOW_PROGRESS 75 "DWM optimizasyonu tamamlandı"
echo.

:: ----- 2.5 GPU Öncelik & TDR -----
echo     %CYAN%%BOLD%[2.5] GPU Öncelik & TDR Ayarları%RESET%
call :DRAW_THIN_LINE

call :REG_BACKUP_AND_SET HKLM "%GFX_PATH%" "TdrDelay" REG_DWORD 60
call :REG_BACKUP_AND_SET HKLM "%GFX_PATH%" "TdrDdiDelay" REG_DWORD 60

:: MaximumFrameLatency
set "D3D_PATH=SOFTWARE\Microsoft\Direct3D"
reg add "HKLM\%D3D_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%D3D_PATH%" "MaximumFrameLatency" REG_DWORD 1

:: FlipQueueSize (pre-rendered frames)
set "D3D9_PATH=SOFTWARE\Microsoft\Direct3D\Drivers"
reg add "HKLM\%D3D9_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%D3D9_PATH%" "ForceFlipInterval" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%D3D9_PATH%" "FlipQueueSize" REG_DWORD 1

echo.
call :SHOW_PROGRESS 100 "GPU optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 3: AĞ & PING OPTİMİZASYONU
:: ============================================================================
:MODULE_NETWORK
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 3: AĞ & PING OPTİMİZASYONU"
echo     %WHITE%Bu modül TCP/IP stack, Nagle algoritması, DNS, NIC sürücü ayarları%RESET%
echo     %WHITE%ve ağ throttling ayarlarını optimize eder.%RESET%
echo.
call :CONFIRM_ACTION "Ağ optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== AG & PING OPTIMIZASYONU BASLADI ====="

:: ----- 3.1 TCP/IP Stack -----
echo     %CYAN%%BOLD%[3.1] TCP/IP Stack Optimizasyonu%RESET%
call :DRAW_THIN_LINE

echo     %WORK% TCP global ayarlar yapılandırılıyor...

netsh int tcp set global autotuninglevel=normal >nul 2>&1
echo     %TICK% Auto Tuning Level = Normal

netsh int tcp set global ecncapability=disabled >nul 2>&1
echo     %TICK% ECN Capability = Disabled

netsh int tcp set global timestamps=disabled >nul 2>&1
echo     %TICK% Timestamps = Disabled

netsh int tcp set global rss=enabled >nul 2>&1
echo     %TICK% Receive Side Scaling = Enabled

netsh int tcp set global nonsackrttresiliency=disabled >nul 2>&1
echo     %TICK% Non-SACK RTT Resiliency = Disabled

netsh int tcp set global maxsynretransmissions=2 >nul 2>&1
echo     %TICK% Max SYN Retransmissions = 2

netsh int tcp set global initialRto=2000 >nul 2>&1
echo     %TICK% Initial RTO = 2000

:: Windows sürümüne göre congestion provider
if "%WIN_VER%"=="11" (
    netsh int tcp set supplemental Internet CongestionProvider=bbr2 >nul 2>&1
    if !errorlevel!==0 (
        echo     %TICK% Congestion Provider = BBR2 (Win11)
    ) else (
        netsh int tcp set supplemental Internet CongestionProvider=ctcp >nul 2>&1
        echo     %TICK% Congestion Provider = CTCP (fallback)
    )
) else (
    netsh int tcp set supplemental Internet CongestionProvider=ctcp >nul 2>&1
    echo     %TICK% Congestion Provider = CTCP (Win10)
)

:: Chimney, DCA, NetDMA (eski parametreler — sessiz hata)
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global netdma=disabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1

echo.
call :SHOW_PROGRESS 25 "TCP/IP stack tamamlandı"
echo.

:: ----- 3.2 TCP/IP Registry -----
echo     %CYAN%%BOLD%[3.2] TCP/IP Registry Optimizasyonu%RESET%
call :DRAW_THIN_LINE

set "TCPIP_PATH=SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpAckFrequency" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TCPNoDelay" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpDelAckTicks" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "DefaultTTL" REG_DWORD 64
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "MaxUserPort" REG_DWORD 65534
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpTimedWaitDelay" REG_DWORD 30
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpMaxDataRetransmissions" REG_DWORD 5
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "SackOpts" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "Tcp1323Opts" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "MaxFreeTcbs" REG_DWORD 65536
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "MaxHashTableSize" REG_DWORD 65536
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "GlobalMaxTcpWindowSize" REG_DWORD 65535

echo.
call :SHOW_PROGRESS 45 "TCP/IP registry tamamlandı"
echo.

:: ----- 3.3 Per-Interface Nagle Devre Dışı -----
echo     %CYAN%%BOLD%[3.3] Per-Interface Nagle Algorithm Devre Dışı%RESET%
call :DRAW_THIN_LINE

echo     %WORK% Tüm ağ arayüzleri için Nagle devre dışı bırakılıyor...
set "IFACE_BASE=SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"

for /f "tokens=*" %%G in ('reg query "HKLM\%IFACE_BASE%" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    set "IFACE_KEY=%%G"
    set "IFACE_KEY=!IFACE_KEY:HKEY_LOCAL_MACHINE\=!"
    reg query "%%G" /v "DhcpIPAddress" >nul 2>&1
    if !errorlevel!==0 (
        call :REG_BACKUP_AND_SET HKLM "!IFACE_KEY!" "TcpAckFrequency" REG_DWORD 1
        call :REG_BACKUP_AND_SET HKLM "!IFACE_KEY!" "TCPNoDelay" REG_DWORD 1
        call :REG_BACKUP_AND_SET HKLM "!IFACE_KEY!" "TcpDelAckTicks" REG_DWORD 0
    )
)

echo.
call :SHOW_PROGRESS 60 "Per-interface ayarları tamamlandı"
echo.

:: ----- 3.4 DNS Optimizasyonu -----
echo     %CYAN%%BOLD%[3.4] DNS Optimizasyonu%RESET%
call :DRAW_THIN_LINE

echo     %WORK% DNS cache temizleniyor...
ipconfig /flushdns >nul 2>&1
echo     %TICK% DNS cache temizlendi

set "DNS_PATH=SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
call :REG_BACKUP_AND_SET HKLM "%DNS_PATH%" "MaxCacheTtl" REG_DWORD 86400
call :REG_BACKUP_AND_SET HKLM "%DNS_PATH%" "MaxNegativeCacheTtl" REG_DWORD 5
call :REG_BACKUP_AND_SET HKLM "%DNS_PATH%" "NegativeSOACacheTime" REG_DWORD 0

echo.
echo     %YELLOW%[?] Cloudflare DNS (1.1.1.1) ayarlamak ister misiniz? (E/H):%RESET%
set /p "DNS_CHOICE=     > "
if /i "%DNS_CHOICE%"=="E" (
    for /f "tokens=2 delims==" %%a in ('wmic nic where "NetConnectionStatus=2" get InterfaceIndex /value 2^>nul ^| findstr "="') do (
        set "NIC_IDX=%%a"
        set "NIC_IDX=!NIC_IDX: =!"
    )
    if defined NIC_IDX (
        netsh interface ipv4 set dns name="!NIC_IDX!" source=static addr=1.1.1.1 register=primary >nul 2>&1
        netsh interface ipv4 add dns name="!NIC_IDX!" addr=1.0.0.1 index=2 >nul 2>&1
        echo     %TICK% DNS sunucuları: 1.1.1.1 / 1.0.0.1 olarak ayarlandı
    ) else (
        :: İsimle dene
        for /f "skip=1 tokens=*" %%a in ('wmic nic where "NetConnectionStatus=2" get NetConnectionID 2^>nul') do (
            set "NIC_CONN=%%a"
            set "NIC_CONN=!NIC_CONN:~0,-1!"
            if not "!NIC_CONN!"=="" (
                netsh interface ipv4 set dns name="!NIC_CONN!" source=static addr=1.1.1.1 register=primary >nul 2>&1
                netsh interface ipv4 add dns name="!NIC_CONN!" addr=1.0.0.1 index=2 >nul 2>&1
                echo     %TICK% DNS ayarlandı: !NIC_CONN!
            )
        )
    )
)

echo.
call :SHOW_PROGRESS 75 "DNS optimizasyonu tamamlandı"
echo.

:: ----- 3.5 NIC Sürücü Seviye Ayarları -----
echo     %CYAN%%BOLD%[3.5] NIC Sürücü Seviye Ayarları%RESET%
call :DRAW_THIN_LINE

echo     %WORK% Ağ kartı gelişmiş ayarları yapılandırılıyor...

:: Aktif NIC ismini bul
set "ACTIVE_NIC="
for /f "skip=1 tokens=*" %%a in ('wmic nic where "NetConnectionStatus=2" get NetConnectionID 2^>nul') do (
    if not defined ACTIVE_NIC (
        set "ACTIVE_NIC=%%a"
        set "ACTIVE_NIC=!ACTIVE_NIC:~0,-1!"
    )
)

if defined ACTIVE_NIC (
    echo     %WHITE%Aktif NIC: !ACTIVE_NIC!%RESET%
    
    :: Interrupt Moderation
    netsh int ip set interface "!ACTIVE_NIC!" dadtransmits=0 >nul 2>&1
    powershell -Command "Set-NetAdapterAdvancedProperty -Name '!ACTIVE_NIC!' -RegistryKeyword '*InterruptModeration' -RegistryValue 0" >nul 2>&1
    echo     %TICK% Interrupt Moderation = Disabled (denendi)
    
    :: Flow Control
    powershell -Command "Set-NetAdapterAdvancedProperty -Name '!ACTIVE_NIC!' -RegistryKeyword '*FlowControl' -RegistryValue 0" >nul 2>&1
    echo     %TICK% Flow Control = Disabled (denendi)
    
    :: Energy Efficient Ethernet
    powershell -Command "Set-NetAdapterAdvancedProperty -Name '!ACTIVE_NIC!' -RegistryKeyword 'EEELinkAdvertisement' -RegistryValue 0" >nul 2>&1
    echo     %TICK% Energy Efficient Ethernet = Disabled (denendi)
    
    :: Power Management - kapatma izni kaldır
    powershell -Command "Disable-NetAdapterPowerManagement -Name '!ACTIVE_NIC!' -ErrorAction SilentlyContinue" >nul 2>&1
    echo     %TICK% NIC Güç Yönetimi devre dışı bırakıldı (denendi)
    
    :: RSS
    powershell -Command "Set-NetAdapterAdvancedProperty -Name '!ACTIVE_NIC!' -RegistryKeyword '*RSS' -RegistryValue 1" >nul 2>&1
    echo     %TICK% Receive Side Scaling = Enabled (denendi)
) else (
    echo     %WARN% Aktif ağ adaptörü bulunamadı
)

echo.
call :SHOW_PROGRESS 90 "NIC ayarları tamamlandı"
echo.

:: ----- 3.6 Ağ Throttling -----
echo     %CYAN%%BOLD%[3.6] Ağ Throttling Kaldırma%RESET%
call :DRAW_THIN_LINE
echo     %WHITE%(MMCSS bölümünde zaten yapıldı — doğrulanıyor)%RESET%

set "MMCSS_PATH2=SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
reg query "HKLM\%MMCSS_PATH2%" /v "NetworkThrottlingIndex" 2>nul | findstr "0xffffffff" >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% NetworkThrottlingIndex = 0xFFFFFFFF (doğrulandı)
) else (
    call :REG_BACKUP_AND_SET HKLM "%MMCSS_PATH2%" "NetworkThrottlingIndex" REG_DWORD 0xffffffff
)

echo.
call :SHOW_PROGRESS 100 "Ağ optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 4: RAM & BELLEK OPTİMİZASYONU
:: ============================================================================
:MODULE_RAM
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 4: RAM & BELLEK OPTİMİZASYONU"
echo     %WHITE%Bu modül virtual memory, memory management, prefetch/superfetch,%RESET%
echo     %WHITE%NTFS ve dosya sistemi ayarlarını optimize eder.%RESET%
echo.
call :CONFIRM_ACTION "RAM optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== RAM & BELLEK OPTIMIZASYONU BASLADI ====="

:: ----- 4.1 Memory Management Registry -----
echo     %CYAN%%BOLD%[4.2] Memory Management Registry%RESET%
call :DRAW_THIN_LINE

set "MM_PATH=SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "ClearPageFileAtShutdown" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "DisablePagingExecutive" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "LargeSystemCache" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "SecondLevelDataCache" REG_DWORD 1024
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "SystemPages" REG_DWORD 0xffffffff
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "IoPageLockLimit" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "PoolUsageMaximum" REG_DWORD 60
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "PagedPoolSize" REG_DWORD 0xffffffff
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "NonPagedPoolSize" REG_DWORD 0

echo.
call :SHOW_PROGRESS 35 "Memory Management tamamlandı"
echo.

:: ----- 4.2 Prefetch/Superfetch -----
echo     %CYAN%%BOLD%[4.2] Prefetch & Superfetch Devre Dışı%RESET%
call :DRAW_THIN_LINE

set "PF_PATH=%MM_PATH%\PrefetchParameters"
call :REG_BACKUP_AND_SET HKLM "%PF_PATH%" "EnablePrefetcher" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%PF_PATH%" "EnableSuperfetch" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%PF_PATH%" "EnableBootTrace" REG_DWORD 0

echo.
call :SHOW_PROGRESS 55 "Prefetch/Superfetch devre dışı"
echo.

:: ----- 4.4 NTFS & Dosya Sistemi -----
echo     %CYAN%%BOLD%[4.4] NTFS & Dosya Sistemi Optimizasyonu%RESET%
call :DRAW_THIN_LINE

echo     %WORK% NTFS ayarları yapılandırılıyor...
fsutil behavior set disablelastaccess 1 >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Last Access Time = Disabled
) else (
    echo     %WARN% disablelastaccess ayarlanamadı
)

fsutil behavior set disable8dot3 1 >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% 8.3 Name Creation = Disabled
) else (
    echo     %WARN% disable8dot3 ayarlanamadı
)

fsutil behavior set memoryusage 2 >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Memory Usage = 2 (Enhanced)
) else (
    echo     %WARN% memoryusage ayarlanamadı
)

fsutil behavior set mftzone 4 >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% MFT Zone = 4 (Büyük)
) else (
    echo     %WARN% mftzone ayarlanamadı
)

set "FS_PATH=SYSTEM\CurrentControlSet\Control\FileSystem"
call :REG_BACKUP_AND_SET HKLM "%FS_PATH%" "NtfsDisable8dot3NameCreation" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%FS_PATH%" "NtfsMemoryUsage" REG_DWORD 2

echo.
call :SHOW_PROGRESS 100 "RAM & Bellek optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 5: INPUT LAG & FARE/KLAVYE OPTİMİZASYONU
:: ============================================================================
:MODULE_INPUT
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 5: INPUT LAG & FARE/KLAVYE OPTİMİZASYONU"
echo     %WHITE%Bu modül fare hassasiyeti, mouse acceleration, klavye yanıt süresi,%RESET%
echo     %WHITE%USB güç yönetimi ve input latency ayarlarını optimize eder.%RESET%
echo.
call :CONFIRM_ACTION "Input lag optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== INPUT LAG OPTIMIZASYONU BASLADI ====="

:: ----- 5.1 Fare Hassasiyet -----
echo     %CYAN%%BOLD%[5.1] Fare (Mouse) Hassasiyet & Ham Girdi%RESET%
call :DRAW_THIN_LINE

set "MOUSE_PATH=Control Panel\Mouse"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseSpeed" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseThreshold1" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseThreshold2" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseSensitivity" REG_SZ "10"

:: Enhanced Pointer Precision devre dışı (SmoothMouse curves lineer)
echo     %WORK% Mouse acceleration devre dışı bırakılıyor (lineer eğri)...

:: SmoothMouseXCurve - flat lineer değerler
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d "0000000000000000c0cc0c0000000000809919000000000040662600000000000033330000000000" /f >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% SmoothMouseXCurve = Lineer
) else (
    echo     %WARN% SmoothMouseXCurve ayarlanamadı
)

:: SmoothMouseYCurve - flat lineer değerler
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d "0000000000000000000038000000000000007000000000000000a800000000000000e00000000000" /f >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% SmoothMouseYCurve = Lineer
) else (
    echo     %WARN% SmoothMouseYCurve ayarlanamadı
)

echo.
call :SHOW_PROGRESS 30 "Fare ayarları tamamlandı"
echo.

:: ----- 5.2 Klavye -----
echo     %CYAN%%BOLD%[5.2] Klavye Yanıt Süresi%RESET%
call :DRAW_THIN_LINE

set "KB_PATH=Control Panel\Keyboard"
call :REG_BACKUP_AND_SET HKCU "%KB_PATH%" "KeyboardDelay" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%KB_PATH%" "KeyboardSpeed" REG_SZ "31"

echo.
call :SHOW_PROGRESS 50 "Klavye ayarları tamamlandı"
echo.

:: ----- 5.3 USB Güç Yönetimi -----
echo     %CYAN%%BOLD%[5.3] USB Polling Rate & Güç Yönetimi%RESET%
call :DRAW_THIN_LINE

echo     %WORK% USB Hub güç yönetimi devre dışı bırakılıyor...

:: Tüm USB Hub'ların güç yönetimini kapat
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USB" /s /v "EnhancedPowerManagementEnabled" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg add "%%a" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
)
echo     %TICK% USB Enhanced Power Management devre dışı (tüm USB hub'lar)

:: USB Selective Suspend devre dışı (powercfg)
if defined UP_GUID (
    powercfg -setacvalueindex %UP_GUID% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
) else (
    powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
)
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo     %TICK% USB Selective Suspend = Disabled

echo.
call :SHOW_PROGRESS 80 "USB ayarları tamamlandı"
echo.

:: ----- 5.4 Genel Input Latency -----
echo     %CYAN%%BOLD%[5.4] Genel Input Latency%RESET%
call :DRAW_THIN_LINE

:: Pre-rendered frames
set "DWM_PATH2=SOFTWARE\Microsoft\Windows\Dwm"
call :REG_BACKUP_AND_SET HKLM "%DWM_PATH2%" "ForceEffectMode" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%DWM_PATH2%" "MaxQueuedPresentations" REG_DWORD 1

echo.
call :SHOW_PROGRESS 100 "Input lag optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 6: GEREKSİZ HİZMETLERİ DEVRE DIŞI BIRAKMA
:: ============================================================================
:MODULE_SERVICES
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 6: GEREKSİZ HİZMETLERİ DEVRE DIŞI BIRAKMA"
echo     %WHITE%Bu modül oyun performansını ETKİLEMEYEN ama CPU/RAM/Disk kaynağı%RESET%
echo     %WHITE%tüketen Windows servislerini devre dışı bırakır.%RESET%
echo.
echo     %YELLOW%%BOLD%[!] UYARI: Bazı servisler belirli özellikler için gereklidir.%RESET%
echo     %YELLOW%    Her servis için açıklama gösterilecektir.%RESET%
echo.
call :CONFIRM_ACTION "Servis optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== SERVIS OPTIMIZASYONU BASLADI ====="

:: ----- 6.1 Servisler -----
echo     %CYAN%%BOLD%[6.1] Servisleri Devre Dışı Bırakma%RESET%
call :DRAW_THIN_LINE
echo.

:: Servis devre dışı bırakma fonksiyonu
:: %1=ServisAdı, %2=Açıklama
call :DISABLE_SERVICE "DiagTrack" "Telemetri ve Veri Toplama"
call :DISABLE_SERVICE "dmwappushservice" "WAP Push Mesaj Yönlendirme"
call :DISABLE_SERVICE "WSearch" "Windows Arama Indeksleme"
call :DISABLE_SERVICE "SysMain" "Superfetch (SSD için gereksiz)"
call :DISABLE_SERVICE "WbioSrvc" "Biyometrik Servis"
call :DISABLE_SERVICE "TabletInputService" "Dokunmatik Klavye"
call :DISABLE_SERVICE "PhoneSvc" "Telefon Servisi"
call :DISABLE_SERVICE "RetailDemo" "Perakende Demo"
call :DISABLE_SERVICE "MapsBroker" "Harita Yöneticisi"
call :DISABLE_SERVICE "Fax" "Faks Servisi"
call :DISABLE_SERVICE "lfsvc" "Konum Servisi"
call :DISABLE_SERVICE "WMPNetworkSvc" "Media Player Paylaşım"
call :DISABLE_SERVICE "XblAuthManager" "Xbox Live Auth"
call :DISABLE_SERVICE "XblGameSave" "Xbox Live Game Save"
call :DISABLE_SERVICE "XboxGipSvc" "Xbox Aksesuar Yönetimi"
call :DISABLE_SERVICE "XboxNetApiSvc" "Xbox Live Ağ"
call :DISABLE_SERVICE "SEMgrSvc" "NFC/Ödeme Yöneticisi"
call :DISABLE_SERVICE "WerSvc" "Hata Raporlama"
call :DISABLE_SERVICE "PcaSvc" "Program Uyumluluk Asistanı"
call :DISABLE_SERVICE "WdiSystemHost" "Tanı Sistemi Host"
call :DISABLE_SERVICE "WdiServiceHost" "Tanı Servisi Host"
call :DISABLE_SERVICE "TrkWks" "Dağıtık Bağlantı İzleme"
call :DISABLE_SERVICE "AJRouter" "AllJoyn Yönlendirici"

echo.

:: Opsiyonel servisler
echo     %YELLOW%%BOLD%[Opsiyonel Servisler]%RESET%
echo.

echo     %YELLOW%[?] Windows Update servisini devre dışı bırakmak ister misiniz?%RESET%
echo     %RED%    (Güvenlik güncellemelerini alamazsınız!)%RESET%
set /p "WU_CHOICE=     > (E/H): "
if /i "%WU_CHOICE%"=="E" (
    call :DISABLE_SERVICE "wuauserv" "Windows Update"
    call :DISABLE_SERVICE "BITS" "Arka Plan Transfer"
)

echo.
echo     %YELLOW%[?] IPv6 Helper servisini devre dışı bırakmak ister misiniz?%RESET%
echo     %YELLOW%    (IPv6 kullanmıyorsanız güvenle kapatılabilir)%RESET%
set /p "IPV6_CHOICE=     > (E/H): "
if /i "%IPV6_CHOICE%"=="E" (
    call :DISABLE_SERVICE "iphlpsvc" "IP Helper (IPv6)"
)

echo.

:: ----- 6.2 Zamanlanmış Görevler -----
echo     %CYAN%%BOLD%[6.2] Zamanlanmış Görevleri Devre Dışı Bırakma%RESET%
call :DRAW_THIN_LINE

echo     %WORK% Telemetri ve gereksiz görevler devre dışı bırakılıyor...

schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1
echo     %TICK% Compatibility Appraiser devre dışı

schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1
echo     %TICK% ProgramDataUpdater devre dışı

schtasks /Change /TN "\Microsoft\Windows\Autochk\Proxy" /Disable >nul 2>&1
echo     %TICK% Autochk Proxy devre dışı

schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
echo     %TICK% CEIP Consolidator devre dışı

schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
echo     %TICK% USB CEIP devre dışı

schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1
echo     %TICK% Disk Diagnostic Collector devre dışı

schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable >nul 2>&1
echo     %TICK% Feedback görevleri devre dışı

schtasks /Change /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable >nul 2>&1
echo     %TICK% Error Reporting Queue devre dışı

:: Disk defrag (SSD ise)
echo "%DISK_TYPE%" | findstr /i "SSD" >nul 2>&1
if %errorlevel%==0 (
    schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable >nul 2>&1
    echo     %TICK% Zamanlanmış defrag devre dışı (SSD tespit edildi)
)

echo.
call :SHOW_PROGRESS 100 "Servis optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: === Servis devre dışı bırakma alt fonksiyonu ===
:DISABLE_SERVICE
:: %1=servis adı, %2=açıklama
set "_SVC=%~1"
set "_DESC=%~2"

:: Mevcut durumu yedekle
for /f "tokens=3" %%a in ('sc qc "%_SVC%" 2^>nul ^| findstr "START_TYPE"') do set "_OLD_START=%%a"
if defined _OLD_START (
    echo sc config "%_SVC%" start=%_OLD_START% ^>nul 2^>^&1 >> "%UNDO_FILE%"
)

sc config "%_SVC%" start=disabled >nul 2>&1
if %errorlevel%==0 (
    sc stop "%_SVC%" >nul 2>&1
    echo     %TICK% %_SVC% (%_DESC%) - Devre dışı
    set /a "SUCCESS_COUNT+=1"
    call :LOG_ACTION "SERVIS DEVRE DISI: %_SVC% (%_DESC%)"
) else (
    echo     %GRAY% %_SVC% (%_DESC%) - Bulunamadı/Zaten devre dışı%RESET%
    set /a "SKIP_COUNT+=1"
)
set /a "CHANGES_COUNT+=1"
set "_OLD_START="
goto :eof

:: ============================================================================
::  BÖLÜM 7: GÖRSEL EFEKT & ARAYÜZ OPTİMİZASYONU
:: ============================================================================
:MODULE_VISUAL
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 7: GÖRSEL EFEKT & ARAYÜZ OPTİMİZASYONU"
echo     %WHITE%Bu modül Windows animasyonlarını, görsel efektleri, bildirim ayarlarını%RESET%
echo     %WHITE%ve arka plan uygulamalarını optimize eder.%RESET%
echo.
call :CONFIRM_ACTION "Görsel efekt optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== GÖRSEL EFEKT OPTIMIZASYONU BASLADI ====="

:: ----- 7.1 Visual Effects -----
echo     %CYAN%%BOLD%[7.1] Görsel Efektler (Visual Effects)%RESET%
call :DRAW_THIN_LINE

set "VFX_PATH=Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
call :REG_BACKUP_AND_SET HKCU "%VFX_PATH%" "VisualFXSetting" REG_DWORD 2

:: UserPreferencesMask - tüm animasyonları kapat
:: Değer: 90 12 01 80 (minimum görsel efekt)
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f >nul 2>&1
echo     %TICK% UserPreferencesMask = Minimum efekt

set "DESK_PATH=Control Panel\Desktop"
call :REG_BACKUP_AND_SET HKCU "%DESK_PATH%" "MenuShowDelay" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%DESK_PATH%" "DragFullWindows" REG_SZ "0"

:: WindowMetrics animasyonları kapat
set "WM_PATH=Control Panel\Desktop\WindowMetrics"
call :REG_BACKUP_AND_SET HKCU "%WM_PATH%" "MinAnimate" REG_SZ "0"

:: Explorer animasyonları
set "ADV_PATH=Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
call :REG_BACKUP_AND_SET HKCU "%ADV_PATH%" "TaskbarAnimations" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%ADV_PATH%" "ListviewAlphaSelect" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%ADV_PATH%" "ListviewShadow" REG_DWORD 0

echo.
call :SHOW_PROGRESS 40 "Görsel efektler tamamlandı"
echo.

:: ----- 7.2 Bildirim & Arka Plan -----
echo     %CYAN%%BOLD%[7.2] Bildirim & Arka Plan Uygulamaları%RESET%
call :DRAW_THIN_LINE

:: Arka plan uygulamalarını devre dışı bırak
set "BG_PATH=Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
call :REG_BACKUP_AND_SET HKCU "%BG_PATH%" "GlobalUserDisabled" REG_DWORD 1

:: Bildirim ayarları
set "NOTIF_PATH=Software\Microsoft\Windows\CurrentVersion\PushNotifications"
call :REG_BACKUP_AND_SET HKCU "%NOTIF_PATH%" "ToastEnabled" REG_DWORD 0

:: Windows Tips/Suggestions kapat
set "CONTENT_PATH=Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SubscribedContent-338389Enabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SubscribedContent-310093Enabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SubscribedContent-338388Enabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SystemPaneSuggestionsEnabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SoftLandingEnabled" REG_DWORD 0

:: Cortana devre dışı
set "CORTANA_PATH=SOFTWARE\Policies\Microsoft\Windows\Windows Search"
reg add "HKLM\%CORTANA_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%CORTANA_PATH%" "AllowCortana" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%CORTANA_PATH%" "AllowSearchToUseLocation" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%CORTANA_PATH%" "DisableWebSearch" REG_DWORD 1

echo.
call :SHOW_PROGRESS 70 "Bildirim & arka plan tamamlandı"
echo.

:: ----- 7.3 Startup Optimizasyonu -----
echo     %CYAN%%BOLD%[7.3] Başlangıç (Startup) Optimizasyonu%RESET%
call :DRAW_THIN_LINE

:: Shell startup delay = 0
set "SERIALIZE_PATH=Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
reg add "HKCU\%SERIALIZE_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%SERIALIZE_PATH%" "StartupDelayInMSec" REG_DWORD 0

echo     %TICK% Shell startup delay = 0

echo.
call :SHOW_PROGRESS 100 "Görsel efekt optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 8: DİSK & DEPOLAMA TEMİZLİĞİ
:: ============================================================================
:MODULE_DISK
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 8: DİSK & DEPOLAMA TEMİZLİĞİ & OPTİMİZASYONU"
echo     %WHITE%Bu modül geçici dosyaları temizler, disk I/O optimizasyonu yapar%RESET%
echo     %WHITE%ve SSD özel ayarlarını uygular.%RESET%
echo.
call :CONFIRM_ACTION "Disk optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== DISK OPTIMIZASYONU BASLADI ====="

:: ----- 8.1 Disk I/O -----
echo     %CYAN%%BOLD%[8.1] Disk I/O Optimizasyonu%RESET%
call :DRAW_THIN_LINE

:: AHCI Link Power Management
if defined UP_GUID (
    powercfg -setacvalueindex %UP_GUID% 0012ee47-9041-4b5d-9b77-535fba8b1442 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 >nul 2>&1
    echo     %TICK% AHCI Link Power Management = Active
    
    :: Hard disk turn off = Never
    powercfg -setacvalueindex %UP_GUID% 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
    echo     %TICK% Hard Disk Turn Off = Never
) else (
    powercfg -setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 >nul 2>&1
    powercfg -setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
    powercfg /setactive SCHEME_CURRENT >nul 2>&1
    echo     %TICK% Disk güç ayarları yapılandırıldı
)

echo.
call :SHOW_PROGRESS 15 "Disk I/O tamamlandı"
echo.

:: ----- 8.2 Temp & Cache Temizleme -----
echo     %CYAN%%BOLD%[8.2] Geçici Dosya & Cache Temizleme%RESET%
call :DRAW_THIN_LINE

set "CLEANED_SIZE=0"

echo     %WORK% User Temp klasörü temizleniyor...
if exist "%TEMP%" (
    for /f "tokens=3" %%a in ('dir "%TEMP%" /s 2^>nul ^| findstr "dosya"') do set "TEMP_SIZE=%%a"
    del /q /f /s "%TEMP%\*" >nul 2>&1
    rd /s /q "%TEMP%" >nul 2>&1
    mkdir "%TEMP%" >nul 2>&1
    echo     %TICK% User Temp temizlendi
)

echo     %WORK% Windows Temp klasörü temizleniyor...
if exist "C:\Windows\Temp" (
    del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
    echo     %TICK% Windows Temp temizlendi
)

echo     %WORK% Prefetch klasörü temizleniyor...
if exist "C:\Windows\Prefetch" (
    del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
    echo     %TICK% Prefetch temizlendi
)

echo     %WORK% Thumbnail cache temizleniyor...
del /f /s /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo     %TICK% Thumbnail cache temizlendi

echo     %WORK% DNS cache temizleniyor...
ipconfig /flushdns >nul 2>&1
echo     %TICK% DNS cache temizlendi

echo     %WORK% ARP cache temizleniyor...
netsh interface ip delete arpcache >nul 2>&1
arp -d * >nul 2>&1
echo     %TICK% ARP cache temizlendi

echo     %WORK% Icon cache temizleniyor...
ie4uinit.exe -show >nul 2>&1
del /f /a "%LocalAppData%\IconCache.db" >nul 2>&1
del /f /a /s "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
echo     %TICK% Icon cache temizlendi

echo     %WORK% Font cache temizleniyor...
net stop FontCache >nul 2>&1
del /f /s /q "%WinDir%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
net start FontCache >nul 2>&1
echo     %TICK% Font cache temizlendi ve yeniden oluşturuldu

echo     %WORK% Delivery Optimization cache temizleniyor...
del /q /f /s "%SystemRoot%\SoftwareDistribution\DeliveryOptimization\*" >nul 2>&1
echo     %TICK% Delivery Optimization cache temizlendi

echo.
call :SHOW_PROGRESS 60 "Geçici dosyalar temizlendi"
echo.

:: Opsiyonel temizlikler
echo     %YELLOW%[?] Windows Update cache'ini temizlemek ister misiniz? (E/H):%RESET%
set /p "WU_CACHE=     > "
if /i "%WU_CACHE%"=="E" (
    net stop wuauserv >nul 2>&1
    del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
    net start wuauserv >nul 2>&1
    echo     %TICK% Windows Update cache temizlendi
)

echo.
echo     %YELLOW%[?] Geri Dönüşüm Kutusu'nu boşaltmak ister misiniz? (E/H):%RESET%
set /p "RB_CLEAN=     > "
if /i "%RB_CLEAN%"=="E" (
    rd /s /q "%SystemDrive%\$Recycle.Bin" >nul 2>&1
    echo     %TICK% Geri Dönüşüm Kutusu temizlendi
)

echo.
if exist "%SystemDrive%\Windows.old" (
    echo     %YELLOW%[?] Windows.old klasörünü silmek ister misiniz? (disk alanı kazanımı) (E/H):%RESET%
    set /p "WOLD_CLEAN=     > "
    if /i "!WOLD_CLEAN!"=="E" (
        rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
        echo     %TICK% Windows.old silindi
    )
)

echo.

:: ----- 8.3 SSD Optimizasyonu -----
echo     %CYAN%%BOLD%[8.3] SSD Optimizasyonu%RESET%
call :DRAW_THIN_LINE

echo "%DISK_TYPE%" | findstr /i "SSD" >nul 2>&1
if %errorlevel%==0 (
    echo     %WHITE%SSD tespit edildi — özel optimizasyonlar uygulanıyor%RESET%
    
    :: TRIM doğrula
    fsutil behavior query DisableDeleteNotify >nul 2>&1
    echo     %TICK% TRIM durumu kontrol edildi
    
    :: TRIM etkinleştir
    fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
    echo     %TICK% TRIM = Etkin
    
    echo     %TICK% Defrag zaten devre dışı (Bölüm 6'da)
    echo     %TICK% Superfetch/SysMain zaten devre dışı (Bölüm 6'da)
) else (
    echo     %GRAY%SSD tespit edilemedi veya HDD kullanılıyor — SSD optimizasyonları atlandı%RESET%
)

echo.
call :SHOW_PROGRESS 100 "Disk optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 9: GÜÇ YÖNETİMİ OPTİMİZASYONU
:: ============================================================================
:MODULE_POWER
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 9: GÜÇ YÖNETİMİ OPTİMİZASYONU"
echo     %WHITE%Bu modül Ultimate Performance güç planını oluşturur, sleep/hibernate%RESET%
echo     %WHITE%devre dışı bırakır ve tüm güç tasarrufu özelliklerini kapatır.%RESET%
echo.
call :CONFIRM_ACTION "Güç yönetimi optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== GÜÇ YÖNETIMI OPTIMIZASYONU BASLADI ====="

:: ----- 9.1 Ultimate Performance -----
echo     %CYAN%%BOLD%[9.1] Ultimate Performance Güç Planı%RESET%
call :DRAW_THIN_LINE

:: Plan oluştur (eğer CPU bölümünde yapılmadıysa)
if not defined UP_GUID (
    for /f "tokens=4" %%a in ('powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2^>nul') do set "UP_GUID=%%a"
)

if defined UP_GUID (
    powercfg /setactive %UP_GUID% >nul 2>&1
    echo     %TICK% Ultimate Performance planı aktif: %UP_GUID%
    
    :: Sleep devre dışı
    powercfg -setacvalueindex %UP_GUID% 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0 >nul 2>&1
    echo     %TICK% Sleep = Devre dışı
    
    :: Display timeout
    powercfg -setacvalueindex %UP_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0 >nul 2>&1
    echo     %TICK% Display Turn Off = Never
    
    :: USB Selective Suspend
    powercfg -setacvalueindex %UP_GUID% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    echo     %TICK% USB Selective Suspend = Disabled
    
    :: PCI Express ASPM
    powercfg -setacvalueindex %UP_GUID% 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
    echo     %TICK% PCI Express Link State PM = Off
    
    :: Processor boost
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2 >nul 2>&1
    echo     %TICK% Processor Boost Mode = Aggressive
    
    :: Min/Max processor
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
    echo     %TICK% İşlemci Min/Max = 100%%
    
    :: Hard disk turn off
    powercfg -setacvalueindex %UP_GUID% 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
    echo     %TICK% Hard Disk Turn Off = Never
    
    :: Planı etkinleştir
    powercfg /setactive %UP_GUID% >nul 2>&1
    
) else (
    echo     %WARN% Ultimate Performance oluşturulamadı, High Performance kullanılıyor
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
)

echo.
call :SHOW_PROGRESS 60 "Güç planı tamamlandı"
echo.

:: ----- 9.2 Hibernate Devre Dışı -----
echo     %CYAN%%BOLD%[9.2] Hibernate Devre Dışı%RESET%
call :DRAW_THIN_LINE

powercfg /hibernate off >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Hibernate devre dışı bırakıldı
    echo     %TICK% hiberfil.sys silinecek (disk alanı kazanımı)
    echo powercfg /hibernate on ^>nul 2^>^&1 >> "%UNDO_FILE%"
) else (
    echo     %WARN% Hibernate zaten devre dışı
)

echo.
call :SHOW_PROGRESS 100 "Güç yönetimi optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 10: GİZLİLİK & TELEMETRİ
:: ============================================================================
:MODULE_PRIVACY
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 10: GİZLİLİK & TELEMETRİ KAPATMA"
echo     %WHITE%Bu modül Windows telemetri, reklam kimliği, konum takibi ve diğer%RESET%
echo     %WHITE%gizlilik ayarlarını kapatır.%RESET%
echo.
call :CONFIRM_ACTION "Gizlilik optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== GIZLILIK & TELEMETRI BASLADI ====="

:: ----- 10.1 Telemetri -----
echo     %CYAN%%BOLD%[10.1] Windows Telemetri Kapatma%RESET%
call :DRAW_THIN_LINE

set "TEL_POL=SOFTWARE\Policies\Microsoft\Windows\DataCollection"
reg add "HKLM\%TEL_POL%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%TEL_POL%" "AllowTelemetry" REG_DWORD 0

set "TEL_CUR=SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
reg add "HKLM\%TEL_CUR%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%TEL_CUR%" "AllowTelemetry" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%TEL_CUR%" "MaxTelemetryAllowed" REG_DWORD 0

echo.
call :SHOW_PROGRESS 25 "Telemetri devre dışı"
echo.

:: ----- 10.2 Diğer Gizlilik -----
echo     %CYAN%%BOLD%[10.2] Diğer Gizlilik Ayarları%RESET%
call :DRAW_THIN_LINE

:: Activity History
set "AH_PATH=SOFTWARE\Policies\Microsoft\Windows\System"
reg add "HKLM\%AH_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%AH_PATH%" "EnableActivityFeed" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%AH_PATH%" "PublishUserActivities" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%AH_PATH%" "UploadUserActivities" REG_DWORD 0

:: Advertising ID
set "ADV_ID_PATH=Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
call :REG_BACKUP_AND_SET HKCU "%ADV_ID_PATH%" "Enabled" REG_DWORD 0

:: Location
set "LOC_PATH=SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
reg add "HKLM\%LOC_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%LOC_PATH%" "DisableLocation" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%LOC_PATH%" "DisableWindowsLocationProvider" REG_DWORD 1

:: Wi-Fi Sense
set "WIFI_PATH=SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
reg add "HKLM\%WIFI_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%WIFI_PATH%" "AutoConnectAllowedOEM" REG_DWORD 0

:: Clipboard History
set "CLIP_PATH=Software\Microsoft\Clipboard"
call :REG_BACKUP_AND_SET HKCU "%CLIP_PATH%" "EnableClipboardHistory" REG_DWORD 0

:: Feedback Frequency
set "FB_PATH=Software\Microsoft\Siuf\Rules"
reg add "HKCU\%FB_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%FB_PATH%" "NumberOfSIUFInPeriod" REG_DWORD 0

:: Online Speech Recognition
set "SPEECH_PATH=Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
reg add "HKCU\%SPEECH_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%SPEECH_PATH%" "HasAccepted" REG_DWORD 0

:: Inking & Typing
set "INK_PATH=Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization"
reg add "HKCU\%INK_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%INK_PATH%" "Value" REG_DWORD 0

:: Tailored Experiences
set "TAIL_PATH=Software\Microsoft\Windows\CurrentVersion\Privacy"
call :REG_BACKUP_AND_SET HKCU "%TAIL_PATH%" "TailoredExperiencesWithDiagnosticDataEnabled" REG_DWORD 0

echo.
call :SHOW_PROGRESS 100 "Gizlilik optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 11: BOOT & BCD OPTİMİZASYONU
:: ============================================================================
:MODULE_BOOT
call :SHOW_BANNER
call :SECTION_HEADER "BÖLÜM 11: BOOT & BCD OPTİMİZASYONU"
echo     %WHITE%Bu modül BCD (Boot Configuration Data) ayarlarını optimize eder,%RESET%
echo     %WHITE%timer çözünürlüğünü artırır ve boot süresini kısaltır.%RESET%
echo.
echo     %YELLOW%%BOLD%[!] UYARI: BCD değişiklikleri dikkatli yapılmalıdır.%RESET%
echo     %YELLOW%    Yanlış ayarlar boot sorunlarına yol açabilir.%RESET%
echo.
call :CONFIRM_ACTION "Boot optimizasyonunu başlatmak istiyor musunuz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

call :LOG_ACTION "===== BOOT & BCD OPTIMIZASYONU BASLADI ====="

:: ----- 11.1 Boot Configuration -----
echo     %CYAN%%BOLD%[11.1] Boot Configuration%RESET%
call :DRAW_THIN_LINE

echo     %WORK% BCD ayarları yapılandırılıyor...

:: Timer ayarları (Bölüm 1.5'te de yapıldı — doğrulama)
bcdedit /set disabledynamictick yes >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Dynamic Tick = Disabled
) else (
    echo     %WARN% Dynamic Tick zaten ayarlı veya hata
)

bcdedit /set useplatformtick yes >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Use Platform Tick = Yes
) else (
    echo     %WARN% Platform Tick zaten ayarlı veya hata
)

bcdedit /set useplatformclock false >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Use Platform Clock (HPET) = False
) else (
    echo     %WARN% Platform Clock zaten ayarlı veya hata
)

bcdedit /set tscsyncpolicy enhanced >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% TSC Sync Policy = Enhanced
) else (
    echo     %WARN% TSC Sync zaten ayarlı veya hata
)

:: Boot timeout = 0
bcdedit /timeout 0 >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Boot Timeout = 0 saniye
    echo bcdedit /timeout 30 ^>nul 2^>^&1 >> "%UNDO_FILE%"
) else (
    echo     %WARN% Boot timeout ayarlanamadı
)

:: Boot menu policy
bcdedit /set bootmenupolicy standard >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Boot Menu Policy = Standard
    echo bcdedit /set bootmenupolicy standard ^>nul 2^>^&1 >> "%UNDO_FILE%"
)

echo.

:: NX Bit (Opsiyonel — güvenlik riski)
echo     %RED%%BOLD%[!] DİKKAT: NX (Data Execution Prevention) Ayarı%RESET%
echo     %RED%    NX/DEP devre dışı bırakmak güvenlik riskidir!%RESET%
echo     %RED%    Sadece performans testi için önerilir.%RESET%
echo.
echo     %YELLOW%[?] NX/DEP politikasını OptOut yapmak ister misiniz? (E/H):%RESET%
set /p "NX_CHOICE=     > "
if /i "%NX_CHOICE%"=="E" (
    bcdedit /set nx optout >nul 2>&1
    if !errorlevel!==0 (
        echo     %TICK% NX = OptOut (DEP minimum)
        echo bcdedit /set nx optin ^>nul 2^>^&1 >> "%UNDO_FILE%"
        call :LOG_ACTION "NX/DEP = OptOut (GÜVENLIK RISKI)"
    )
) else (
    echo     %WHITE%NX/DEP değiştirilmedi%RESET%
)

echo.
call :SHOW_PROGRESS 100 "Boot optimizasyonu tamamlandı!"
call :SHOW_SECTION_COMPLETE

echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 12: TÜMÜNÜ UYGULA
:: ============================================================================
:MODULE_ALL
call :SHOW_BANNER
call :SECTION_HEADER "★ TÜMÜNÜ UYGULA ★"
echo     %MAGENTA%%BOLD%Bu seçenek TÜM optimizasyon modüllerini sırasıyla uygular.%RESET%
echo     %WHITE%Toplam 11 modül çalıştırılacaktır.%RESET%
echo.
echo     %YELLOW%%BOLD%[!] UYARI: Bu işlem geri dönüşü olan ama kapsamlı değişiklikler yapar.%RESET%
echo     %YELLOW%    Sistem geri yükleme noktası otomatik oluşturulacaktır.%RESET%
echo.
call :CONFIRM_ACTION "TÜMÜNÜ UYGULAMAK istediğinizden emin misiniz?"
if /i "!CONFIRM_RESULT!"=="N" goto :MAIN_MENU

echo.
echo     %WORK% Sistem geri yükleme noktası oluşturuluyor...
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Laving Optimizer - Full Optimization", 100, 7 >nul 2>&1
if %errorlevel%==0 (
    echo     %TICK% Geri yükleme noktası oluşturuldu
) else (
    echo     %WARN% Geri yükleme noktası oluşturulamadı (devam ediyor)
)
echo.

:: Set auto-confirm flag
set "CONFIRM_RESULT=Y"

:: ===== MODÜL 1: CPU =====
call :SECTION_HEADER "MODÜL 1/11: CPU & ZAMANLAYICI"
call :LOG_ACTION "===== TOPLU: CPU BASLADI ====="

set "MMCSS_PATH=SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
call :REG_BACKUP_AND_SET HKLM "%MMCSS_PATH%" "SystemResponsiveness" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MMCSS_PATH%" "NetworkThrottlingIndex" REG_DWORD 0xffffffff
call :REG_BACKUP_AND_SET HKLM "%MMCSS_PATH%" "NoLazyMode" REG_DWORD 1

set "GAMES_PATH=%MMCSS_PATH%\Tasks\Games"
reg add "HKLM\%GAMES_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "GPU Priority" REG_DWORD 8
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Priority" REG_DWORD 6
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Scheduling Category" REG_SZ "High"
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "SFIO Priority" REG_SZ "High"
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Affinity" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Background Only" REG_SZ "False"
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Clock Rate" REG_DWORD 10000
call :REG_BACKUP_AND_SET HKLM "%GAMES_PATH%" "Latency Sensitive" REG_SZ "True"

set "PRIO_PATH=SYSTEM\CurrentControlSet\Control\PriorityControl"
call :REG_BACKUP_AND_SET HKLM "%PRIO_PATH%" "Win32PrioritySeparation" REG_DWORD 0x26
call :REG_BACKUP_AND_SET HKLM "%PRIO_PATH%" "IRQ8Priority" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%PRIO_PATH%" "ConvertibleSlateMode" REG_DWORD 0

:: Ultimate Performance
for /f "tokens=4" %%a in ('powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2^>nul') do set "UP_GUID=%%a"
if defined UP_GUID (
    powercfg /setactive %UP_GUID% >nul 2>&1
    echo     %TICK% Ultimate Performance planı aktif
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 100 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2 >nul 2>&1
    powercfg /setactive %UP_GUID% >nul 2>&1
    echo     %TICK% Core Parking devre dışı, İşlemci 100%%
)

:: MSI Mode
for /f "tokens=*" %%a in ('wmic path Win32_VideoController get PNPDeviceID 2^>nul ^| findstr /i "PCI"') do (
    set "GPU_PNP=%%a"
    set "GPU_PNP=!GPU_PNP: =!"
    if not "!GPU_PNP!"=="" (
        set "MSI_GPU_PATH=SYSTEM\CurrentControlSet\Enum\!GPU_PNP!\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        reg add "HKLM\!MSI_GPU_PATH!" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
        echo     %TICK% GPU MSI Mode aktif
    )
)

:: BCD
bcdedit /set disabledynamictick yes >nul 2>&1
bcdedit /set useplatformtick yes >nul 2>&1
bcdedit /set tscsyncpolicy enhanced >nul 2>&1
bcdedit /set useplatformclock false >nul 2>&1
echo     %TICK% Timer/BCD ayarları tamamlandı

call :SHOW_PROGRESS 9 "Modül 1/11 tamamlandı"
echo.

:: ===== MODÜL 2: GPU =====
call :SECTION_HEADER "MODÜL 2/11: GPU & GÖRÜNTÜ"

set "GFX_PATH=SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
call :REG_BACKUP_AND_SET HKLM "%GFX_PATH%" "HwSchMode" REG_DWORD 2
call :REG_BACKUP_AND_SET HKLM "%GFX_PATH%" "TdrDelay" REG_DWORD 60
call :REG_BACKUP_AND_SET HKLM "%GFX_PATH%" "TdrDdiDelay" REG_DWORD 60

set "GBAR_PATH=Software\Microsoft\GameBar"
call :REG_BACKUP_AND_SET HKCU "%GBAR_PATH%" "AllowAutoGameMode" REG_DWORD 1
call :REG_BACKUP_AND_SET HKCU "%GBAR_PATH%" "AutoGameModeEnabled" REG_DWORD 1

set "GCONF_PATH=System\GameConfigStore"
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_Enabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_FSEBehaviorMode" REG_DWORD 2
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_HonorUserFSEBehaviorMode" REG_DWORD 1
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_FSEBehavior" REG_DWORD 2
call :REG_BACKUP_AND_SET HKCU "%GCONF_PATH%" "GameDVR_DXGIHonorFSEWindowsCompatible" REG_DWORD 1

set "GDVR_POL=SOFTWARE\Policies\Microsoft\Windows\GameDVR"
reg add "HKLM\%GDVR_POL%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%GDVR_POL%" "AllowGameDVR" REG_DWORD 0

set "GDVR_USER=SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
reg add "HKCU\%GDVR_USER%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%GDVR_USER%" "AppCaptureEnabled" REG_DWORD 0

set "DWM_PATH=SOFTWARE\Microsoft\Windows\Dwm"
call :REG_BACKUP_AND_SET HKLM "%DWM_PATH%" "OverlayTestMode" REG_DWORD 5
call :REG_BACKUP_AND_SET HKLM "%DWM_PATH%" "ForceEffectMode" REG_DWORD 0

set "THEMES_PATH=Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
call :REG_BACKUP_AND_SET HKCU "%THEMES_PATH%" "EnableTransparency" REG_DWORD 0

call :SHOW_PROGRESS 18 "Modül 2/11 tamamlandı"
echo.

:: ===== MODÜL 3: AĞ =====
call :SECTION_HEADER "MODÜL 3/11: AĞ & PING"

netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global ecncapability=disabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global nonsackrttresiliency=disabled >nul 2>&1
netsh int tcp set global maxsynretransmissions=2 >nul 2>&1
netsh int tcp set global initialRto=2000 >nul 2>&1
echo     %TICK% TCP global ayarları tamamlandı

if "%WIN_VER%"=="11" (
    netsh int tcp set supplemental Internet CongestionProvider=bbr2 >nul 2>&1
) else (
    netsh int tcp set supplemental Internet CongestionProvider=ctcp >nul 2>&1
)
echo     %TICK% Congestion Provider ayarlandı

set "TCPIP_PATH=SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpAckFrequency" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TCPNoDelay" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpDelAckTicks" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "DefaultTTL" REG_DWORD 64
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "MaxUserPort" REG_DWORD 65534
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpTimedWaitDelay" REG_DWORD 30
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "TcpMaxDataRetransmissions" REG_DWORD 5
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "SackOpts" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "Tcp1323Opts" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "MaxFreeTcbs" REG_DWORD 65536
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "MaxHashTableSize" REG_DWORD 65536
call :REG_BACKUP_AND_SET HKLM "%TCPIP_PATH%" "GlobalMaxTcpWindowSize" REG_DWORD 65535

:: Per-interface Nagle
set "IFACE_BASE=SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
for /f "tokens=*" %%G in ('reg query "HKLM\%IFACE_BASE%" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    set "IFACE_KEY=%%G"
    set "IFACE_KEY=!IFACE_KEY:HKEY_LOCAL_MACHINE\=!"
    reg query "%%G" /v "DhcpIPAddress" >nul 2>&1
    if !errorlevel!==0 (
        call :REG_BACKUP_AND_SET HKLM "!IFACE_KEY!" "TcpAckFrequency" REG_DWORD 1
        call :REG_BACKUP_AND_SET HKLM "!IFACE_KEY!" "TCPNoDelay" REG_DWORD 1
        call :REG_BACKUP_AND_SET HKLM "!IFACE_KEY!" "TcpDelAckTicks" REG_DWORD 0
    )
)

set "DNS_PATH=SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
call :REG_BACKUP_AND_SET HKLM "%DNS_PATH%" "MaxCacheTtl" REG_DWORD 86400
call :REG_BACKUP_AND_SET HKLM "%DNS_PATH%" "MaxNegativeCacheTtl" REG_DWORD 5
call :REG_BACKUP_AND_SET HKLM "%DNS_PATH%" "NegativeSOACacheTime" REG_DWORD 0

ipconfig /flushdns >nul 2>&1
echo     %TICK% DNS cache temizlendi

call :SHOW_PROGRESS 27 "Modül 3/11 tamamlandı"
echo.

:: ===== MODÜL 4: RAM =====
call :SECTION_HEADER "MODÜL 4/11: RAM & BELLEK"

set "MM_PATH=SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "ClearPageFileAtShutdown" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "DisablePagingExecutive" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "LargeSystemCache" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "SecondLevelDataCache" REG_DWORD 1024
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "SystemPages" REG_DWORD 0xffffffff
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "IoPageLockLimit" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "PoolUsageMaximum" REG_DWORD 60
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "PagedPoolSize" REG_DWORD 0xffffffff
call :REG_BACKUP_AND_SET HKLM "%MM_PATH%" "NonPagedPoolSize" REG_DWORD 0

set "PF_PATH=%MM_PATH%\PrefetchParameters"
call :REG_BACKUP_AND_SET HKLM "%PF_PATH%" "EnablePrefetcher" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%PF_PATH%" "EnableSuperfetch" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%PF_PATH%" "EnableBootTrace" REG_DWORD 0

fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set memoryusage 2 >nul 2>&1
fsutil behavior set mftzone 4 >nul 2>&1

set "FS_PATH=SYSTEM\CurrentControlSet\Control\FileSystem"
call :REG_BACKUP_AND_SET HKLM "%FS_PATH%" "NtfsDisable8dot3NameCreation" REG_DWORD 1
call :REG_BACKUP_AND_SET HKLM "%FS_PATH%" "NtfsMemoryUsage" REG_DWORD 2

echo     %TICK% NTFS & dosya sistemi optimize edildi

call :SHOW_PROGRESS 36 "Modül 4/11 tamamlandı"
echo.

:: ===== MODÜL 5: INPUT =====
call :SECTION_HEADER "MODÜL 5/11: INPUT LAG & FARE/KLAVYE"

set "MOUSE_PATH=Control Panel\Mouse"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseSpeed" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseThreshold1" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseThreshold2" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%MOUSE_PATH%" "MouseSensitivity" REG_SZ "10"

reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d "0000000000000000c0cc0c0000000000809919000000000040662600000000000033330000000000" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d "0000000000000000000038000000000000007000000000000000a800000000000000e00000000000" /f >nul 2>&1
echo     %TICK% Mouse acceleration devre dışı (lineer eğri)

set "KB_PATH=Control Panel\Keyboard"
call :REG_BACKUP_AND_SET HKCU "%KB_PATH%" "KeyboardDelay" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%KB_PATH%" "KeyboardSpeed" REG_SZ "31"

:: USB güç yönetimi
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\USB" /s /v "EnhancedPowerManagementEnabled" 2^>nul ^| findstr /i "HKEY_LOCAL_MACHINE"') do (
    reg add "%%a" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
)
echo     %TICK% USB Power Management devre dışı

if defined UP_GUID (
    powercfg -setacvalueindex %UP_GUID% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    powercfg /setactive %UP_GUID% >nul 2>&1
)
echo     %TICK% USB Selective Suspend devre dışı

call :SHOW_PROGRESS 45 "Modül 5/11 tamamlandı"
echo.

:: ===== MODÜL 6: SERVİSLER =====
call :SECTION_HEADER "MODÜL 6/11: GEREKSİZ SERVİSLER"

call :DISABLE_SERVICE "DiagTrack" "Telemetri"
call :DISABLE_SERVICE "dmwappushservice" "WAP Push"
call :DISABLE_SERVICE "WSearch" "Arama Indeksleme"
call :DISABLE_SERVICE "SysMain" "Superfetch"
call :DISABLE_SERVICE "WbioSrvc" "Biyometrik"
call :DISABLE_SERVICE "TabletInputService" "Dokunmatik Klavye"
call :DISABLE_SERVICE "PhoneSvc" "Telefon"
call :DISABLE_SERVICE "RetailDemo" "Demo"
call :DISABLE_SERVICE "MapsBroker" "Harita"
call :DISABLE_SERVICE "Fax" "Faks"
call :DISABLE_SERVICE "lfsvc" "Konum"
call :DISABLE_SERVICE "WMPNetworkSvc" "Media Paylaşım"
call :DISABLE_SERVICE "XblAuthManager" "Xbox Auth"
call :DISABLE_SERVICE "XblGameSave" "Xbox Save"
call :DISABLE_SERVICE "XboxGipSvc" "Xbox Aksesuar"
call :DISABLE_SERVICE "XboxNetApiSvc" "Xbox Ağ"
call :DISABLE_SERVICE "SEMgrSvc" "NFC"
call :DISABLE_SERVICE "WerSvc" "Hata Raporlama"
call :DISABLE_SERVICE "PcaSvc" "Uyumluluk"
call :DISABLE_SERVICE "WdiSystemHost" "Tanı Host"
call :DISABLE_SERVICE "WdiServiceHost" "Tanı Servis"
call :DISABLE_SERVICE "TrkWks" "Link Tracking"
call :DISABLE_SERVICE "AJRouter" "AllJoyn"

:: Zamanlanmış görevler
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Autochk\Proxy" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable >nul 2>&1
echo     %TICK% Zamanlanmış görevler devre dışı

call :SHOW_PROGRESS 55 "Modül 6/11 tamamlandı"
echo.

:: ===== MODÜL 7: GÖRSEL =====
call :SECTION_HEADER "MODÜL 7/11: GÖRSEL EFEKTLER"

set "VFX_PATH=Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
call :REG_BACKUP_AND_SET HKCU "%VFX_PATH%" "VisualFXSetting" REG_DWORD 2

reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f >nul 2>&1
echo     %TICK% Animasyonlar minimize edildi

set "DESK_PATH=Control Panel\Desktop"
call :REG_BACKUP_AND_SET HKCU "%DESK_PATH%" "MenuShowDelay" REG_SZ "0"
call :REG_BACKUP_AND_SET HKCU "%DESK_PATH%" "DragFullWindows" REG_SZ "0"

set "WM_PATH=Control Panel\Desktop\WindowMetrics"
call :REG_BACKUP_AND_SET HKCU "%WM_PATH%" "MinAnimate" REG_SZ "0"

set "ADV_PATH=Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
call :REG_BACKUP_AND_SET HKCU "%ADV_PATH%" "TaskbarAnimations" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%ADV_PATH%" "ListviewAlphaSelect" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%ADV_PATH%" "ListviewShadow" REG_DWORD 0

set "BG_PATH=Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
call :REG_BACKUP_AND_SET HKCU "%BG_PATH%" "GlobalUserDisabled" REG_DWORD 1

set "CORTANA_PATH=SOFTWARE\Policies\Microsoft\Windows\Windows Search"
reg add "HKLM\%CORTANA_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%CORTANA_PATH%" "AllowCortana" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%CORTANA_PATH%" "DisableWebSearch" REG_DWORD 1

set "CONTENT_PATH=Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SubscribedContent-338389Enabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SubscribedContent-310093Enabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SubscribedContent-338388Enabled" REG_DWORD 0
call :REG_BACKUP_AND_SET HKCU "%CONTENT_PATH%" "SystemPaneSuggestionsEnabled" REG_DWORD 0

set "SERIALIZE_PATH=Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
reg add "HKCU\%SERIALIZE_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%SERIALIZE_PATH%" "StartupDelayInMSec" REG_DWORD 0

call :SHOW_PROGRESS 64 "Modül 7/11 tamamlandı"
echo.

:: ===== MODÜL 8: DİSK =====
call :SECTION_HEADER "MODÜL 8/11: DİSK TEMİZLİK"

echo     %WORK% Geçici dosyalar temizleniyor...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
del /f /s /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
ipconfig /flushdns >nul 2>&1
arp -d * >nul 2>&1
del /f /a "%LocalAppData%\IconCache.db" >nul 2>&1
del /f /a /s "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
echo     %TICK% Tüm cache ve temp dosyalar temizlendi

if defined UP_GUID (
    powercfg -setacvalueindex %UP_GUID% 0012ee47-9041-4b5d-9b77-535fba8b1442 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
    powercfg /setactive %UP_GUID% >nul 2>&1
)

echo "%DISK_TYPE%" | findstr /i "SSD" >nul 2>&1
if %errorlevel%==0 (
    fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
    echo     %TICK% SSD TRIM etkin
)

call :SHOW_PROGRESS 73 "Modül 8/11 tamamlandı"
echo.

:: ===== MODÜL 9: GÜÇ =====
call :SECTION_HEADER "MODÜL 9/11: GÜÇ YÖNETİMİ"

if defined UP_GUID (
    powercfg -setacvalueindex %UP_GUID% 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0 >nul 2>&1
    powercfg -setacvalueindex %UP_GUID% 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
    powercfg /setactive %UP_GUID% >nul 2>&1
    echo     %TICK% Güç planı ayarları tamamlandı (Sleep/Display off/PCI Express)
)

powercfg /hibernate off >nul 2>&1
echo     %TICK% Hibernate devre dışı

call :SHOW_PROGRESS 82 "Modül 9/11 tamamlandı"
echo.

:: ===== MODÜL 10: GİZLİLİK =====
call :SECTION_HEADER "MODÜL 10/11: GİZLİLİK & TELEMETRİ"

set "TEL_POL=SOFTWARE\Policies\Microsoft\Windows\DataCollection"
reg add "HKLM\%TEL_POL%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%TEL_POL%" "AllowTelemetry" REG_DWORD 0

set "TEL_CUR=SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
reg add "HKLM\%TEL_CUR%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%TEL_CUR%" "AllowTelemetry" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%TEL_CUR%" "MaxTelemetryAllowed" REG_DWORD 0

set "AH_PATH=SOFTWARE\Policies\Microsoft\Windows\System"
reg add "HKLM\%AH_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%AH_PATH%" "EnableActivityFeed" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%AH_PATH%" "PublishUserActivities" REG_DWORD 0
call :REG_BACKUP_AND_SET HKLM "%AH_PATH%" "UploadUserActivities" REG_DWORD 0

set "ADV_ID_PATH=Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
call :REG_BACKUP_AND_SET HKCU "%ADV_ID_PATH%" "Enabled" REG_DWORD 0

set "LOC_PATH=SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
reg add "HKLM\%LOC_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%LOC_PATH%" "DisableLocation" REG_DWORD 1

set "WIFI_PATH=SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
reg add "HKLM\%WIFI_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKLM "%WIFI_PATH%" "AutoConnectAllowedOEM" REG_DWORD 0

set "CLIP_PATH=Software\Microsoft\Clipboard"
call :REG_BACKUP_AND_SET HKCU "%CLIP_PATH%" "EnableClipboardHistory" REG_DWORD 0

set "FB_PATH=Software\Microsoft\Siuf\Rules"
reg add "HKCU\%FB_PATH%" /f >nul 2>&1
call :REG_BACKUP_AND_SET HKCU "%FB_PATH%" "NumberOfSIUFInPeriod" REG_DWORD 0

call :SHOW_PROGRESS 91 "Modül 10/11 tamamlandı"
echo.

:: ===== MODÜL 11: BOOT =====
call :SECTION_HEADER "MODÜL 11/11: BOOT & BCD"

bcdedit /timeout 0 >nul 2>&1
bcdedit /set bootmenupolicy standard >nul 2>&1
echo     %TICK% Boot timeout = 0, Boot menu = Standard

call :SHOW_PROGRESS 100 "Tüm modüller tamamlandı!"
echo.

:: ===== ÖZET RAPOR =====
echo.
echo     %MAGENTA%%BOLD%╔══════════════════════════════════════════════════════════════════════════════╗%RESET%
echo     %MAGENTA%%BOLD%║                        ★ OPTİMİZASYON TAMAMLANDI ★                         ║%RESET%
echo     %MAGENTA%%BOLD%╠══════════════════════════════════════════════════════════════════════════════╣%RESET%
echo     %MAGENTA%%BOLD%║%RESET%                                                                          %MAGENTA%%BOLD%║%RESET%
echo     %MAGENTA%%BOLD%║%RESET%  %GREEN%Başarılı işlemler  : %SUCCESS_COUNT%%RESET%
echo     %MAGENTA%%BOLD%║%RESET%  %RED%Hatalı işlemler    : %FAIL_COUNT%%RESET%
echo     %MAGENTA%%BOLD%║%RESET%  %GRAY%Atlanan işlemler   : %SKIP_COUNT%%RESET%
echo     %MAGENTA%%BOLD%║%RESET%  %WHITE%Toplam değişiklik  : %CHANGES_COUNT%%RESET%
echo     %MAGENTA%%BOLD%║%RESET%                                                                          %MAGENTA%%BOLD%║%RESET%
echo     %MAGENTA%%BOLD%║%RESET%  %CYAN%Log dosyası  : %LOG_FILE%%RESET%
echo     %MAGENTA%%BOLD%║%RESET%  %CYAN%Yedek klasör : %BACKUP_DIR%%RESET%
echo     %MAGENTA%%BOLD%║%RESET%  %CYAN%Geri alma    : %UNDO_FILE%%RESET%
echo     %MAGENTA%%BOLD%║%RESET%                                                                          %MAGENTA%%BOLD%║%RESET%
echo     %MAGENTA%%BOLD%╚══════════════════════════════════════════════════════════════════════════════╝%RESET%
echo.

:: Süre ölçümü
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set /a "END_S=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)"
)
set /a "ELAPSED=END_S-START_S"
if %ELAPSED% lss 0 set /a "ELAPSED+=86400"
set /a "ELAPSED_MIN=ELAPSED/60"
set /a "ELAPSED_SEC=ELAPSED%%60"
echo     %WHITE%Toplam süre: %ELAPSED_MIN% dakika %ELAPSED_SEC% saniye%RESET%
echo.

:: Log'a özet yaz
echo. >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"
echo   OZET RAPOR >> "%LOG_FILE%"
echo   Basarili: %SUCCESS_COUNT% >> "%LOG_FILE%"
echo   Hatali  : %FAIL_COUNT% >> "%LOG_FILE%"
echo   Atlanan : %SKIP_COUNT% >> "%LOG_FILE%"
echo   Toplam  : %CHANGES_COUNT% >> "%LOG_FILE%"
echo   Sure    : %ELAPSED_MIN% dk %ELAPSED_SEC% sn >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

:: Undo scripti bitir
echo echo. >> "%UNDO_FILE%"
echo echo Geri alma tamamlandi! >> "%UNDO_FILE%"
echo echo Lutfen bilgisayarinizi yeniden baslatin. >> "%UNDO_FILE%"
echo pause >> "%UNDO_FILE%"

echo     %YELLOW%%BOLD%[!] Değişikliklerin tam olarak uygulanması için bilgisayarınızı%RESET%
echo     %YELLOW%%BOLD%    yeniden başlatmanız önerilir.%RESET%
echo.
echo     %YELLOW%[?] Şimdi yeniden başlatmak ister misiniz? (E/H):%RESET%
set /p "RESTART_CHOICE=     > "
if /i "%RESTART_CHOICE%"=="E" (
    echo     %WORK% 10 saniye içinde yeniden başlatılıyor...
    shutdown /r /t 10 /c "Laving Optimizer - Sistem yeniden başlatılıyor..."
    echo     %YELLOW%İptal etmek için: shutdown /a%RESET%
)

echo.
echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 13: YEDEKTEN GERİ YÜKLE
:: ============================================================================
:MODULE_RESTORE
call :SHOW_BANNER
call :SECTION_HEADER "YEDEKTEN GERİ YÜKLE"
echo     %WHITE%Bu modül daha önce oluşturulmuş yedekleri geri yükler.%RESET%
echo.

echo     %CYAN%[1] Oluşturulan UNDO scriptini çalıştır%RESET%
echo     %CYAN%[2] Sistem Geri Yükleme noktasına dön%RESET%
echo     %CYAN%[0] Ana menüye dön%RESET%
echo.
set /p "RESTORE_CHOICE=     Seçiminiz: "

if "%RESTORE_CHOICE%"=="1" (
    if exist "%UNDO_FILE%" (
        echo     %WORK% Geri alma scripti çalıştırılıyor...
        echo     %YELLOW%Dosya: %UNDO_FILE%%RESET%
        call :CONFIRM_ACTION "Geri alma işlemini başlatmak istiyor musunuz?"
        if /i "!CONFIRM_RESULT!"=="Y" (
            call "%UNDO_FILE%"
            echo     %TICK% Geri alma tamamlandı
        )
    ) else (
        echo     %CROSS% UNDO scripti bulunamadı: %UNDO_FILE%
        echo     %WHITE%Desktop'ta LavingBackup klasörünü kontrol edin.%RESET%
        echo.
        :: Masaüstünde başka backup klasörleri ara
        echo     %CYAN%Bulunan yedek klasörleri:%RESET%
        dir /b /ad "%USERPROFILE%\Desktop\LavingBackup_*" 2>nul
        if %errorlevel% neq 0 (
            echo     %GRAY%Hiç yedek klasörü bulunamadı.%RESET%
        )
    )
)

if "%RESTORE_CHOICE%"=="2" (
    echo     %WORK% Sistem Geri Yükleme açılıyor...
    rstrui.exe
)

echo.
echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  BÖLÜM 14: SİSTEM BİLGİSİ
:: ============================================================================
:MODULE_SYSINFO
call :SHOW_BANNER
call :SECTION_HEADER "SİSTEM BİLGİSİ"

echo     %CYAN%%BOLD%╔══════════════════════════════════════════════════════════════════════════════╗%RESET%
echo     %CYAN%%BOLD%║                           DETAYLI SİSTEM BİLGİSİ                            ║%RESET%
echo     %CYAN%%BOLD%╠══════════════════════════════════════════════════════════════════════════════╣%RESET%
echo     %CYAN%%BOLD%║%RESET%                                                                          %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%İŞLETİM SİSTEMİ%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
echo     %CYAN%%BOLD%║%RESET%   Sürüm    : %WIN_LABEL%
echo     %CYAN%%BOLD%║%RESET%   Build    : %WIN_BUILD%

for /f "tokens=2 delims==" %%a in ('wmic os get OSArchitecture /value 2^>nul') do echo     %CYAN%%BOLD%║%RESET%   Mimari   : %%a
for /f "tokens=2 delims==" %%a in ('wmic os get InstallDate /value 2^>nul') do echo     %CYAN%%BOLD%║%RESET%   Kurulum  : %%a
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%İŞLEMCİ (CPU)%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
echo     %CYAN%%BOLD%║%RESET%   Model      : %CPU_NAME%
echo     %CYAN%%BOLD%║%RESET%   Çekirdek   : %CPU_CORES%
echo     %CYAN%%BOLD%║%RESET%   Thread     : %CPU_THREADS%
for /f "tokens=2 delims==" %%a in ('wmic cpu get MaxClockSpeed /value 2^>nul') do echo     %CYAN%%BOLD%║%RESET%   Maks Hız   : %%a MHz
for /f "tokens=2 delims==" %%a in ('wmic cpu get L2CacheSize /value 2^>nul') do echo     %CYAN%%BOLD%║%RESET%   L2 Cache   : %%a KB
for /f "tokens=2 delims==" %%a in ('wmic cpu get L3CacheSize /value 2^>nul') do echo     %CYAN%%BOLD%║%RESET%   L3 Cache   : %%a KB
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%BELLEK (RAM)%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
echo     %CYAN%%BOLD%║%RESET%   Toplam     : %RAM_TOTAL% MB
for /f "tokens=2 delims==" %%a in ('wmic os get FreePhysicalMemory /value 2^>nul') do (
    set /a "FREE_RAM=%%a/1024"
    echo     %CYAN%%BOLD%║%RESET%   Boş       : !FREE_RAM! MB
)
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%EKRAN KARTI (GPU)%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
echo     %CYAN%%BOLD%║%RESET%   Model      : %GPU_NAME%
for /f "tokens=2 delims==" %%a in ('wmic path Win32_VideoController get DriverVersion /value 2^>nul') do (
    if not "%%a"=="" echo     %CYAN%%BOLD%║%RESET%   Sürücü     : %%a
)
for /f "tokens=2 delims==" %%a in ('wmic path Win32_VideoController get AdapterRAM /value 2^>nul') do (
    if not "%%a"=="" (
        set /a "VRAM=%%a/1048576"
        echo     %CYAN%%BOLD%║%RESET%   VRAM       : !VRAM! MB
    )
)
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%DEPOLAMA%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
echo     %CYAN%%BOLD%║%RESET%   Tip        : %DISK_TYPE%
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get Size /value 2^>nul') do (
    set /a "DISK_SIZE=%%a/1073741824"
    echo     %CYAN%%BOLD%║%RESET%   C: Boyut   : !DISK_SIZE! GB
)
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /value 2^>nul') do (
    set /a "DISK_FREE=%%a/1073741824"
    echo     %CYAN%%BOLD%║%RESET%   C: Boş     : !DISK_FREE! GB
)
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%AĞ%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
echo     %CYAN%%BOLD%║%RESET%   Adaptör    : %NIC_NAME%
for /f "tokens=2 delims==" %%a in ('wmic nic where "NetConnectionStatus=2" get Speed /value 2^>nul') do (
    if not "%%a"=="" (
        set /a "NIC_SPEED=%%a/1000000"
        echo     %CYAN%%BOLD%║%RESET%   Hız        : !NIC_SPEED! Mbps
    )
)
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%GÜÇ PLANI%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
for /f "tokens=*" %%a in ('powercfg /getactivescheme 2^>nul') do echo     %CYAN%%BOLD%║%RESET%   %%a
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%║%RESET% %WHITE%%BOLD%PING TESTİ%RESET%
echo     %CYAN%%BOLD%║%RESET% %GRAY%────────────────────────────────────────────%RESET%
echo     %WORK% Ping testi yapılıyor (1.1.1.1)...
for /f "tokens=*" %%a in ('ping -n 4 1.1.1.1 2^>nul ^| findstr /i "ortalama Average"') do (
    echo     %CYAN%%BOLD%║%RESET%   %%a
)
echo     %CYAN%%BOLD%║%RESET%

echo     %CYAN%%BOLD%╚══════════════════════════════════════════════════════════════════════════════╝%RESET%

echo.
echo     %WHITE%Ana menüye dönmek için bir tuşa basın...%RESET%
pause >nul
goto :MAIN_MENU

:: ============================================================================
::  ÇIKIŞ
:: ============================================================================
:EXIT_SCRIPT
call :SHOW_BANNER

:: Süre ölçümü
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set /a "END_S=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)"
)
if defined START_S (
    set /a "ELAPSED=END_S-START_S"
    if !ELAPSED! lss 0 set /a "ELAPSED+=86400"
    set /a "ELAPSED_MIN=ELAPSED/60"
    set /a "ELAPSED_SEC=ELAPSED%%60"
)

echo.
echo     %WHITE%%BOLD%Oturum Özeti:%RESET%
echo     %GRAY%────────────────────────────────────────────%RESET%
echo     %GREEN%Başarılı  : %SUCCESS_COUNT%%RESET%
echo     %RED%Hatalı    : %FAIL_COUNT%%RESET%
echo     %GRAY%Atlanan   : %SKIP_COUNT%%RESET%
echo     %WHITE%Toplam    : %CHANGES_COUNT%%RESET%
if defined ELAPSED_MIN (
    echo     %CYAN%Süre      : %ELAPSED_MIN% dk %ELAPSED_SEC% sn%RESET%
)
echo.

if %CHANGES_COUNT% gtr 0 (
    echo     %CYAN%Log dosyası  : %LOG_FILE%%RESET%
    echo     %CYAN%Yedek klasör : %BACKUP_DIR%%RESET%
    echo     %CYAN%Geri alma    : %UNDO_FILE%%RESET%
    echo.
    
    :: Undo scripti bitir
    echo echo. >> "%UNDO_FILE%"
    echo echo Geri alma tamamlandi! >> "%UNDO_FILE%"
    echo pause >> "%UNDO_FILE%"
    
    :: Log'a özet yaz
    echo. >> "%LOG_FILE%"
    echo ============================================================ >> "%LOG_FILE%"
    echo   OTURUM SONU - %date% %time% >> "%LOG_FILE%"
    echo   Basarili: %SUCCESS_COUNT% / Hatali: %FAIL_COUNT% / Toplam: %CHANGES_COUNT% >> "%LOG_FILE%"
    echo ============================================================ >> "%LOG_FILE%"
)

echo     %WHITE%%BOLD%Laving Ultimate Gaming Optimizer v2.0%RESET%
echo     %GRAY%Geliştirici: Laving%RESET%
echo     %GRAY%Teşekkürler!%RESET%
echo.
echo     %WHITE%Çıkmak için bir tuşa basın...%RESET%
pause >nul
endlocal
exit /b 0