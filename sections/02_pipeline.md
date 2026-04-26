# Part II — RAG Pipeline, Indexing & Hyperparameters (Q11–Q21)

---

## Q11: Explain the steps in the indexing process in a RAG pipeline.

### ✅ Answer
There are four steps in the indexing process of a RAG pipeline: parsing, chunking, encoding, and storing. The parsing step deals with extracting the document content. Then, the chunking step splits the extracted content into smaller pieces called chunks.

The encoding step uses an embedding model to convert chunks into dense numerical vectors called embeddings. Finally, these embeddings are saved in a vector database for efficient search and retrieval.

All these steps in the indexing process are performed offline.

### 💡 In-depth Explanation
A more honest indexing pipeline has six steps; teams often skip 5–6 and pay for it later:

1. **Ingest** — pull from S3, Drive, Confluence, Slack. Track source + version.
2. **Parse** — convert PDF/DOCX/HTML/Markdown into clean text. Tools: `unstructured`, `pypdf`, `pdfplumber`, `tika`. Tables and images need special handling.
3. **Chunk** — split into retrieval units (Q34 covers methods).
4. **Embed** — run each chunk through an embedding model, get a fixed-size vector.
5. **Enrich with metadata** — title, section path, author, date, source URL, doc-id. Lets you filter (`WHERE source='wiki' AND date > 2025`) at query time.
6. **Store** — write to vector DB (Pinecone, Weaviate, Qdrant, pgvector). Build the ANN index.

### 📝 Example
```python
# 1. Parse
text = pypdf.PdfReader("policy.pdf").extract_text()

# 2. Chunk
splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
chunks = splitter.split_text(text)

# 3. Embed + 4. Store with metadata
import openai, pinecone
for i, chunk in enumerate(chunks):
    vec = openai.embeddings.create(input=chunk, model="text-embedding-3-large").data[0].embedding
    pinecone.upsert(vectors=[{
        "id": f"policy-{i}",
        "values": vec,
        "metadata": {"source": "policy.pdf", "section": "refunds", "page": 3}
    }])
```
This is offline: run nightly, on document change events, or on demand.

### 🎯 Interview Insight
Always mention **metadata**. Junior answers stop at "embed and store"; senior engineers know that metadata-based filtering makes retrieval orders-of-magnitude better in real corpora.

---

## Q12: Explain the importance of chunking in RAG.

### ✅ Answer
Chunking in Retrieval-Augmented Generation (RAG) is crucial because it breaks down large texts into smaller and semantically coherent segments called chunks. Proper chunking helps to find relevant information efficiently by creating focused chunks that maintain context and avoid irrelevant noise.

Choosing the right chunk size balances detail and context, optimizing both retrieval accuracy and computational efficiency. Ineffective chunking can lead to poor retrieval results and incoherent responses, which makes it a foundational step for successful RAG performance in real-world applications.

### 💡 In-depth Explanation
Chunking is doing two jobs simultaneously:

