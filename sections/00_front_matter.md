# RAG Interview Questions & Answers — Complete Study Guide

> **A consolidated, enriched study guide based on the [RAG-Interview-Questions-and-Answers-Hub](https://github.com/KalyanKS-NLP/RAG-Interview-Questions-and-Answers-Hub) by Kalyan KS.**
>
> Original answers are preserved as authored. Each question is supplemented with an **In-depth Explanation**, a **Concrete Example** (with code where useful), and an **Interview Insight** so you can read everything in one place and walk into your interview confident.

---

## How to Use This Document

1. **Skim the Table of Contents** to map the territory. Notice how questions cluster — interviewers usually probe one cluster deeply rather than asking a random sample.
2. **For first pass**, read each question's *Answer* + *Interview Insight*. That gets you a working vocabulary fast.
3. **For deep prep**, read *In-depth Explanation* + *Example*. Try to re-state the example in your own words.
4. **Right before the interview**, re-read only the *Interview Insight* lines.

The 105 questions are organized into 11 parts that mirror the lifecycle of building a RAG system — from fundamentals → indexing → retrieval → re-ranking → evaluation.

---

## Table of Contents

| Part | Topic | Questions |
|------|-------|-----------|
| I    | RAG Foundations & Motivation                    | Q1 – Q10   |
| II   | RAG Pipeline, Indexing & Hyperparameters        | Q11 – Q21  |
| III  | The Generator LLM                               | Q22 – Q23  |
| IV   | Query Transformation (HyDE, HyPE, etc.)         | Q24 – Q30  |
| V    | Chunking Strategies                             | Q31 – Q37  |
| VI   | Retrieval Approaches & Vector Search            | Q38 – Q54  |
| VII  | Embedding Optimization & Quantization           | Q55 – Q60  |
| VIII | Re-ranking (Cross-encoders, Bi-encoders)        | Q61 – Q72  |
| IX   | Retrieval Metrics (Precision, Recall, MRR, MAP, NDCG) | Q73 – Q80 |
| X    | Context Precision, Recall & Relevancy           | Q81 – Q96  |
| XI   | Generator Evaluation (Faithfulness, Response Relevancy) | Q97 – Q105 |

---

## A Mental Model of the RAG Pipeline

Before diving in, fix this picture in your head — most questions are really probing one of these boxes.

```
┌─────────────────────────── INDEXING (offline) ───────────────────────────┐
│                                                                          │
│   Raw docs ─► Parse ─► Chunk ─► Embed ─► Vector DB (with metadata)       │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────── QUERY TIME (online) ──────────────────────────┐
│                                                                          │
│   User Query                                                             │
│       │                                                                  │
│       ▼                                                                  │
│   [Query Transformation]  ── (HyDE, rewrite, expand, decompose)          │
│       │                                                                  │
│       ▼                                                                  │
│   [Retriever]  ── (semantic / keyword / hybrid → top-K candidates)       │
│       │                                                                  │
│       ▼                                                                  │
│   [Re-ranker]  ── (cross-encoder → reorder candidates)                   │
│       │                                                                  │
│       ▼                                                                  │
│   [Augment Prompt]  ── (instructions + query + top-N chunks)             │
│       │                                                                  │
│       ▼                                                                  │
│   [Generator LLM]  ── (final grounded response)                          │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

Whenever a question feels abstract, ask yourself: *which box is this about?* That alone will frame your answer.

---
