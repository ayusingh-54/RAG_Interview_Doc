# Part III — The Generator LLM (Q22–Q23)

---

## Q22: Compare reasoning vs. non-reasoning LLMs for RAG systems.

### ✅ Answer
Reasoning LLMs such as GPT-4o1 and DeepSeek R1 are better generators in RAG systems because they have advanced "test-time compute" and chain-of-thought features. These unique abilities allow them to analyze the retrieved information more effectively and do multi-step reasoning to come up with better answers.

But non-reasoning LLMs are still cheaper and faster, which makes them a good choice for many applications. In the end, the choice between reasoning and non-reasoning models depends on the query complexity.

### 💡 In-depth Explanation
"Reasoning models" (o1, o3, DeepSeek R1, Claude with extended thinking) burn extra compute at inference time to *think* before answering — internal chains of thought, self-checks, plan-then-execute. The trade-off:

| Dimension | Reasoning LLMs | Non-reasoning LLMs |
|-----------|---------------|--------------------|
| Multi-hop questions | Strong | Weak |
| Latency | 5–30s | 0.5–3s |
| Cost / query | $$$ | $ |
| Variance | Lower | Higher |
| Streaming UX | Awkward (long quiet) | Smooth |

A pragmatic pattern: **route by complexity.** Use a small classifier to detect complex queries (multi-hop, comparative, numerical reasoning) → send to a reasoning model. Send simple lookups to a fast non-reasoning model. Many production RAGs hit 80–90% on cheap models and only escalate the hard 10–20%.

### 📝 Example
- Query A: *"What's our office WiFi password?"* → simple lookup → Haiku 4.5 answers in 0.5s, costs ~$0.0001.
- Query B: *"Compare our 2024 vs 2025 expense growth, attribute drivers from board minutes, and project 2026."* → multi-hop synthesis → reasoning model warranted.

### 🎯 Interview Insight
Drop the term **"router architecture"**. It signals you've productionized RAG and care about cost-quality trade-offs at scale.

---

## Q23: What happens with a weak generator LLM in a RAG system?

### ✅ Answer
A weak generator LLM may find it difficult to understand the retrieved context, which could lead to answers that are incomplete or hallucinated. This makes the whole RAG system less useful because the final answers lack coherence and factual correctness, even though the context that was retrieved is good.

So, in a RAG setup, a strong generator LLM is necessary to convert retrieved knowledge into reliable, contextually relevant outputs.

### 💡 In-depth Explanation
Specific failure modes you'll see with a weak generator:

1. **Ignores instructions** — answers from prior knowledge instead of the provided context.
2. **Cherry-picks one chunk** — fails to synthesize across multiple retrieved chunks.
3. **Drops citations** — doesn't reference [Doc N] even when told to.
4. **Long-context confusion** — gets distracted by tangential chunks.
5. **Numeric / table reasoning errors** — misreads tables, off-by-one errors.
6. **Format drift** — outputs prose when JSON is requested.

The fix order is usually: (1) shorten context, (2) tighten prompt, (3) upgrade model.

