# Guardrails & Observability Guide

> **Note:** This document summarizes the built-in data checks, API safety guards, and system health metrics verified across the executed notebooks in `notebooks_output/`. 

---

## 1. Built-In Safety Guardrails

The project enforces data quality, formatting accuracy, and safe responses across all four stages of the pipeline (as implemented in `notebooks/` and recorded in `notebooks_output/`):

| Pipeline Stage | Safety Control | What It Does | Verified Result |
| :--- | :--- | :--- | :--- |
| **Data Preparation (Week 1)** | PII Scan & Redaction | Automatically detects and masks personal information (such as emails and phone numbers) before training or evaluation. | Clean, anonymized dataset splits frozen with SHA-256 verification. |
| **Data Preparation (Week 1)** | Near-Duplicate Leakage Guard | Checks for similar tickets across training, validation, and test sets using TF-IDF similarity so test data never leaks into training. | Zero cross-split leakage across the 1,500 train / 100 val / 180 test splits. |
| **API Input Guard (Week 4)** | Input Sanitization & Injection Detection | Strips hidden control characters, redacts live PII from incoming tickets, and flags suspicious prompt-injection patterns in the response metadata. | Implemented in the generated FastAPI gateway (`week4/repo/serve/app.py`). |
| **Knowledge Grounding (Weeks 3 & 4)** | Retrieval-Augmented Context | Grounds replies in the top-3 most relevant resolved tickets from an 800-ticket knowledge base (`kb.jsonl`) using BM25 retrieval. | Improves reply quality (ROUGE-L **0.345**) over ungrounded generation. |
| **API Output Guard (Week 4)** | Strict Schema & Credential Protection | Enforces the exact 4-key JSON structure (`queue`, `type`, `priority`, `resolution`), validates label vocabularies, and withholds responses that ask users for passwords or credentials. | **100.0% schema-valid rate** on the 180-ticket held-out test set. |

---

## 2. System Observability & Health Monitoring

All notebooks and the Week 4 serving stack emit built-in metrics and logs so the team and evaluators can verify system health without adding external monitoring tools:

### Pipeline & Training Telemetry (`notebooks_output/` & `logs/`)
* **Pre-Flight Checks:** Every notebook runs an automated GPU availability check and verifies input file integrity using SHA-256 manifests before executing.
* **Resource Efficiency:** QLoRA fine-tuning (Run B) trains **0.53%** of model parameters, peaks at **12.7 GiB** of GPU memory, and completes in **~17 minutes** on an NVIDIA L40S without overfitting (validation loss **0.7655**).
* **Quantisation Quality Gate:** Before serving, the W4A16 quantised model is automatically benchmarked against the unquantised model and achieves a **PASSED** verdict across schema validity, label accuracy, and ROUGE-L thresholds.
* **Experiment Tracking:** All evaluation scores across Weeks 1–3 are saved in structured JSON files and visualized in `docs/experiment-dashboard/index.html`.

### Live API Telemetry (`week4/repo/`)
* **Built-In Response Metadata:** Every FastAPI response includes retrieved ticket IDs, safety guard flags, and a step-by-step latency breakdown alongside the triage prediction.
* **Serving Speed (NVIDIA L40S):**
  * **Single-request decode speed:** **140.9 tokens/sec** (1.3x faster than standard Hugging Face generation).
  * **Peak concurrent throughput:** **1,455 tokens/sec** under load.
  * **End-to-end ticket latency:** **~1.00 sec/ticket** with RAG retrieval enabled (**0.85 sec/ticket** without RAG).

---

## 3. Where Evaluators Can Verify These Controls

* **Executed Code & Outputs:** `notebooks_output/it_helpdesk_week1_baseline.ipynb` through `notebooks_output/it_helpdesk_week4_serving.ipynb`
* **Experiment Dashboard:** `docs/experiment-dashboard/index.html` and `docs/experiment-dashboard/results.json`
* **Slurm Execution Logs:** `artifacts/image.png` (full Week 1–4 pipeline run)
