# Local LLM Setup — Qwen3.5-9B FP8 via WSL2 + vLLM

A complete guide to running a fast local AI coding assistant on your own PC using WSL2 and vLLM.
Achieved speed: **~50 tok/s** on RTX 5080 (16 GB VRAM).

---

## Table of Contents

- [What This Does](#what-this-does)
- [How to Start the Server](#how-to-start-the-server)
- [Connect to VS Code Continue](#connect-to-vs-code-continue)
- [Hardware Requirements](#hardware-requirements)
- [Choosing Your Model](#choosing-your-model)
- [Understanding the Parameters](#understanding-the-parameters)
- [Tuning for Accuracy vs Creativity](#tuning-for-accuracy-vs-creativity)
- [Our Exact Setup (RTX 5080)](#our-exact-setup-rtx-5080)
- [Troubleshooting](#troubleshooting)

---

## What This Does

Runs a local OpenAI-compatible AI server on your GPU — no internet required, no API costs.
The server connects to the **Continue** extension in VS Code for chat-based coding assistance.

**Architecture used:**
- Model: `lovedheart/Qwen3.5-9B-FP8` (9B parameters, FP8 quantized)
- Server: vLLM 0.18.0 (PagedAttention, optimized inference)
- Runtime: WSL2 (Ubuntu) with CUDA 12.8
- Interface: VS Code + Continue extension

---

## How to Start the Server

1. Double-click **`start.bat`** in this folder
2. A terminal window opens — wait for this line:
   ```
   INFO:     Application startup complete.
   ```
3. Takes **~2–3 minutes** after the first run (model is cached locally)
4. Server runs at `http://localhost:8000`
5. To stop: close the terminal window or press `Ctrl+C`

---

## Connect to VS Code Continue

1. Install the [Continue extension](https://marketplace.visualstudio.com/items?itemName=Continue.continue) in VS Code
2. Press `Ctrl+L` to open the Continue chat panel
3. Click the model name at the bottom and select **"Qwen3.5-9B FP8 Local"**
4. Start chatting — responses arrive at ~50 tok/s

The Continue config is at:
```
C:\Users\<your-username>\.continue\config.yaml
```

Add this model entry:
```yaml
models:
  - name: Qwen3.5-9B FP8 Local
    provider: openai
    model: lovedheart/Qwen3.5-9B-FP8
    apiBase: http://localhost:8000/v1
    apiKey: local
```

---

## Hardware Requirements

| Component | Minimum | Recommended | Our Setup |
|-----------|---------|-------------|-----------|
| GPU VRAM | 12 GB | 16 GB | 16 GB (RTX 5080) |
| System RAM | 16 GB | 32 GB | — |
| Storage | 15 GB free | 30 GB free | NVMe SSD |
| OS | Windows 10/11 | Windows 11 | Windows 11 |
| CUDA | 12.4+ | 12.8 | 12.8 |

> **Important for RTX 4000/5000 series (Blackwell/Ada):**
> These GPUs require **CUDA 12.8** specifically. CUDA 12.4 does not support sm_89/sm_120 (Blackwell).
> Install from: https://developer.nvidia.com/cuda-12-8-0-download-archive

### VRAM Math — How to Choose Your Model

```
Usable VRAM = Total VRAM - ~1.4 GB (Windows/display overhead)

Model VRAM  = Parameters × bytes_per_param
            fp32 = 4 bytes   →  7B fp32  = 28 GB
            bf16 = 2 bytes   →  7B bf16  = 14 GB
            fp8  = 1 byte    →  9B fp8   =  9 GB
            int4 = 0.5 byte  →  7B int4  =  3.5 GB

Required    = Model VRAM + KV Cache (min ~1–2 GB)
```

**Example for 16 GB GPU:**
```
Usable VRAM  = 14.52 GB
Model (fp8)  =  9.00 GB
KV Cache     =  5.52 GB  ✅ comfortable
```

---

## Choosing Your Model

| Model | VRAM | Speed (vLLM) | Quality | Notes |
|-------|------|--------------|---------|-------|
| Qwen3.5-4B fp16 | ~8 GB | ~80 tok/s | Good | Fast, less capable |
| **Qwen3.5-9B fp8** | **~9 GB** | **~50 tok/s** | **Strong** | **Our choice** |
| Qwen3.5-9B bf16 | ~18 GB | — | Best | Doesn't fit 16 GB |
| Qwen3.5-27B fp8 | ~27 GB | — | Excellent | Needs 32 GB VRAM |

**Quantization quality ranking** (best to worst):
```
bf16 ≈ fp8 >> int8 > int4 (GGUF Q4) > int3
```
FP8 is nearly identical to bf16 — less than 1% quality loss.

---

## Understanding the Parameters

These are the flags used in `start.bat`. Here's what each one does:

### Core Settings

| Parameter | Value | What It Does |
|-----------|-------|--------------|
| `--model` | `lovedheart/Qwen3.5-9B-FP8` | HuggingFace model ID |
| `--port` | `8000` | HTTP port for the API |
| `--dtype` | `auto` | Let vLLM auto-detect model precision (fp8) |
| `--gpu-memory-utilization` | `0.91` | Use 91% of VRAM (leaves headroom for OS) |
| `--max-model-len` | `8192` | Max context window in tokens (~6,000 words) |

### Memory Optimizations

| Parameter | Value | What It Does |
|-----------|-------|--------------|
| `--kv-cache-dtype` | `fp8` | Store KV cache in fp8 (half the memory vs bf16) |
| `--enforce-eager` | *(flag)* | Skip CUDA graph compilation — faster startup, ~same speed for interactive use |
| `--limit-mm-per-prompt` | `{"image":0,"video":0}` | Disable vision encoder (text-only mode, saves ~2 GB VRAM) |

### Quality / Behavior

| Parameter | Value | What It Does |
|-----------|-------|--------------|
| `--chat-template` | `no_think.jinja` | Disables chain-of-thought thinking mode (5× faster responses) |
| `--trust-remote-code` | *(flag)* | Allow model-specific custom code to run |

### Adjusting `--gpu-memory-utilization`

```
Too high → startup fails: "Free memory less than desired utilization"
Too low  → fewer KV cache blocks → shorter usable context

Formula: value must satisfy  (value × total_VRAM) < free_VRAM_at_startup
Example: 0.91 × 15.92 GB = 14.49 GB  <  14.52 GB free  ✅
         0.92 × 15.92 GB = 14.65 GB  >  14.52 GB free  ❌
```

### Adjusting `--max-model-len`

| Value | Context | Use Case |
|-------|---------|----------|
| 4096 | ~3,000 words | Short chats, simple coding |
| **8192** | **~6,000 words** | **Our setting — good balance** |
| 16384 | ~12,000 words | Long files, large codebases |
| 32768 | ~24,000 words | Needs more VRAM for KV cache |

---

## Tuning for Accuracy vs Creativity

These are **generation parameters** you pass per-request (in Continue's chat or API calls).
They control how the model generates text.

### Temperature

Controls randomness. Range: `0.0` to `2.0`

| Value | Behavior | Best For |
|-------|----------|----------|
| `0.0` | Fully deterministic, always picks most likely token | Bug fixing, exact answers |
| `0.1–0.3` | Very focused, minimal variation | Code generation, factual Q&A |
| `0.6–0.7` | Balanced — default for most tasks | General coding assistant |
| `1.0–1.2` | Creative, varied responses | Brainstorming, writing |
| `1.5+` | Very random, sometimes incoherent | Experimental only |

### Top-P (Nucleus Sampling)

Limits token pool to the top P% of probability mass. Range: `0.0` to `1.0`

| Value | Behavior |
|-------|----------|
| `0.1` | Very conservative, only highest-probability tokens |
| `0.9` | Standard — good default |
| `1.0` | No filtering |

### Top-K

Hard limit on number of candidate tokens. Range: `1` to `∞`

| Value | Behavior |
|-------|----------|
| `1` | Greedy (always picks #1 token) |
| `20` | Focused |
| `50` | Standard default |

### Recommended Presets

```yaml
# Precise coding (bug fixes, refactoring):
temperature: 0.2
top_p: 0.9

# Balanced coding assistant (default):
temperature: 0.6
top_p: 0.9

# Creative / brainstorming:
temperature: 1.0
top_p: 0.95
top_k: 50

# Thinking mode (slow but thorough — for hard problems):
# Remove --chat-template flag from start.bat
# temperature: 0.6
```

### Enabling Thinking Mode

Thinking mode makes the model reason step-by-step before answering.
Slower (~5 tok/s) but more accurate for complex problems.

To enable: remove `--chat-template no_think.jinja` from `start.bat`

To enable per-request only (API):
```json
{
  "chat_template_kwargs": {"enable_thinking": true}
}
```

---

## Our Exact Setup (RTX 5080)

### System
- GPU: NVIDIA RTX 5080 (16 GB GDDR7, Blackwell sm_120)
- OS: Windows 11
- CUDA: 12.8
- WSL2: Ubuntu 22.04
- Python: 3.12 (inside vllm-env virtualenv in WSL)
- vLLM: 0.18.0

### Model
- `lovedheart/Qwen3.5-9B-FP8` — community FP8 quantization of `Qwen/Qwen3.5-9B`
- Architecture: Qwen3.5 hybrid (GDN + Attention layers)
- Downloaded to: `C:\Users\mojtaba\.cache\huggingface`

### Key Discoveries Made During Setup

1. **RTX 5080 needs CUDA 12.8** — CUDA 12.4 fails with `sm_120` not supported
2. **Qwen3.5-9B bf16 = 16 GB** — doesn't fit on 16 GB VRAM with KV cache
3. **FP8 model = 9 GB** — fits with 5+ GB KV cache remaining
4. **Vision encoder overhead** — Qwen3.5 is multimodal; adding `--limit-mm-per-prompt {"image":0,"video":0}` disables it and frees ~2 GB VRAM
5. **Thinking mode** — enabled by default, uses chain-of-thought reasoning (slow). Disabled via custom chat template for 10× speed improvement
6. **CUDA graph compilation** — takes 30–60 min on first run for this hybrid architecture; `--enforce-eager` skips it with minimal speed loss for interactive use
7. **`--gpu-memory-utilization 0.92` fails** — 0.91 is the maximum that passes the startup VRAM check on this system

### Achieved Performance

| Metric | Value |
|--------|-------|
| Token speed | ~50 tok/s |
| Startup time | ~2–3 min |
| VRAM used | ~15.5 GB / 15.92 GB |
| Max context | 8,192 tokens |
| Thinking mode | Disabled (fast) |

### Final Command (what `start.bat` runs)

```bash
python -m vllm.entrypoints.openai.api_server \
  --model lovedheart/Qwen3.5-9B-FP8 \
  --port 8000 \
  --host 0.0.0.0 \
  --dtype auto \
  --gpu-memory-utilization 0.91 \
  --max-model-len 8192 \
  --kv-cache-dtype fp8 \
  --enforce-eager \
  --trust-remote-code \
  --limit-mm-per-prompt '{"image": 0, "video": 0}' \
  --chat-template no_think.jinja
```

---

## Alternative Method: Plain Python + Transformers (No WSL)

If you don't want WSL2, you can run a simpler server directly on Windows using Python and HuggingFace Transformers.

**Trade-offs vs vLLM:**

| | Plain Transformers | vLLM (WSL2) |
|---|---|---|
| Setup complexity | Simple | Moderate |
| Speed | ~15–35 tok/s | ~50 tok/s |
| WSL2 required | No | Yes |
| Model support | Any HF model | Most HF models |
| Streaming | Yes (manual) | Yes (built-in) |

### Setup Steps (Windows, no WSL)

**1. Install Python 3.12**
```
winget install Python.Python.3.12
```

**2. Create a virtual environment**
```cmd
py -3.12 -m venv venv
venv\Scripts\activate
```

**3. Install dependencies**
```cmd
pip install torch --index-url https://download.pytorch.org/whl/cu128
pip install transformers accelerate fastapi uvicorn
```

**4. Create `server.py`** — a FastAPI server that wraps the model:
```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import uvicorn, json

MODEL = "Qwen/Qwen3.5-4B"   # or any model that fits your VRAM

torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True

tokenizer = AutoTokenizer.from_pretrained(MODEL)
model = AutoModelForCausalLM.from_pretrained(
    MODEL,
    torch_dtype=torch.bfloat16,
    device_map="cuda:0",
    attn_implementation="sdpa"
)

app = FastAPI()

@app.post("/v1/chat/completions")
async def chat(req: dict):
    messages = req.get("messages", [])
    max_tokens = req.get("max_tokens", 512)
    text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    inputs = tokenizer(text, return_tensors="pt").to("cuda")
    with torch.inference_mode():
        output = model.generate(**inputs, max_new_tokens=max_tokens, do_sample=False)
    reply = tokenizer.decode(output[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True)
    return {"choices": [{"message": {"role": "assistant", "content": reply}}],
            "usage": {"completion_tokens": len(output[0]) - inputs["input_ids"].shape[1]}}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**5. Run it**
```cmd
python server.py
```

**6. Connect Continue** — same `config.yaml` entry as the vLLM method.

### Which Model for Plain Transformers?

| Model | VRAM | Speed | Notes |
|-------|------|-------|-------|
| Qwen3.5-4B bf16 | ~8 GB | ~30 tok/s | Best fit for 16 GB |
| Qwen3-8B bf16 | ~16 GB | ~15 tok/s | Tight fit, works |
| Qwen3.5-9B bf16 | ~18 GB | ❌ | Doesn't fit 16 GB |

> **Why is plain Transformers slower?**
> vLLM uses PagedAttention + CUDA kernel fusion. Transformers generates one token at a time with no batching optimization.

---

## Troubleshooting

### "Free memory less than desired GPU memory utilization"
Lower `--gpu-memory-utilization` by 0.01 increments until it passes.

### "No available memory for cache blocks"
- Add `--kv-cache-dtype fp8`
- Reduce `--max-model-len` (try 4096)
- Add `--limit-mm-per-prompt '{"image":0,"video":0}'`

### Server starts but Continue gives no response
- Verify server shows `Application startup complete`
- Check `apiBase` in `config.yaml` matches `http://localhost:8000/v1`
- Test manually: `curl http://localhost:8000/health`

### Very slow (~5 tok/s)
Thinking mode is enabled. Add `--chat-template no_think.jinja` to your start command.

### torch / CUDA version mismatch
Install CUDA 12.8 PyTorch:
```bash
pip install torch --index-url https://download.pytorch.org/whl/cu128
```

### WSL not found or not starting
```powershell
wsl --install -d Ubuntu
wsl --update
```

---

## File Structure

```
./
├── start.bat              # Double-click to start server
├── start_with_log.ps1     # PowerShell launcher (saves log to vllm.log)
├── no_think.jinja         # Patched chat template (thinking disabled by default)
└── README.md              # This file
```

---

## Credits

- Model: [lovedheart/Qwen3.5-9B-FP8](https://huggingface.co/lovedheart/Qwen3.5-9B-FP8) (community FP8 of [Qwen/Qwen3.5-9B](https://huggingface.co/Qwen/Qwen3.5-9B))
- Inference: [vLLM](https://github.com/vllm-project/vllm)
- IDE Integration: [Continue](https://github.com/continuedev/continue)
