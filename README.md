# Helpa — ADTC 2026 Laptop LLM Track

Offline first-aid and health-triage guidance in Yorùbá and English.
Gemma 4 E2B · LoRA fine-tuned · GGUF Q4_K_M · runs fully offline on llama.cpp.

> Most preventable deaths after an accident happen before the patient reaches a
> hospital. In that window the wrong action is worse than none. Helpa gives
> step-by-step guidance — including what *not* to do — in the language the person
> speaks, with no internet connection.

See [REPORT.md](REPORT.md) for the technical writeup.

## Run the profiler

```bash
bash download_model.sh
adtc-profiler run --submission . --mode participant --output submission.json
cat submission.json
```

## Try it

Yorùbá:

```bash
llama-cli -m model/Helpa-Gemma4-E2B-Q4_K_M.gguf --reasoning off --single-turn \
  -p "Ejò bu ẹnìkan jẹ ní ẹsẹ̀. Kí ni àwọn ìgbésẹ̀ tí mo gbọdọ̀ ṣe?"
```

English:

```bash
llama-cli -m model/Helpa-Gemma4-E2B-Q4_K_M.gguf --reasoning off --single-turn \
  -p "Someone spilled hot oil on their arm. What should I do right now, and what should I avoid?"
```

`--reasoning off` suppresses Gemma 4's thinking channel so you see only the answer.

## Model

Weights: https://huggingface.co/yusasif/Helpa-ADTC-challenge (public, no credentials required)
