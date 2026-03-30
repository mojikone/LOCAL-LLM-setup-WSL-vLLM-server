# Local LLM Setup — Dual Model Server via WSL2 + vLLM

Run two local AI coding assistants on your GPU — switch between them in VS Code Continue based on your needs.
No internet required after setup. No API costs.

| Model | Speed | Context | Quality | Use When |
|-------|-------|---------|---------|----------|
| **Qwen3.5-9B FP8** (port 8000) | ~50 tok/s | 8,192 tokens | Higher | Complex reasoning, hard problems |
| **Qwen3.5-4B BF16** (port 8001) | ~70 tok/s | 16,384 tokens | Good | Large files, fast answers |

> Only one can run at a time (VRAM constraint). Switch by closing one terminal and opening the other.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Connect to VS Code Continue](#connect-to-vs-code-continue)
- [Hardware Requirements & VRAM Math](#hardware-requirements--vram-math)
- [Choosing Your Model](#choosing-your-model)
- [Configuration Parameters](#configuration-parameters)
- [Tuning for Accuracy vs Creativity](#tuning-for-accuracy-vs-creativity)
- [Alternative: Plain Python + Transformers (No WSL)](#alternative-plain-python--transformers-no-wsl)
- [Our Exact Setup (RTX 5080)](#our-exact-setup-rtx-5080)
- [File Structure](#file-structure)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Run Qwen3.5-9B FP8 (~50 tok/s, higher quality)
Double-click:
```
Qwen3.5-9B FP8 Local\start.bat
```

### Run Qwen3.5-4B BF16 (~70 tok/s, larger context)
Double-click:
```
Qwen3.5-4B BF16 Local\start.bat
```

Wait for this line in the terminal (takes ~2–3 min after first run):
```
INFO:     Application startup complete.
```

To stop: close the terminal or press `Ctrl+C`.

---

## Connect to VS Code Continue

1. Install the [Continue extension](https://marketplace.visualstudio.com/items?itemName=Continue.continue)
2. Press `Ctrl+L` to open the Continue chat
3. Click the model name at the bottom — you'll see both models listed:
   - **"Qwen3.5-9B FP8 | Quality | port 8000"**
   - **"Qwen3.5-4B BF16 | Speed | port 8001"**
4. Select whichever is currently running

The Continue config is at `C:\Users\<username>\.continue\config.yaml`:

```yaml
models:
  - name: "Qwen3.5-9B FP8 | Quality | port 8000"
    provider: openai
    model: lovedheart/Qwen3.5-9B-FP8
    apiBase: http://localhost:8000/v1
    apiKey: local
    completionOptions:
      maxTokens: 2048
      temperature: 0.6
      topP: 0.9
      topK: 50

  - name: "Qwen3.5-4B BF16 | Speed | port 8001"
    provider: openai
    model: Qwen/Qwen3.5-4B
    apiBase: http://localhost:8001/v1
    apiKey: local
    completionOptions:
      maxTokens: 4096
      temperature: 0.6
      topP: 0.9
      topK: 50
```

---

## Hardware Requirements & VRAM Math

| Component | Minimum | Recommended | Our Setup |
|-----------|---------|-------------|-----------|
| GPU VRAM | 12 GB | 16 GB | 16 GB (RTX 5080) |
| System RAM | 16 GB | 32 GB | — |
| Storage | 25 GB free | 40 GB free | NVMe SSD |
| OS | Windows 10/11 | Windows 11 | Windows 11 |
| CUDA | 12.4+ | **12.8** | **12.8** |

> **RTX 4000/5000 series (Ada/Blackwell):** Requires CUDA 12.8.
> Install: https://developer.nvidia.com/cuda-12-8-0-download-archive

### VRAM Math

```
Usable VRAM  =  Total VRAM  −  ~1.4 GB (Windows display overhead)

Model VRAM:
  fp32  = params × 4 bytes   →  7B fp32  = 28 GB
  bf16  = params × 2 bytes   →  7B bf16  = 14 GB
  fp8   = params × 1 byte    →  9B fp8   =  9 GB
  int4  = params × 0.5 byte  →  7B int4  =  3.5 GB

Required  =  Model VRAM  +  KV Cache (min ~1 GB)
```

**Our 16 GB GPU — both models:**
```
Qwen3.5-9B fp8:   9.0 GB model  +  5.2 GB KV cache  =  14.2 GB  ✅
Qwen3.5-4B bf16:  9.3 GB model  +  5.9 GB KV cache  =  15.2 GB  ✅
Both together:    14.3 GB + 15.2 GB = 29.5 GB             ❌ (run one at a time)
```

---

## Choosing Your Model

| Model | VRAM | Speed | Context | Quality | Best For |
|-------|------|-------|---------|---------|----------|
| Qwen3.5-4B bf16 | ~15 GB | **~70 tok/s** | 16,384 tok | Good | Large files, fast chat |
| **Qwen3.5-9B fp8** | ~14 GB | **~50 tok/s** | 8,192 tok | **Strong** | Complex code, reasoning |
| Qwen3.5-27B fp8 | ~27 GB | ~30 tok/s | 32,768 tok | Excellent | Needs 32 GB VRAM |

**Quantization quality** (best → worst):
```
bf16 ≈ fp8  >>  int8  >  int4 (GGUF Q4)  >  int3
```
FP8 = less than 1% quality loss vs bf16.

---

## Which File to Edit — Live vs Restart

| What you want to change | File | Requires restart? |
|---|---|---|
| Max output tokens | `continue_config.yaml.example` → copy to `C:\Users\<you>\.continue\config.yaml` | ❌ **No — live reload** |
| Temperature, top-p, top-k | same `config.yaml` | ❌ **No — live reload** |
| Total context window (`MAX_MODEL_LEN`) | `config.env` in model folder | ✅ Yes — restart `start.bat` |
| VRAM allocation (`GPU_MEMORY_UTILIZATION`) | `config.env` | ✅ Yes — restart `start.bat` |
| Switch model / port | `config.env` | ✅ Yes — restart `start.bat` |

**Rule of thumb:**
- `config.yaml` = how Continue *asks* the server → instant, no restart
- `config.env` = how the server *runs* → must stop and restart `start.bat`

---

## Configuration Parameters

Each model folder has a `config.env` file you can edit before starting:

```ini
# config.env — edit and restart start.bat to apply

MODEL=Qwen/Qwen3.5-4B          # HuggingFace model ID
PORT=8001                       # HTTP port for the API
GPU_MEMORY_UTILIZATION=0.88    # Fraction of VRAM to use (see notes below)
MAX_MODEL_LEN=16384             # Max tokens: input + output combined
KV_CACHE_DTYPE=fp8              # KV cache precision: fp8 (half memory) or auto
ENFORCE_EAGER=true              # true=fast start | false=compile for max speed
```

### `GPU_MEMORY_UTILIZATION` — how to set it

```
The value × total_VRAM must be LESS than free_VRAM at startup.

Example (RTX 5080, 15.92 GB total, 14.52 GB free):
  0.91 × 15.92 = 14.49 GB < 14.52 GB  ✅  (9B model — max safe)
  0.92 × 15.92 = 14.65 GB > 14.52 GB  ❌  (startup fails)
  0.88 × 15.92 = 14.01 GB < 14.52 GB  ✅  (4B model — safe with room)
```

### `MAX_MODEL_LEN` — context vs VRAM trade-off

| Value | Context | VRAM for KV cache |
|-------|---------|-------------------|
| 4,096 | ~3,000 words | Low |
| 8,192 | ~6,000 words | Medium |
| **16,384** | **~12,000 words** | **High (4B model)** |
| 32,768 | ~24,000 words | Very high |

### `ENFORCE_EAGER`

| Value | Startup time | Token speed | When to use |
|-------|-------------|-------------|-------------|
| `true` | ~2–3 min | ~same for chat | Daily use ✅ |
| `false` | 30–60 min (first time only, cached after) | ~10% faster | If you want max throughput |

---

## Tuning for Accuracy vs Creativity

Set these in `C:\Users\<username>\.continue\config.yaml` under `completionOptions`, or pass per-request.

### Temperature

| Value | Behavior | Best For |
|-------|----------|----------|
| `0.0` | Deterministic, always picks most likely token | Exact bug fixes |
| `0.1–0.3` | Very focused, minimal variation | Code generation, factual Q&A |
| `0.6–0.7` | Balanced — **default** | General coding assistant |
| `1.0–1.2` | Creative, varied | Brainstorming, writing |
| `1.5+` | Very random | Experimental only |

### Top-P (Nucleus Sampling)

| Value | Behavior |
|-------|----------|
| `0.1` | Very conservative, highest-probability tokens only |
| `0.9` | **Standard default** |
| `1.0` | No filtering |

### Top-K

| Value | Behavior |
|-------|----------|
| `1` | Greedy (always picks #1 token) — fully deterministic |
| `20` | Focused |
| `50` | **Standard default** |

### Recommended Presets

```yaml
# Precise code (bug fixes, refactoring):
temperature: 0.2
topP: 0.9
topK: 20

# Balanced coding assistant (default):
temperature: 0.6
topP: 0.9
topK: 50

# Creative / brainstorming:
temperature: 1.0
topP: 0.95
topK: 50
```

### Enabling Thinking Mode (Chain-of-Thought)

By default, thinking mode is **disabled** for speed (~70 tok/s).
To enable it (slower ~5–10 tok/s but deeper reasoning):

1. Open `start.bat` in the model folder
2. Remove `--chat-template '...no_think.jinja'` from the command
3. Restart the server

Or enable per-request only via the API:
```json
{ "chat_template_kwargs": { "enable_thinking": true } }
```

---

## Alternative: Plain Python + Transformers (No WSL)

No WSL2 needed — runs directly on Windows. Simpler setup, slightly slower.

**Comparison:**

| | Plain Transformers | vLLM (WSL2) |
|---|---|---|
| Setup | Simple | Moderate |
| Speed | ~15–35 tok/s | ~50–70 tok/s |
| WSL2 required | ❌ | ✅ |
| Context | Same | Same |

### Setup Steps

**1. Install Python 3.12**
```
winget install Python.Python.3.12
```

**2. Create virtual environment and install dependencies**
```cmd
py -3.12 -m venv venv
venv\Scripts\activate
pip install torch --index-url https://download.pytorch.org/whl/cu128
pip install transformers accelerate fastapi uvicorn
```

**3. Create `server.py`**
```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from fastapi import FastAPI
import uvicorn, json

MODEL    = "Qwen/Qwen3.5-4B"   # change to any model that fits your VRAM
PORT     = 8000
MAX_NEW  = 2048                  # default max output tokens
TEMP     = 0.6                   # default temperature

torch.backends.cuda.matmul.allow_tf32 = True
tokenizer = AutoTokenizer.from_pretrained(MODEL)
model = AutoModelForCausalLM.from_pretrained(
    MODEL, torch_dtype=torch.bfloat16, device_map="cuda:0", attn_implementation="sdpa"
)

app = FastAPI()

@app.post("/v1/chat/completions")
async def chat(req: dict):
    messages   = req.get("messages", [])
    max_tokens = req.get("max_tokens", MAX_NEW)
    temperature = req.get("temperature", TEMP)
    text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    inputs = tokenizer(text, return_tensors="pt").to("cuda")
    with torch.inference_mode():
        output = model.generate(
            **inputs, max_new_tokens=max_tokens,
            do_sample=temperature > 0, temperature=temperature
        )
    reply = tokenizer.decode(output[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True)
    n_new = len(output[0]) - inputs["input_ids"].shape[1]
    return {"choices": [{"message": {"role": "assistant", "content": reply}}],
            "usage": {"completion_tokens": n_new}}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT)
```

**4. Run and connect Continue** — same `config.yaml` entry pointing to `http://localhost:8000/v1`.

### Model choices for plain Transformers (16 GB VRAM)

| Model | VRAM | Speed |
|-------|------|-------|
| Qwen3.5-4B bf16 | ~9.3 GB | ~30 tok/s |
| Qwen3-8B bf16 | ~16 GB | ~15 tok/s |

---

## Our Exact Setup (RTX 5080)

### System
- GPU: NVIDIA RTX 5080 (16 GB GDDR7, Blackwell sm_120)
- OS: Windows 11
- CUDA: 12.8
- WSL2: Ubuntu with Python 3.12 virtualenv (`~/vllm-env`)
- vLLM: 0.18.0

### Models Downloaded
| Model | HuggingFace ID | Size | Cache Location |
|-------|---------------|------|----------------|
| Qwen3.5-9B FP8 | `lovedheart/Qwen3.5-9B-FP8` | ~9 GB | `C:\Users\mojtaba\.cache\huggingface` |
| Qwen3.5-4B BF16 | `Qwen/Qwen3.5-4B` | ~9.3 GB | same |

### Key Discoveries

1. **RTX 5080 needs CUDA 12.8** — CUDA 12.4 fails (`sm_120` not supported)
2. **Qwen3.5 is multimodal** — vision encoder allocates VRAM by default. Fixed with `--limit-mm-per-prompt '{"image":0,"video":0}'`
3. **Thinking mode enabled by default** — generates hidden reasoning tokens, reduces speed from ~50 to ~5 tok/s. Fixed by patching chat template (`no_think.jinja`)
4. **9B fp8 on 16 GB: max context = 8192** — KV cache math leaves no room for more
5. **4B bf16 on 16 GB: context = 16384** — smaller model, more KV cache room
6. **FlashInfer JIT on 4B** — first startup compiles CUDA kernels (~5 min). Instant after that
7. **`--enforce-eager` skips CUDA graph compilation** — 30–60 min compile time avoided with minimal speed loss for interactive chat

### Final Achieved Performance

| Model | Speed | Context | VRAM Used |
|-------|-------|---------|-----------|
| Qwen3.5-9B FP8 (port 8000) | **~50 tok/s** | 8,192 tokens | ~14.2 GB |
| Qwen3.5-4B BF16 (port 8001) | **~70 tok/s** | 16,384 tokens | ~15.2 GB |

---

## File Structure

```
LOCAL MODELS/
├── start.bat                        ← ONE-CLICK selector (copy start_selector.bat here)
│                                       asks you which model to start (1 or 2)
│
├── Qwen3.5-9B FP8 Local/
│   ├── config.env                   ← edit server parameters (requires restart)
│   ├── start.bat                    ← direct launcher (port 8000)
│   ├── start_selector.bat           ← copy this to parent LOCAL MODELS\ folder
│   ├── start_with_log.ps1           ← PowerShell launcher with log file
│   ├── no_think.jinja               ← patched chat template (thinking disabled)
│   ├── continue_config.yaml.example ← copy to C:\Users\<you>\.continue\config.yaml
│   └── README.md                    ← this file
│
└── Qwen3.5-4B BF16 Local/
    ├── config.env                   ← edit server parameters (requires restart)
    ├── start.bat                    ← direct launcher (port 8001)
    ├── start_with_log.ps1           ← PowerShell launcher with log file
    └── no_think.jinja               ← patched chat template (thinking disabled)
```

---

## Troubleshooting

### "Free memory less than desired GPU memory utilization"
Lower `GPU_MEMORY_UTILIZATION` in `config.env` by 0.01 until it passes.

### "No available memory for cache blocks"
- Ensure `KV_CACHE_DTYPE=fp8` in `config.env`
- Reduce `MAX_MODEL_LEN` (try 4096)
- Add `--limit-mm-per-prompt '{"image":0,"video":0}'` if missing

### Very slow (~5 tok/s)
Thinking mode is on. Check that `--chat-template no_think.jinja` is in the start command.

### Context length error (input + output > max)
Reduce `maxTokens` in `config.yaml`, or reduce `MAX_MODEL_LEN` and switch to the 4B model for larger files.

### First startup slow on 4B model
FlashInfer compiles CUDA kernels on first use (~5 min). Normal. Every subsequent start is instant.

### torch / CUDA mismatch
```bash
pip install torch --index-url https://download.pytorch.org/whl/cu128
```

### WSL not found
```powershell
wsl --install -d Ubuntu
wsl --update
```

---

## Credits

- [lovedheart/Qwen3.5-9B-FP8](https://huggingface.co/lovedheart/Qwen3.5-9B-FP8) — community FP8 of [Qwen/Qwen3.5-9B](https://huggingface.co/Qwen/Qwen3.5-9B)
- [Qwen/Qwen3.5-4B](https://huggingface.co/Qwen/Qwen3.5-4B) — official BF16 instruct model
- [vLLM](https://github.com/vllm-project/vllm) — inference engine
- [Continue](https://github.com/continuedev/continue) — VS Code extension
