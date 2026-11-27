# My Project Overview

## Project Title

Domain-Adapted IT Helpdesk Assistant

> [!note] Longer title (if the field has room)
> Domain-Adapted IT Helpdesk Assistant: Fine-Tuning, Retrieval and Serving of a 7B Open LLM for IT Ticket Triage

## Project Domain

IT Service Management (IT Helpdesk Automation)

## Project Summary

We are building a domain-adapted IT helpdesk assistant on an open 7B LLM (Qwen2.5-7B-Instruct). Given a support ticket, it returns one strict JSON object with the queue, ticket type and priority, plus a concise suggested reply. The model is fine-tuned with QLoRA on a frozen, leakage-checked dataset of synthetic support tickets and augmented with retrieval over past resolved tickets (RAG). It is then merged, 4-bit quantised and served with vLLM behind a FastAPI service with input and output guards. Every stage is compared against baselines on the same held-out test set; the final service is red-teamed with 20 adversarial prompts, and the model is documented in a model card.

> [!tip] Short version (for a character limit)
> A fine-tuned, retrieval-augmented 7B open LLM that triages IT support tickets (queue, type, priority) and drafts replies as strict JSON. It is quantised, served with vLLM behind a FastAPI service with safety guards, red-teamed, and documented with a model card.

## Project Flow: Week 1 to Week 4

In short: test the model, teach it, give it a reference library, then turn it into a safe, fast service.

### Week 1: Prepare the data and measure the starting point

1. Pick a public set of support tickets and keep only the IT-related ones.
2. Hide personal details like emails and phone numbers.
3. Fix the exact answer format the model must give: one JSON with `queue`, `type`, `priority` and `resolution` (a short reply).
4. Split the tickets into train, validation and test sets (1500 / 100 / 180). Make sure near-duplicates don't appear in both train and test, or the scores would look better than they are. Then freeze the split so every later week uses the same tickets.
5. Try the plain model as it is, either asking directly or with a few examples in the prompt, and note where it goes wrong.

**Result:** clean, frozen data and a "before" score to beat.

### Week 2: Teach the model (fine-tuning)

1. Use QLoRA. The big model stays frozen in compressed 4-bit form, and only a tiny add-on (about 0.5% of the model) is trained. That way it fits on a normal GPU.
2. Train only on the answer part, so the model learns to produce the triage and reply, not to repeat the ticket.
3. Run a few small experiments, changing one thing at a time (bigger or smaller add-on, which layers to train). Pick the best one (run B) using the validation set.
4. Compare it with the Week 1 scores on the same test tickets.

**Result:** better replies, and it gets all three labels right together more often. Priority is still weak.

### Week 3: Give it a reference library (RAG)

1. Build a knowledge base of 800 solved tickets the model has never seen.
2. Decide how to search it: how to cut tickets into pieces, which search method, and whether to re-rank results. Each choice is tested on the validation set. The winner was simple keyword search (BM25), no re-ranking, top 3 tickets.
3. For every new ticket, find the 3 most similar solved tickets and paste them into the prompt so the model can borrow from them.
4. Compare the setups fairly on the same test tickets: plain model and fine-tuned model, each with and without RAG, plus simple baselines. Use statistics so small differences aren't over-read.

**Result:** RAG clearly improves the written reply. Label accuracy changes were within noise, and prompts become about 3.6× longer.

### Week 4: Make it a real service and stress-test it

1. Merge the Week 2 add-on into the model, then shrink it to 4-bit (quantisation) so it is smaller and faster. A pass/fail rule checks that quality didn't drop, and it passed.
2. Run it on vLLM (a fast engine for serving LLMs) with a FastAPI web service in front. When a ticket arrives, it is cleaned and checked (input guard). Similar past tickets are found (retrieval), the model answers, and the answer is checked again (output guard) before the JSON goes back.
3. Measure speed, both per request and under heavy load.
4. Red-team it: attack it on purpose with 20 tricky prompts, such as "ignore your instructions". Some prompt-injection attacks still got through, and these are logged honestly.
5. Write the model card (what it is, what it's for, its limits) and a 10-minute demo kit.

**Result:** a working, documented service with its limitations written down.

> [!note] Run order
> Each week saves its outputs and the next week checks and reuses them, so the notebooks must run in order, 1 → 2 → 3 → 4.