1. **Constraint job** — embeddings have a max input length (e.g., 8192 tokens for OpenAI's `text-embedding-3-large`). You *must* chunk long docs.
2. **Quality job** — embeddings represent a chunk's *average meaning*. A 200-token focused chunk on "refund policy" embeds differently from a 5000-token doc that mentions refunds in passing. Smaller, topically-coherent chunks → sharper embeddings → better retrieval.

The best chunkers respect document *structure* (headings, sections, paragraphs) rather than fixed token windows. A heading and its following paragraph usually belong in the same chunk; splitting them mid-section is destructive.

### 📝 Example
A 50-page employee handbook chunked two ways:

| Strategy | Result |
|----------|--------|
| Fixed 1000-token windows | Some chunks span "End of Vacation Policy → Start of IT Security." Embedding is a muddle of two topics. |
| Markdown-aware (split at `##`) | Each chunk = one policy section. Embedding cleanly represents that one topic. Retrieval precision jumps. |

### 🎯 Interview Insight
Frame chunking as **"the most under-appreciated lever in RAG."** Many teams obsess over the LLM and ignore chunking — yet chunking changes top-K relevance dramatically. Mentioning that earns credibility.

---

## Q13: How do you choose the chunk size for a RAG system?

### ✅ Answer
Choosing the chunk size for a RAG system involves balancing granularity, context completeness, and computational efficiency. Smaller chunks (e.g., 100-200 tokens) allow precise retrieval but may lack sufficient context. Larger chunks (e.g., 500-1000 tokens) provide more context at the cost of increased computational load and potential noise.

The optimal size depends on the use case, document structure, embedding model, and the generator (LLM) model. For example, smaller chunks are suitable for fact-based queries, and more complex queries benefit from larger ones.

### 💡 In-depth Explanation
A practical decision framework:

| Factor | Pull toward smaller (~150–300 tok) | Pull toward larger (~500–1000 tok) |
|--------|----------------------------------|-----------------------------------|
| Query type | Factual, lookup ("what is X?") | Synthesis, analysis ("compare X and Y") |
| Doc structure | Tables, FAQs, structured data | Narrative, prose, code |
| Embedding model | Older (BERT-class) | Newer long-context (E5, BGE-large) |
| Generator context | Small budget (8K) | Large budget (200K+) |

**Empirical recipe**: start at 512 tokens with 10–15% overlap. Build a small eval set (50 query/answer pairs). Sweep chunk sizes [128, 256, 512, 1024]. Pick the size that maximizes Context Recall (Q86) without tanking Faithfulness (Q97).

### 📝 Example
A SaaS support corpus had average answer length ~80 tokens. Switching from 1024-token to 256-token chunks improved top-3 retrieval accuracy from 71% → 88% on a 100-question eval set, because the right answer no longer competed for "embedding airtime" with neighboring topics in a fat chunk.

### 🎯 Interview Insight
Never give a single number when asked. Always say *"It depends on (a) query type, (b) corpus structure — and I'd validate empirically with an eval set."* That signals a scientist's mindset.

---

## Q14: What are the potential consequences of having chunks that are too large versus chunks that are too small?

### ✅ Answer
Large chunks often mix different topics into one chunk and reduce the chunk's relevance. This can lead to coarse vector representations and less accurate retrieval. Large chunks can also add noise and confuse the model with irrelevant information that isn't important, resulting in a less accurate answer.

Small chunk sizes in RAG systems can lead to fragmented context. This fragmentation often leads to poor retrieval quality because information that is semantically related may be split up into chunks that are not retrieved together. Furthermore, smaller chunks mean that there are more chunks in the vector database, which increases storage costs and slows down the similarity search.

### 💡 In-depth Explanation
The two failure modes manifest differently in eval metrics:

| Symptom | Likely cause |
|---------|--------------|
| High Context Recall, low Faithfulness | Chunks too large → relevant info present but LLM gets distracted by surrounding noise |
| Low Context Recall, high Context Precision | Chunks too small → answer is split across chunks, you only retrieved one piece |
| Top-K must be huge to find anything | Chunks too small or too noisy |
| Answers contradict between similar queries | Inconsistent chunking (some chunks include section header, some don't) |

### 📝 Example
A query: *"What is the incident severity classification?"*

- Too-large chunks (2000 tok): one chunk covers severity + escalation + comms — retrieved, but the LLM picks up unrelated escalation steps and includes them in the answer.
- Too-small chunks (100 tok): the severity table is split across 4 chunks; only 2 get retrieved → answer is incomplete.
- Right-sized (~400 tok aligned with the section): the whole severity section in one chunk → clean answer.

### 🎯 Interview Insight
Phrase it as a sweet spot, not a single number: *"Both extremes degrade quality; the sweet spot for prose is usually 300–500 tokens with section-aware splitting."*

---

## Q15: Explain the retrieval process step-by-step in a RAG pipeline.

### ✅ Answer
The retrieval process in RAG systems starts by encoding the user query, i.e., converting it into a dense vector representation using an embedding model. This vector representation is then used to search the vector database, which has the embeddings of chunks.

Based on the similarity scores, the vector database system returns the most relevant document chunks.

### 💡 In-depth Explanation
A more complete retrieval pipeline at query time:

1. **Query preprocessing** — lowercase, strip punctuation, optionally rewrite or expand (Q25).
2. **Query embedding** — encode with the *same* model used at indexing time (mismatched models = scrambled space).
3. **ANN search** — find top-K (typically 50–100) candidates by cosine similarity using HNSW/IVF (Q47).
4. **Metadata filtering** — apply hard constraints (`source='wiki' AND lang='en'`).
5. **Re-ranking** — cross-encoder reorders to true top-N (typically 5–10) (Q61).
6. **Diversity / deduplication** — MMR or chunk-collapse so you don't return three near-identical paragraphs.
7. **Hand off** — insert top chunks into the prompt template.

Many production bugs live in steps 4 and 6 — they're often skipped.

### 📝 Example
```python
def retrieve(query, top_k=50, top_n=5):
    q_vec = embed(query)
    candidates = vector_db.query(q_vec, top_k=top_k, filter={"lang": "en"})
    reranked = cross_encoder.rank(query, candidates)
    diverse  = mmr(reranked, lambda_=0.7)[:top_n]
    return diverse
```

### 🎯 Interview Insight
Always distinguish **top-K (after ANN)** from **top-N (after rerank)**. Confusing these two is a common junior mistake; using both terms correctly signals fluency.

---

## Q16: What are the key considerations when choosing an LLM for a RAG system?

### ✅ Answer
The key considerations when choosing an LLM for a RAG system are reading-comprehension ability, context window size, and inference speed. Reading-comprehension ability reflects how effectively the model processes the retrieved context to generate accurate responses.

Context window size is crucial, as longer context models enable RAG systems to effectively include more relevant chunks. However, this must be balanced against cost and latency requirements.

Additionally, inference speed, infrastructure compatibility, and licensing terms also play a key role in deployment decisions for real-world RAG solutions.

### 💡 In-depth Explanation
Beyond the three above, evaluate:

- **Instruction following** — RAG prompts are long (instructions + context + query). Weak instruction-followers ignore "answer only from context."
- **Citation behavior** — does the model naturally produce inline citations like "[Doc 3]"?
- **Hallucination rate on closed-book** — measure on a held-out RAG eval (e.g., HaluBench).
- **Tool/function calling** — for agentic RAG.
- **Cost per 1M tokens** — input + output, which dominates at scale.
- **Hosting** — closed-API (OpenAI, Anthropic) vs. open-weights (Llama 4, Qwen3). Compliance often forces self-hosting.

### 📝 Example — Decision Matrix
| Use case | Reasonable choice |
|----------|------------------|
| High-volume support chat (cheap, fast) | Haiku 4.5, Llama 4 8B, Gemini Flash |
| Legal analysis (accuracy > cost) | Opus 4.7, GPT-4-class |
| On-prem (data residency) | Llama 4 70B, Qwen3 |
| Multi-document synthesis | Long-context model (Sonnet 4.6 1M, Gemini 2.5 Pro) |

### 🎯 Interview Insight
Show you think about **cost per query**, not just model quality. Engineers who only mention quality come across as not having shipped at scale.

---

## Q17: How is the prompt provided to the LLM in a RAG system different from a standard, non-RAG prompt?

### ✅ Answer
The prompt provided to the LLM without a RAG setup includes only the user query and the optional instructions. Here, the LLM generates the response based on its knowledge gained during training.

The prompt provided to the LLM with the RAG setup includes the user query, instructions, and relevant context. Here, the LLM generates the response as per the instructions solely based on the provided relevant context.

### 💡 In-depth Explanation
A good RAG prompt has five blocks, in this order:

1. **System role** — "You are a customer support assistant for Acme."
2. **Grounding instruction** — "Answer using ONLY the provided Context. If unsure, say 'I don't know.'"
3. **Citation instruction** — "Cite sources as [Doc N] inline."
4. **Context block** — retrieved chunks, each labeled with `[Doc N]` and metadata.
5. **User query** — the actual question, last (so the model attends to it strongly).

Putting the query *last* exploits attention recency. Putting context *between* the instructions and query helps the model treat context as evidence, not just trivia.

### 📝 Example
```
You are a financial analyst assistant. Answer the question using ONLY
the provided Context. Cite sources with [Doc N]. If the Context does
not contain the answer, reply "I don't know."

[Doc 1, 10-K 2025, p. 14] Revenue grew 12% YoY to $4.2B.
[Doc 2, Q3 earnings call] CFO noted FX headwinds of 3 percentage points.

Question: What was the revenue growth in 2025, and what factors affected it?
```

### 🎯 Interview Insight
Mention you'd **A/B test** prompt variants. Saying "I treat the prompt template like code: versioned, tested with an eval set, and improved iteratively" is gold.

---

## Q18: What are the key hyperparameters in a RAG pipeline?

### ✅ Answer
Chunk size, chunk overlap, embedding dimensionality, retrieval top-k, and retrieval threshold are some of the most important hyperparameters for retrieval in RAG. Temperature and max output length are two important hyperparameters for RAG generation.

The chunk size determines how much text is put into a segment before embedding, influencing the context granularity retrieved. Chunk overlap repeats a set of tokens at chunk boundaries, helping preserve important context across segments. Embedding dimensionality is the vector size used to represent text, which affects retrieval precision and database efficiency.

Retrieval top-k sets the number of most similar chunks returned, directly impacting recall and context diversity in the response. The retrieval threshold is a similarity cutoff that filters retrieved results, ensuring only relevant chunks are selected.

Temperature controls the randomness of generated text, balancing creativity and determinism in model outputs. Max output length limits the number of tokens generated, managing the verbosity and computational cost of responses.

### 💡 In-depth Explanation
A complete RAG hyperparameter map:

| Stage | Hyperparameter | Typical range |
|-------|---------------|---------------|
| Indexing | chunk_size | 200–1024 tokens |
| Indexing | chunk_overlap | 0–20% of chunk_size |
| Indexing | embedding_dim | 384–3072 |
| Indexing | embedding_model | task-tuned vs. general |
| Retrieval | top_k (initial) | 20–100 |
| Retrieval | similarity_threshold | 0.65–0.80 |
| Re-rank | top_n (after rerank) | 3–10 |
| Generation | temperature | 0.0–0.3 (RAG = factual) |
| Generation | max_tokens | 256–2048 |
| Generation | top_p | 0.9–1.0 |

### 📝 Example — Hyperparameter Sweep
```python
for chunk_size in [256, 512, 1024]:
  for top_k in [10, 30, 50]:
    for top_n in [3, 5]:
      reindex(chunk_size)
      score = run_eval(top_k=top_k, top_n=top_n)
      log(chunk_size, top_k, top_n, score)
```
You'll usually find a clear winner; the difference between best and worst is often 15–20% absolute.

### 🎯 Interview Insight
Volunteer the *interaction* between hyperparameters: bigger chunks → smaller top-K is fine, smaller chunks → bigger top-K. Showing you reason about *systems* not isolated knobs is a senior signal.

---

## Q19: What are the popular frameworks to implement a RAG system? Justify your choice of framework.

### ✅ Answer
LangChain, LlamaIndex, and Haystack are the most popular frameworks for RAG implementation. LangChain is great for custom pipelines, and LlamaIndex is great for efficient document indexing and retrieval. The Haystack framework provides excellent modularity for building RAG systems.

I would recommend LangChain because of its comprehensive ecosystem, extensive documentation, active community support, and flexibility in handling various data sources and LLM integrations.

### 💡 In-depth Explanation
The honest landscape as of 2026:

| Framework | Strengths | Weaknesses |
|-----------|----------|-----------|
| **LangChain** | Huge ecosystem, every integration exists | Abstraction churn, opinionated |
| **LlamaIndex** | Best-in-class document/index abstractions | Smaller LLM-orchestration layer |
| **Haystack 2.x** | Clean pipeline graph model, production-grade | Smaller community |
| **DSPy** | Compile prompts/programs; signature-based | Steeper learning curve |
| **Roll-your-own** | Zero abstractions, full control | More glue code |

**Pragmatic take**: for a serious production RAG system, many teams now build a thin custom layer over a vector DB SDK + LLM SDK rather than depending on a large framework. Frameworks shine for prototyping and unusual integrations.

### 📝 Example
A 30-line "framework-free" RAG:
```python
import openai
from qdrant_client import QdrantClient

def rag(query):
    qv = openai.embeddings.create(input=query, model="text-embedding-3-large").data[0].embedding
    hits = qdrant.search(collection="docs", query_vector=qv, limit=5)
    context = "\n".join(f"[Doc {i}] {h.payload['text']}" for i, h in enumerate(hits))
    return openai.chat.completions.create(
        model="gpt-4o",
        messages=[
          {"role":"system","content":"Answer ONLY from Context."},
          {"role":"user","content": f"{context}\n\nQuestion: {query}"}
        ]).choices[0].message.content
```

### 🎯 Interview Insight
Avoid being a fanboy of one framework. Say *"I pick the lightest tool that solves my need"* — that's the experienced engineer's posture.

---

## Q20: Explain the influence of LLM context window size on RAG hyperparameters.

### ✅ Answer
The size of the LLM context window has a big impact on RAG hyperparameters, like chunk size and the number of chunks that are retrieved. Larger context windows let you feed more retrieved chunks to the LLM, which increases the chance of including more relevant information. This could make the quality of the generated answers better.

But after a certain point, performance gains start to go down because of problems like "lost in the middle" and higher latency.

### 💡 In-depth Explanation
The interaction:

- **Small context (8K)** — must use small chunks (~256) and small top-N (~3–5). Demands strong retrieval.
- **Medium context (32–128K)** — comfortable middle ground. Top-N 10–15 with 500-token chunks.
- **Long context (200K–1M)** — you *can* stuff 50+ chunks, but quality plateaus then degrades due to lost-in-the-middle.

A useful constraint to compute: `top_N × chunk_size < 0.3 × context_window`. Leave the other 70% for instructions, conversation history, and the answer.

### 📝 Example
For Anthropic Sonnet 4.6 (1M context) on legal Q&A:
```
Budget        : 1,000,000 tokens
Reserve       :   200,000  ← system prompt + history + answer
Available     :   800,000
With 1K chunks: 800 chunks max, but quality plateaus around top-30
Optimal       : top_N=20, chunk_size=1000  (≈20K tokens of context)
```
Going beyond top-30 hurt accuracy in our eval.

### 🎯 Interview Insight
Mention "lost-in-the-middle" by name — it shows you've read Liu et al. 2023 and you know context is not free.

---

## Q21: How do you choose values for various LLM inference hyperparameters in a RAG system?

### ✅ Answer
Temperature controls randomness—lower values give more focused and deterministic responses suitable for technical or precise tasks, while higher values make output more creative and diverse.

The max tokens limit the length of the output, making sure that the answers are short or long enough depending on the use case, with a trade-off between completeness and latency. Optimal settings depend on the specific application context and are found through iterative experimentation.

### 💡 In-depth Explanation
For RAG specifically (where grounding matters), defaults that work:

| Param | Default | Why |
|-------|---------|-----|
| temperature | 0.0–0.2 | RAG = factual extraction. Randomness invents. |
| top_p | 0.9 | Mostly redundant if temperature is low |
| max_tokens | 512 | Set tight to avoid runaway answers |
| stop sequences | `\n\nQ:` etc. | Prevent the model from continuing past the answer |
| presence_penalty | 0 | Don't push the model to introduce new tokens |
| frequency_penalty | 0 | Same |

When users want **creative** generations from a RAG system (marketing copy grounded in product facts), you might bump temperature to 0.5–0.7. But default to determinism.

### 📝 Example
```python
response = openai.chat.completions.create(
    model="gpt-4o",
    messages=[...],
    temperature=0.1,         # near-deterministic
    max_tokens=512,
    stop=["\n\nUser:", "\n\nQuestion:"]
)
```

### 🎯 Interview Insight
Have a one-liner ready: *"For RAG, I default to temperature ≈ 0 because we're doing extractive QA, not creative writing."* Clean and memorable.

---
