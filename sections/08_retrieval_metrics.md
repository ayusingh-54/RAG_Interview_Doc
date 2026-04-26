# Part IX — Retrieval Metrics: Precision, Recall, MRR, MAP, NDCG (Q73–Q80)

---

## Q73: How would you evaluate the effectiveness of a reranker in a RAG system? Which metrics (e.g., MRR, MAP, NDCG) would you prioritize and why?

### ✅ Answer
The effectiveness of a re-ranker in a RAG system is best evaluated using ranking metrics that capture how well it prioritizes relevant chunks. Mean Reciprocal Rank (MRR) is key when the focus is on how quickly the first relevant chunk appears, ideal for question-answering scenarios.

Mean Average Precision (MAP) is useful when multiple relevant chunks matter, measuring both precision and ranking quality across results. Normalized Discounted Cumulative Gain (NDCG) excels when relevance is graded rather than binary, rewarding the correct order of highly relevant chunks.

### 💡 In-depth Explanation
| Metric | Best for | Pitfall |
|--------|---------|---------|
| MRR | Single-answer Q&A (FAQ bot) | Ignores all but the first relevant doc |
| MAP | Multi-doc retrieval (research) | Binary relevance only |
| NDCG@k | Graded relevance (highly/somewhat/not) | Needs graded labels |
| Precision@k | "Are top results good?" | Order-blind |
| Recall@k | "Did I find the answer at all?" | Order-blind, gameable by large K |

For a RAG re-ranker specifically, **NDCG@10** is the most common single-metric north star, with **MRR** as a secondary check.

### 📝 Example
Build a 200-question eval set with annotated relevant chunks. Run before/after rerank:

| Metric | Before rerank | After rerank | Δ |
|--------|--------------|-------------|---|
| MRR | 0.62 | 0.81 | +0.19 |
| NDCG@10 | 0.71 | 0.86 | +0.15 |
| Precision@5 | 0.48 | 0.72 | +0.24 |

You'd ship the reranker on these numbers.

### 🎯 Interview Insight
Always state you'd build an **eval set first**. Without one, all reranker tuning is theatre.

---

## Q74: Explain the difference between Precision@k and Recall@k in the context of RAG. When might you prefer one over the other?

### ✅ Answer
Precision@k focuses on accuracy of the retrieval by measuring the proportion of the top-k retrieved chunks that are relevant to the query. Recall@k focuses on completeness of the retrieval by measuring the proportion of all relevant chunks that are retrieved within the top-k results.

You might choose Precision@k when you want to ensure high-quality, relevant chunks to reduce noise. On the other hand, you might choose Recall@k when it is crucial to capture as many relevant chunks as possible.