### 📝 Example
Same retrieved context, two models:
> *Context:* "Our refund window is 30 days for digital goods, 14 days for physical."
> *Q:* "Can I refund a physical product after 20 days?"
> Weak model: "Yes, refunds are allowed within 30 days." ❌ (didn't distinguish digital vs. physical)
> Strong model: "No — physical products have a 14-day refund window, and 20 days exceeds that." ✓

### 🎯 Interview Insight
Stress that **a great retriever cannot save a weak generator**, *and vice versa*. The system is only as strong as its weakest link — production RAG quality is a *product*, not a sum.

---

# Part IV — Query Transformation (Q24–Q30)

---

## Q24: How do you handle ambiguous or vague user queries in RAG systems?

### ✅ Answer
Issues with ambiguous or vague user queries in RAG systems include retrieval of irrelevant information, incomplete answers, and increased risk of hallucination due to the lack of specificity.

The most common strategy to handle ambiguous or vague user queries is query rewriting. Query rewriting transforms unclear queries into precise and focused queries, thereby enhancing retrieval quality and leading to more accurate, grounded responses.

### 💡 In-depth Explanation
A more complete toolkit:

1. **Query rewriting** — small LLM rewrites the user's query into something more retrieval-friendly. ("password" → "how to reset my account password").
2. **Conversational rewriting** — for chat, rewrite considering history. ("And what about the refund?" → "How do I get a refund for a digital product?")
3. **Clarification asking** — when confidence is low, the system asks the user back ("Did you mean X or Y?").
4. **Multi-query expansion** — generate 3–5 paraphrases, retrieve for each, union the results.
5. **HyDE / HyPE** — embed a hypothetical answer instead of the query (Q27, Q28).
6. **Intent classification** — route ambiguous queries to a specialized retriever (e.g., FAQ vs. product spec).

### 📝 Example
User: *"why is my thing broken"*
Rewriter: *"Troubleshooting guide for Acme Widget X: device not powering on or showing error code"*
The rewritten version has nouns that match document chunks → retrieval score jumps from 0.42 → 0.78.

```python
rewrite_prompt = f"""
Rewrite the user's query into a clear, specific search query.
User: {user_query}
Conversation history: {history[-3:]}
Output: a single search query, no explanation.
"""
search_query = small_llm.complete(rewrite_prompt)
```

### 🎯 Interview Insight
Mention the **trade-off**: query rewriting adds 200–500ms latency. So you'd apply it *selectively*, e.g., when initial retrieval scores are low (lazy rewriting) or when the query is < 5 tokens.

---

## Q25: What are the different query transformation techniques that enhance user queries in RAG?

### ✅ Answer
Different query transformation techniques in RAG include query rewriting, query expansion, query decomposition, and HyDE to enhance retrieval relevance and context precision.

- Query Rewriting: Rewrites the initial user query to make it more specific and detailed, boosting retrieval accuracy.
- Query Expansion using Step-Back Prompting: Generates a broader, generalized version of the query.
- Query Decomposition: Divides complex queries into simpler sub-queries to ensure comprehensive coverage and more precise retrieval for each component question.
- HyDE (Hypothetical Document Embedding): Synthesizes a hypothetical answer to the query and uses it as a retrieval query to get more relevant document chunks.

### 💡 In-depth Explanation
Cheat-sheet for *when* to use each:

| Technique | Best for | Example |
|-----------|----------|---------|
| **Rewriting** | Vague, short, conversational queries | "fix it" → detailed troubleshooting query |
| **Step-back / expansion** | Niche queries that need broader context | "Why does Q3 lag?" → "How does seasonality affect retail?" |
| **Decomposition** | Multi-part questions | "Compare X vs Y on price, performance, support." → 3 sub-queries |
| **HyDE** | Vocabulary mismatch (user words ≠ doc words) | Lay user terms → technical doc terms |
| **HyPE** | Pre-indexed efficiency, real-time apps | Same as HyDE but offline |
| **Multi-query** | High-recall use cases (research) | 5 paraphrases → union of results |

### 📝 Example — Decomposition
User query: *"Which of our customers in EMEA have churned in the last year and what was the most-cited reason?"*
Decomposed:
1. "List EMEA customers who churned in 2025."
2. "For each, what reason was given in the exit survey?"
3. "Aggregate top reasons."

Each sub-query retrieves a small focused set; you stitch results together.

### 🎯 Interview Insight
Volunteer the meta-technique: **a small classifier first decides which transformation (if any) to apply.** That's the production-grade design.

---

## Q26: What are the pros and cons of query transformation techniques?

### ✅ Answer
Query transformation techniques in RAG systems offer significant advantages, such as improved retrieval accuracy leading to more relevant and contextually accurate responses.

However, their downsides include increased computational cost, added latency, and potential noise from overexpansion. Over expansion risks retrieving noisy or off-topic documents, while complex methods like query decomposition require careful handling to ensure subqueries align with the original intent.

Some strategies may also require substantial prompt engineering and continuous optimization to match diverse query scenarios. Balancing effectiveness and efficiency is critical to avoid diminishing returns.

### 💡 In-depth Explanation
| Pro | Con |
|-----|-----|
| Better recall on vague queries | +1 LLM call → +200–800ms latency |
| Bridges vocabulary gap | Cost increases (per-query) |
| Surfaces multi-hop info | Noisy expansion can hurt precision |
| Improves user experience | Harder to debug ("why did it return X?") |
| Higher robustness to typos | Risk of *changing user intent* during rewrite |

The biggest hidden cost is **debugging**: when you transform queries, you decouple "what the user typed" from "what the system searched", so trace logs must capture both.

### 📝 Example
User typed: *"how to cancel"*
Rewriter changed to: *"how to cancel a subscription"*
But the user actually meant *"cancel an order I just placed"*. Retrieval returned subscription-cancel docs → wrong answer. Mitigation: log both versions, build an eval set with these tricky cases.

### 🎯 Interview Insight
Talk about **fallbacks**: if the transformed query returns no high-confidence hits, retry with the original. Building safety nets shows production maturity.

---

## Q27: Explain how the HyDE query transformation technique works.

### ✅ Answer
The HyDE (Hypothetical Document Embedding) technique improves RAG retrieval by transforming the user query into a hypothetical answer before embedding it. Rather than directly searching with the query embedding, the HyDE technique utilizes a large language model (LLM) to create a brief, plausible document that could potentially answer the query.

This synthetic document is then encoded into an embedding and used for retrieval, leading to better semantic alignment with actual document chunks in the database. As a result, HyDE enhances retrieval quality, especially for vague or underspecified queries.

### 💡 In-depth Explanation
Why HyDE works: queries and documents live in different *linguistic styles*. A query is a question ("What's our return window?") while documents are statements ("Returns must be initiated within 30 days..."). Their embeddings, even if semantically related, can be surprisingly far apart in vector space. By generating a *hypothetical document* (pseudo-answer) from the query, you produce an embedding in the same style as your corpus → cosine similarity jumps.

The hypothetical document does NOT need to be factually correct. The LLM can invent details freely; what matters is that it's stylistically and topically aligned with real docs.

### 📝 Example
Query: *"Are pets allowed in the office?"*
HyDE pseudo-doc generated by LLM: *"Acme's pet policy permits well-behaved dogs in designated areas of the headquarters. Owners must register the pet with HR and ensure it's vaccinated."*
Now embed this pseudo-doc and search → finds the real pet-policy chunk with much higher confidence than embedding "Are pets allowed in the office?" directly.

```python
def hyde_retrieve(query, k=5):
    pseudo = llm.complete(f"Write a passage that answers: {query}")
    pseudo_vec = embed(pseudo)
    return vector_db.search(pseudo_vec, k=k)
```

### 🎯 Interview Insight
HyDE's clever framing: **"Embed an answer, not a question."** Mention that — interviewers love crisp characterizations.

---

## Q28: Explain how the HyPE technique works in RAG.

### ✅ Answer
The HyPE (Hypothetical Prompt Embedding) technique improves retrieval accuracy by addressing the semantic mismatch between user queries and document chunks.

Unlike HyDE, which generates hypothetical answer documents at query time, HyPE precomputes hypothetical questions for each document chunk during the indexing phase. These questions are designed to capture the key concepts in the chunk, transforming retrieval into a "question-to-question" matching process, which reduces latency and improves retrieval.

### 💡 In-depth Explanation
HyPE flips HyDE: instead of generating a pseudo-doc *from the query at query-time*, HyPE generates pseudo-questions *from each chunk at indexing-time*.

Indexing pipeline (offline):
1. For each chunk, ask an LLM: *"Write 3–5 questions that this chunk answers."*
2. Embed each question, store with a pointer back to the source chunk.
3. At query time, embed the user query (no LLM call!), search the question index → retrieve source chunks of the matching questions.

This makes retrieval **question-to-question** rather than question-to-passage. Result: better semantic alignment + zero query-time LLM cost.

### 📝 Example
Chunk: *"To request time off, submit a PTO request via Workday at least 5 business days in advance."*
LLM-generated hypothetical questions:
1. "How do I request vacation?"
2. "What's the PTO submission deadline?"
3. "How early do I need to file a time-off request?"

User asks: *"How do I take a day off next week?"* → matches Q3 nearly verbatim → retrieves the source chunk.

### 🎯 Interview Insight
Frame the difference as **"compute amortization"**: HyDE pays per query; HyPE pays once at indexing. For high-QPS systems, that's a huge cost win.

---

## Q29: Compare HyPE and HyDE techniques in RAG.

### ✅ Answer
HyDE (Hypothetical Document Embedding) and HyPE (Hypothetical Prompt Embedding) enhance RAG by addressing the semantic gap between user queries and document chunks, but they differ in approach.

- Timing: HyPE generates hypothetical questions during indexing, while HyDE generates hypothetical answer documents at query time.
- Efficiency: HyPE reduces runtime latency by avoiding LLM calls during retrieval, unlike HyDE, which requires an LLM call per query.
- Focus: HyPE focuses on question-question matching, while HyDE focuses on answer-answer matching.

While HyDE is flexible for diverse queries, HyPE’s pre-indexed approach is more efficient for real-time applications.

### 💡 In-depth Explanation
Side-by-side:

| Dimension | HyDE | HyPE |
|-----------|------|------|
| When LLM runs | Query time | Index time |
| Query-time latency | +1 LLM call | None |
| Storage overhead | None | +N pseudo-questions per chunk |
| Adapts to new query types | Yes (any query) | Limited to indexed Q types |
| Cost model | Per-query | One-time + reindex on doc change |
| Best for | Evolving query distributions, low QPS | Stable, high QPS apps |

You can also combine them: index with HyPE for the common case, fall back to HyDE for low-confidence queries.

### 📝 Example
SaaS support bot, 10,000 QPS:
- HyDE: 10,000 × $0.0005 LLM calls = **$5/sec ($432/day) just for query rewriting.**
- HyPE: 50,000 chunks × $0.0005 once = **$25 indexing cost**, then $0/query.

For high-volume apps, HyPE wins by orders of magnitude.

### 🎯 Interview Insight
The key trade-off to articulate: **"HyDE is more flexible; HyPE is more efficient."** Whichever one you'd pick, justify it with a concrete cost or latency constraint.

---

## Q30: To minimize RAG system latency, which pre-retrieval enhancement technique will you choose?

### ✅ Answer
To minimize RAG system latency, I would choose the HyPE (Hypothetical Prompt Embedding) technique. Unlike query transformation techniques such as query rewriting, query expansion, query decomposition, or HyDE, which require LLM calls at query time and increase latency, HyPE precomputes hypothetical questions for document chunks during the indexing phase.

This question-to-question matching approach reduces runtime latency by avoiding real-time LLM calls, making it more efficient for real-time applications while maintaining high retrieval accuracy. By shifting the computational effort to indexing, HyPE ensures faster and more precise document retrieval.

### 💡 In-depth Explanation
Latency contribution of each technique at query time:

| Technique | Latency cost |
|-----------|-------------|
| Original query (no transform) | 0 ms |
| HyPE | 0 ms (precomputed) |
| Query rewriting | ~300 ms (1 small LLM call) |
| HyDE | ~500–800 ms (1 large LLM call) |
| Decomposition | ~500 ms + N parallel searches |
| Multi-query expansion | ~400 ms + N searches |

For a tight 1-second SLA (chat apps), HyPE is the only "free" enhancement. Query rewriting with a *small* model (e.g., Haiku) is a reasonable fallback.

### 📝 Example
A 200ms latency budget for retrieval enhancement:
- ❌ HyDE with GPT-4 (700ms) — exceeds budget
- ❌ Decomposition (500ms) — exceeds budget
- ✓ HyPE (0ms) — fits trivially
- ✓ Query rewrite with Haiku (180ms) — fits

### 🎯 Interview Insight
Don't just pick HyPE — **acknowledge its limitation** (questions must be re-generated when docs change; cold-start costs). Showing you see the trade-off is more impressive than picking the right answer.

---
