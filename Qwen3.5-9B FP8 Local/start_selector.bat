@echo off
:: ============================================================
:: PLACEMENT: copy this file ONE LEVEL UP from this folder
:: Place at:  D:\Mojtaba\LOCAL MODELS\start.bat
::            (parent folder that contains both model folders)
:: ============================================================
echo ============================================================
echo   Local LLM Server ??? Model Selector
echo ============================================================
echo.
echo   [1]  Qwen3.5-9B FP8   port 8000  ~50 tok/s  8K context  (higher quality)
echo   [2]  Qwen3.5-4B BF16  port 8001  ~70 tok/s  16K context (faster, larger ctx)
echo.
set /p CHOICE="   Select model (1 or 2): "

if "%CHOICE%"=="1" (
    echo.
    echo   Starting Qwen3.5-9B FP8 on port 8000...
    call "Qwen3.5-9B FP8 Local\start.bat"
) else if "%CHOICE%"=="2" (
    echo.
    echo   Starting Qwen3.5-4B BF16 on port 8001...
    call "Qwen3.5-4B BF16 Local\start.bat"
) else (
    echo.
    echo   Invalid choice. Please enter 1 or 2.
    pause
)