### 💡 In-depth Explanation
Formal definitions:
- **Precision@k** = (# relevant in top-k) / k
- **Recall@k** = (# relevant in top-k) / (total relevant in corpus)

For RAG specifically:
- **Use Recall@k** for the *first stage* of a two-stage pipeline. You want the answer to *exist* in the candidate set; reranker handles ordering. Set k large (50–100).
- **Use Precision@k** for the *final* set passed to the LLM. You want to minimize noise; the LLM gets distracted by irrelevant chunks. Set k small (3–5).

### 📝 Example
Corpus has 4 relevant chunks; retriever returns 5: [rel, irr, rel, irr, irr].
- Precision@5 = 2/5 = 0.4
- Recall@5 = 2/4 = 0.5

If you only have 3 slots in the LLM prompt, you'd want precision@3 to be ~1.0. If you don't care about the prompt size yet (you'll rerank), you want recall@50 ≈ 1.0.

### 🎯 Interview Insight
The pair to memorize: **"Recall feeds rerank; rerank feeds the LLM."** That's the production loop.

---

## Q75: Why is MRR unsuitable when there are multiple relevant chunks per query, and how does MAP address this limitation?

### ✅ Answer
MRR (Mean Reciprocal Rank) considers the rank of the first relevant chunk and disregards the ranks and presence of other relevant chunks. This limitation makes MRR more appropriate for scenarios where a single chunk sufficiently answers the query.

In contrast, MAP (Mean Average Precision) addresses this by averaging the precision across all relevant ranks, accounting for the presence and order of all relevant chunks. Hence, MAP is preferred over MRR for cases where multiple relevant chunks contribute to answering a query comprehensively.

### 💡 In-depth Explanation
**MRR formula**: average of 1 / rank-of-first-relevant across queries.

**AP formula** (per query): mean of `Precision@k` over each rank `k` where a relevant doc was retrieved.

**MAP**: mean of AP across queries.

MRR ignores everything after the first hit; MAP integrates over the whole ranked list. For queries with N relevant docs, MAP rewards getting all N near the top.

### 📝 Example
Two retrievers, same query (3 relevant docs in corpus):
- A returns: [rel, irr, irr, irr, rel, rel] → MRR = 1; AP = (1/1 + 2/5 + 3/6)/3 ≈ 0.63
- B returns: [rel, rel, rel, irr, irr, irr] → MRR = 1; AP = (1/1 + 2/2 + 3/3)/3 = 1.0

MRR ties them. MAP correctly says B is much better.

### 🎯 Interview Insight
Soundbite: **"MRR rewards finding *one* needle; MAP rewards stacking the haystack with needles at the top."**

---

## Q76: Given a retrieval result, show how to manually calculate the MAP@5 (Mean Average Precision at 5). What does MAP reveal about the retrieval system that raw Precision does not?

### ✅ Answer
To manually calculate MAP@5, list the top 5 retrieved items for each query and note the positions where relevant items appear; then, compute precision at each relevant position (e.g., if the first relevant item appears at rank 2, precision = 1/2) and average these values to get the Average Precision (AP) for that query. Repeat this for all queries and take the mean of their APs for MAP@5.

MAP@5 reveals a retrieval system's ability to rank relevant items higher. In contrast, raw Precision only measures the proportion of relevant items retrieved, ignoring their order. This makes MAP@5 a better indicator of how well the system prioritizes relevance at the top of the result list.

### 💡 In-depth Explanation
Step-by-step recipe (worked twice):

**Single query worked example.** Top-5: [rel, irr, rel, irr, rel]; total relevant in corpus = 3.
1. Relevant ranks: 1, 3, 5.
2. Precision at each: P@1 = 1/1, P@3 = 2/3, P@5 = 3/5.
3. AP = (1.0 + 0.667 + 0.6) / 3 = 0.756.

**Now compare** to a retriever that returns [rel, rel, rel, irr, irr]:
1. Relevant ranks: 1, 2, 3.
2. P@1=1, P@2=1, P@3=1 → AP = 1.0.

Both retrievers have **same Precision@5 (3/5)** but very different MAP. MAP correctly says front-loading matters.

### 📝 Example — MAP across multiple queries
Q1: AP = 0.756. Q2: AP = 1.0. Q3: AP = 0.5.
MAP = (0.756 + 1.0 + 0.5) / 3 = 0.752.

### 🎯 Interview Insight
Be ready to compute by hand. Saying *"P@1 + P@3 + P@5 averaged over relevant positions"* and writing it out shows fluency.

---

## Q77: If all the relevant chunks are at the very bottom, how would this affect MRR, MAP, and NDCG metrics? Explain each.

### ✅ Answer
If all relevant chunks are at the bottom of a ranked list for a search query, MRR (Mean Reciprocal Rank) would be low, as it measures the reciprocal of the rank of the first relevant chunk. MAP (Mean Average Precision) would also be low, as it averages precision across all relevant chunks, penalizing late appearances heavily due to increasing denominators in precision calculations.

NDCG (Normalized Discounted Cumulative Gain) would similarly be low, as it discounts the relevance scores of chunks appearing later in the ranking, reducing the cumulative gain.

### 💡 In-depth Explanation
Concrete numerical impact for top-10 with 3 relevant chunks at positions 8, 9, 10:

- **MRR** = 1/8 = 0.125 (vs. 1.0 if relevant at rank 1).
- **MAP** = (1/8 + 2/9 + 3/10)/3 = (0.125 + 0.222 + 0.300)/3 ≈ 0.216 (vs. 1.0 ideal).
- **NDCG@10**: DCG with discounts log₂(rank+1) → relevant at rank 8 contributes ~1/log₂9 ≈ 0.315; ideal would be ~ 1/log₂2 = 1.0. So NDCG suffers proportionally.

All three are order-aware → all penalize late placement; NDCG's logarithmic discount is the gentlest, MRR is the most punitive (a single position drop from rank 1 to rank 2 halves MRR).

### 📝 Example — Same set, different order
Best case (relevant at top): MRR=1, MAP=1, NDCG=1.
Worst case (relevant at bottom): MRR≈0.125, MAP≈0.22, NDCG≈0.4.
Same set of relevant docs, dramatically different metric values — that's the whole point of order-aware metrics.

### 🎯 Interview Insight
Interviewers love numerical questions. Have the **discount log formula `1/log₂(rank+1)`** memorized — it tells you NDCG drops about 30% per doubling of rank.

---

## Q78: Suppose your RAG retriever gets perfect Recall@10 but low Precision@10. What problems could this cause for the downstream generator?

### ✅ Answer
Perfect Recall@10 means all relevant chunks are retrieved within the top 10 results. Low Precision@10 indicates many of those retrieved chunks are irrelevant. If a RAG retriever achieves perfect Recall@10 but low Precision@10, the downstream generator receives all the relevant information mixed with much irrelevant content.

This will confuse the generator model and increase the chance of generating off-topic or inaccurate responses.

### 💡 In-depth Explanation
Specific failure modes of a noisy context:

1. **Distraction** — irrelevant chunks pull the LLM toward off-topic content.
2. **Lost-in-the-middle** — the relevant chunk gets buried at position 6 of 10, where attention is weakest.
3. **Token waste** — irrelevant chunks burn context, leaving less room for the answer.
4. **Conflicting info** — irrelevant chunks may state things that contradict the relevant ones.
5. **Cost** — every irrelevant chunk = wasted input tokens.

Solution: re-rank to lift precision while preserving recall.

### 📝 Example
A RAG eval with Recall@10=1.0 but Precision@10=0.3 (3 relevant + 7 noise):
- Without rerank: Faithfulness drops 12 points; LLM cherry-picks wrong chunk.
- With rerank to top-3 (Precision@3=1.0): Faithfulness recovers to baseline.

### 🎯 Interview Insight
The fix in one sentence: **"Recall is achieved by retrieval; precision is achieved by reranking."** That's the production cure for this scenario.

---

## Q79: Compare and contrast "order-aware" and "order-unaware" retrieval metrics in RAG, giving examples for each from the set (Precision, Recall, MRR, MAP, NDCG).

### ✅ Answer
Order-aware retrieval metrics consider the ranking of retrieved items, emphasizing the importance of higher-ranked relevant results. For example, Mean Reciprocal Rank (MRR) and Normalized Discounted Cumulative Gain (NDCG) are order-aware, as MRR evaluates the rank of the first relevant item and NDCG accounts for relevance scores and ranking positions.

Order-unaware metrics focus solely on whether relevant items are retrieved and ignore the order. Precision and Recall are order-unaware, measuring the proportion of relevant items retrieved (Precision) and the proportion of relevant items found out of all relevant items (Recall), without considering their order.

### 💡 In-depth Explanation
| Metric | Order-aware? | Why |
|--------|-------------|-----|
| Precision@k | No | Set membership |
| Recall@k | No | Set membership |
| F1@k | No | Harmonic mean of P@k, R@k |
| MRR | **Yes** | Reciprocal of position |
| MAP | **Yes** | Averages P@k at each relevant rank |
| NDCG | **Yes** | Logarithmic discount on rank |
| Hit@k | No | Binary "found-it-or-not" |

For RAG, where chunk *order in the prompt matters* (LLMs attend more strongly to the start), **always include at least one order-aware metric** in your evaluation.

### 📝 Example
Three retrievers, same recall@5 = 0.6:
- A: [rel, rel, rel, irr, irr] → MAP=1.0, NDCG=high
- B: [irr, rel, irr, rel, rel] → MAP≈0.55, NDCG=med
- C: [irr, irr, rel, rel, rel] → MAP=0.46, NDCG=low

Set-based metrics tie them; order-aware metrics correctly rank A > B > C.

### 🎯 Interview Insight
The senior phrase: **"Set-based metrics tell you what's *retrievable*; order-aware metrics tell you what's *usable* by the LLM."**

---

## Q80: How would the value of NDCG@k change if all relevant chunks are retrieved but in the reverse order (least to most relevant)?

### ✅ Answer
NDCG@k rewards placing highly relevant chunks at earlier ranks and applies a logarithmic discount to relevance scores at lower positions. So reversing the order pushes the most relevant chunks further down the list—making them less valuable in the NDCG calculation.

While all relevant items are present, their suboptimal positions reduce the overall score since NDCG is sensitive to both the presence and order of relevant items in the top k. The value of NDCG@k will decrease compared to the ideal ranking, but will remain higher than a ranking with irrelevant chunks at the top.

### 💡 In-depth Explanation
NDCG = DCG / IDCG (Ideal DCG). With graded relevance (e.g., 3=highly relevant, 2=relevant, 1=marginal, 0=irrelevant):

DCG = Σ relᵢ / log₂(i+1)

Reversed order means the *most relevant* (highest gain) is at the bottom (highest discount) — so it contributes far less. But because the irrelevant docs aren't replacing relevant ones (they're not even in the list), DCG doesn't go to 0; it just shrinks.

### 📝 Example — Numerical
4 relevant items with grades [3, 2, 1, 1].
- **Ideal order** (most→least): IDCG = 3/log₂2 + 2/log₂3 + 1/log₂4 + 1/log₂5 ≈ 3 + 1.26 + 0.5 + 0.43 = 5.19.
- **Reversed**: DCG = 1/log₂2 + 1/log₂3 + 2/log₂4 + 3/log₂5 ≈ 1 + 0.63 + 1 + 1.29 = 3.92.
- **NDCG = 3.92 / 5.19 ≈ 0.76.**

Compare a retrieval with all irrelevant docs in top-4: DCG = 0; NDCG = 0.

### 🎯 Interview Insight
Be ready with the formula and a worked example. NDCG questions are favorites — **practice computing it by hand for 3–5 items** before any RAG interview.

---
