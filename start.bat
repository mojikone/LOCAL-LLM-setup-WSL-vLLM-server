@echo off
echo ============================================================
echo   Qwen3.5-9B FP8 - vLLM Server (WSL2)
echo   http://localhost:8000  ~50 tok/s
echo   Press Ctrl+C to stop
echo ============================================================
echo.
wsl -d Ubuntu -- bash -c "source ~/vllm-env/bin/activate && HF_HOME=/mnt/c/Users/mojtaba/.cache/huggingface python -m vllm.entrypoints.openai.api_server --model lovedheart/Qwen3.5-9B-FP8 --port 8000 --host 0.0.0.0 --dtype auto --gpu-memory-utilization 0.91 --max-model-len 8192 --kv-cache-dtype fp8 --enforce-eager --trust-remote-code --limit-mm-per-prompt '{\"image\": 0, \"video\": 0}' --chat-template '/mnt/d/Mojtaba/LOCAL MODELS/Qwen3.5-9B FP8 Local/no_think.jinja'"
pause
