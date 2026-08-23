# Helpa — Yorùbá/English Emergency Guidance for the Minutes Before the Hospital

**Domain:** healthcare_medical · **Languages:** English, Yorùbá · **Base:** Gemma 4 E2B · **Runtime:** llama.cpp, GGUF Q4_K_M

---

## 1. The problem

Most preventable deaths after an accident happen **before the patient reaches a hospital**. A crash on an expressway, a pot of hot oil in a kitchen, a child convulsing at 2am, a snake bite on a farm — the outcome is often decided in the ten minutes before anyone medical is involved.

In that window, the wrong action is worse than none. Butter on a burn. Tilting a bleeding nose backwards. Forcing a spoon into the mouth of someone having a seizure. Sucking venom from a snake bite. These are common, taught by word of mouth, and they cause harm.

The people standing in that window are rarely clinicians, and across much of Nigeria they are not operating in English.

### Why existing tools fail them

| General assistants | Helpa |
|---|---|
| English only | Answers in Yorùbá or English, whichever was used |
| Need a network connection | Runs fully offline on a low-end laptop |
| Generic advice, no local context | Nigerian presentations — malaria, typhoid, kwashiorkor, snake bite |
| Rarely say what *not* to do | Leads with the harmful actions to avoid |

Helpa exists because an emergency assistant that only works in English, and only with signal, is not an emergency assistant for the people most likely to need one.

## 2. Why a purpose-built model was necessary

We measured base Gemma 4 E2B before building anything. Asked in Yorùbá what to do for a feverish, shivering child, it produced fluent nonsense — rendering *doctor* as **ìwé ìròyìn**, which means *newspaper*. The identical question in English returned a clean, sensible answer that correctly directed the user to a clinician.

The cause is structural, not a prompting problem:

| | tokens per word |
|---|---|
| English | 1.16 |
| Yorùbá | **2.75** |

`'Ṣàlàyé àwọn èròjà'` → `['Ṣ','à','l','ày','é','▁à','w','ọn','▁è','r','ò','jà']`

Diacritical Yorùbá fragments into near-character sequences at 2.4× the token cost, so tone placement must be modelled token by token. Repetition-loop degeneration is the known signature of that weakness. Closing it is the core technical contribution here.

## 3. Model selection and quantization

**Gemma 4 E2B** — natively multilingual, so Yorùbá is adaptation rather than a cold start; effective-2B fits the 8 GB laptop profile with headroom; supported by llama.cpp, which the track requires.

**Text-only LoRA** via `FastLanguageModel`: r=32, α=64, lr=1e-4, 3 epochs, with `embed_tokens` and `lm_head` frozen. This model takes no image input, so no vision layers are trained — the adapter is smaller and training is faster than a multimodal run.

**Q4_K_M** is the accuracy-per-byte knee. Heavier quantization destroys exactly the low-probability token distinctions that carry Yorùbá tone marks, and tone is not decoration in Yorùbá — it is meaning.

## 4. Training data

1,412 unique pairs — **773 Yorùbá / 639 English** — plus a fluency slice:

| source | n | contributes |
|---|---|---|
| Yorùbá health Q&A | 760 | 70 triage topics, ~10 question paraphrases each |
| English health & first aid | 614 | step-by-step emergency procedure |
| Yorùbá procedures, written for this work | 13 | procedural Yorùbá the source lacked |
| Yorùbá fluency (en→yo rendering) | 2,000 | closes the generation gap in §2 |

Three decisions define the quality of this set.

**7,075 rows were really 785.** The Yorùbá source contained 7,075 entries; deduplication showed 785 unique question/answer pairs and only 95 unique answers — the rest exact repeats. Training on the raw file would have produced memorization rather than capability.

**The two languages were teaching different skills.** The Yorùbá data was almost entirely *triage* — "what does this symptom mean" → "go to hospital". The English data was *procedure* — numbered emergency steps. Mixed unchanged, the model would learn *English = steps, Yorùbá = hospital referral*, which is precisely the inequality this project exists to remove. We authored 13 Yorùbá step-by-step procedures — choking, CPR, severe bleeding, fracture, burns, poisoning, seizure, heat collapse — to close it.

**Every Yorùbá token was verified before training** against a 68,665-token attested vocabulary built from a human-reviewed Yorùbá corpus and human-written reference answers. The gate caught real authoring errors at source, including `ìdodo` — which means *navel* — mistakenly used for *toothpaste* in a burns instruction. That is exactly the class of error that reads as fluent and would otherwise have shipped.

**Safety framing is deliberate.** Every answer is anchored to a hospital referral, and procedures lead with what *not* to do, because in this domain the harmful actions are the common ones.

## 5. Results

| probe | base Gemma 4 E2B | fine-tuned |
|---|---|---|
| Yorùbá triage | fluent nonsense; renders *doctor* as *newspaper* | correct, actionable guidance |
| English triage | coherent referral | preserved |
| Yorùbá procedure | — | numbered steps including what to avoid |

Training: `train_loss 1.225 → 0.160`, `eval_loss 0.548 → 0.324` over 3 epochs, monotone eval curve with no overfitting signature despite the small dataset. Best checkpoint selected on eval loss.

## 6. Constraints that shaped the design

- **No connectivity at inference.** Zero network calls. Emergencies happen where signal does not reach — that is the design case, not the edge case.
- **8 GB RAM ceiling.** Selected E2B over E4B, and Q4_K_M over higher precision.
- **Thermal budget on passively-cooled laptops.** A 2B-effective model at Q4_K_M sustains generation without triggering throttling.
- **Yorùbá token economics.** At 2.75 tokens/word a Yorùbá answer costs ~2.4× its English equivalent; training context was raised to 2048 so complete multi-step procedures fit rather than truncating mid-instruction.

## 7. Input modes

Gemma 4 is natively multimodal — text, image and audio. In its product form the assistant accepts a photograph of an injury or a short video of what is happening, because in an emergency nobody wants to type a description.

**This submission exercises the text pathway**, which is also a real usage mode: a bystander typing *"snake bit someone on the leg"* is faster than framing a photograph. The submitted artifact is correspondingly the text model, running in llama.cpp with no external dependencies.

## 8. Benchmarks

Development figures; see `submission.json` for profiler-measured values on the evaluation laptop.

| metric | source |
|---|---|
| Quantized file size | ~3 GB (Q4_K_M) |
| Peak RSS | profiler |
| Generation throughput | profiler |
| Time to first token | profiler |

## 9. Scope and roadmap

This assistant gives first-aid guidance and symptom triage. It does not diagnose, and every answer routes to a health facility for anything clinical.

Yorùbá output is vocabulary-verified against an attested corpus; clinician review of every procedure, and alignment with Nigerian Red Cross and WHO first-aid guidance, is part of the pipeline ahead of field use.

Next: voice input and output, since hands are busy in an emergency and Gemma 4 supports audio natively; image and video input in production; Hausa, Igbo and Pidgin via the same verification method; and deepening the procedural half of the dataset, which is where the life-saving minutes are.
