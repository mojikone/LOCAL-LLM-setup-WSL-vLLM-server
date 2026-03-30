$log = 'D:\Mojtaba\LOCAL MODELS\Qwen3.5-9B FP8 Local\vllm.log'
Remove-Item $log -ErrorAction SilentlyContinue
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Qwen3.5-9B FP8 - vLLM Server (WSL2)" -ForegroundColor Cyan
Write-Host "  http://localhost:8000  ~50 tok/s" -ForegroundColor Cyan
Write-Host "  Log: $log" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
wsl -d Ubuntu -- bash -c "source /home/mojtaba/vllm-env/bin/activate && export HF_HOME=/mnt/c/Users/mojtaba/.cache/huggingface && python -m vllm.entrypoints.openai.api_server --model lovedheart/Qwen3.5-9B-FP8 --port 8000 --host 0.0.0.0 --dtype auto --gpu-memory-utilization 0.91 --max-model-len 8192 --kv-cache-dtype fp8 --enforce-eager --trust-remote-code --limit-mm-per-prompt '{\"image\": 0, \"video\": 0}' --chat-template '/mnt/d/Mojtaba/LOCAL MODELS/Qwen3.5-9B FP8 Local/no_think.jinja'" 2>&1 | Tee-Object -FilePath $log
