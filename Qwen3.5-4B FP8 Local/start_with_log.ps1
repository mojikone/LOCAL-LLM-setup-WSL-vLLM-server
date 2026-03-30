$log = "$PSScriptRoot\vllm.log"
Remove-Item $log -ErrorAction SilentlyContinue

# Load config.env
$config = @{}
Get-Content "$PSScriptRoot\config.env" | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "=" } | ForEach-Object {
    $k, $v = $_ -split "=", 2
    $config[$k.Trim()] = $v.Trim()
}

$model     = $config["MODEL"]
$port      = $config["PORT"]
$hfcache   = $config["HF_CACHE"]
$gpuUtil   = $config["GPU_MEMORY_UTILIZATION"]
$maxLen    = $config["MAX_MODEL_LEN"]
$kvDtype   = $config["KV_CACHE_DTYPE"]
$eager     = if ($config["ENFORCE_EAGER"] -eq "true") { "--enforce-eager" } else { "" }
$template  = "/mnt/d/Mojtaba/LOCAL MODELS/Qwen3.5-4B FP8 Local/no_think.jinja"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Qwen3.5-4B FP8 - vLLM Server (WSL2)" -ForegroundColor Cyan
Write-Host "  http://localhost:$port   ~80 tok/s" -ForegroundColor Cyan
Write-Host "  Log -> $log" -ForegroundColor Cyan
Write-Host "  Edit config.env to change parameters" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

$cmd = "source ~/vllm-env/bin/activate && HF_HOME=$hfcache python -m vllm.entrypoints.openai.api_server " +
       "--model $model --port $port --host 0.0.0.0 --dtype auto " +
       "--gpu-memory-utilization $gpuUtil --max-model-len $maxLen " +
       "--kv-cache-dtype $kvDtype $eager --trust-remote-code " +
       "--limit-mm-per-prompt '{`"image`": 0, `"video`": 0}' " +
       "--chat-template '$template'"

wsl -d Ubuntu -- bash -c $cmd 2>&1 | Tee-Object -FilePath $log
