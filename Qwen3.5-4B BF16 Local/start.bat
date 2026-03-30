@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo   Qwen3.5-4B BF16 - vLLM Server (WSL2)
echo   Edit config.env to change model parameters
echo ============================================================
echo.

:: Read config.env - strip comment lines then parse key=value
for /f "tokens=*" %%L in ('type "%~dp0config.env" ^| findstr /v "^#"') do (
    for /f "tokens=1,2 delims==" %%A in ("%%L") do (
        if not "%%A"=="" if not "%%B"=="" set "%%A=%%B"
    )
)

:: Build enforce-eager flag
set EAGER_FLAG=
if /i "!ENFORCE_EAGER!"=="true" set EAGER_FLAG=--enforce-eager

echo   Model : !MODEL!
echo   Port  : !PORT!
echo   VRAM  : !GPU_MEMORY_UTILIZATION!
echo   CTX   : !MAX_MODEL_LEN! tokens
echo   KV    : !KV_CACHE_DTYPE!
echo   Eager : !ENFORCE_EAGER!
echo.
echo   Waiting for: Application startup complete.
echo ============================================================
echo.

wsl -d Ubuntu -- bash -c "source ~/vllm-env/bin/activate && HF_HOME=!HF_CACHE! python -m vllm.entrypoints.openai.api_server --model !MODEL! --port !PORT! --host 0.0.0.0 --dtype auto --gpu-memory-utilization !GPU_MEMORY_UTILIZATION! --max-model-len !MAX_MODEL_LEN! --kv-cache-dtype !KV_CACHE_DTYPE! !EAGER_FLAG! --trust-remote-code --limit-mm-per-prompt '{\"image\": 0, \"video\": 0}' --chat-template '/mnt/d/Mojtaba/LOCAL MODELS/Qwen3.5-4B BF16 Local/no_think.jinja'"

pause
