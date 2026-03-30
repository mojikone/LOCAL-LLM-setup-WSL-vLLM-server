@echo off
echo ============================================================
echo   Local LLM Server — Model Selector
echo ============================================================
echo.
echo   [1]  Qwen3.5-9B FP8   port 8000  ~50 tok/s  8K context  (higher quality)
echo   [2]  Qwen3.5-4B FP8   port 8001  ~80 tok/s  16K context (faster, larger ctx)
echo.
set /p CHOICE="   Select model (1 or 2): "

if "%CHOICE%"=="1" (
    echo.
    echo   Starting Qwen3.5-9B FP8 on port 8000...
    call "Qwen3.5-9B FP8 Local\start.bat"
) else if "%CHOICE%"=="2" (
    echo.
    echo   Starting Qwen3.5-4B FP8 on port 8001...
    call "Qwen3.5-4B FP8 Local\start.bat"
) else (
    echo.
    echo   Invalid choice. Please enter 1 or 2.
    pause
)
