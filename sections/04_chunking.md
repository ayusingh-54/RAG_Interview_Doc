# Part V — Chunking Strategies (Q31–Q37)

---

## Q31: What are the different chunk enhancement techniques in RAG?

### ✅ Answer
The different chunk enhancement techniques in RAG are HyPE, Contextual Chunk Header, and Document Augmentation.

- HyPE (Hypothetical Prompt Embedding) precomputes hypothetical questions for each document chunk at indexing time, enabling retrieval by question-to-question matching, which improves semantic alignment and retrieval accuracy without adding query-time latency.
- Contextual Chunk Header adds relevant contextual information such as document titles or section headings to each chunk before embedding, helping retrieval models understand and rank chunks better when chunk text alone is ambiguous.
- Document Augmentation enhances chunks by including additional metadata and enhances retrieval quality.

### 💡 In-depth Explanation
A fuller catalog used in production:

| Technique | What it adds to each chunk | Effect |
|-----------|---------------------------|--------|
| **Contextual Chunk Header** | Doc title + section path | Chunk knows where it lives |
| **HyPE** | LLM-generated hypothetical questions | Question-to-question matching |
| **Anthropic-style Contextual Retrieval** | A 1-sentence LLM summary describing the chunk in the context of the whole doc | 49% retrieval-error reduction reported |
| **Summary prefix** | LLM-generated 1-line summary of the chunk | Boosts dense match for paraphrase queries |
| **Metadata enrichment** | source, date, author, tags | Enables filters, recency boosting |
| **Parent-child / hierarchical chunks** | Small chunk for retrieval, large parent for context | Best of both granularities |
| **Cross-references** | Links to related chunks | Supports multi-hop retrieval |

### 📝 Example — Anthropic-style Contextual Retrieval
```
Original chunk: "Returns must be initiated within 30 days of receipt."

Augmented chunk: "From the Acme 2026 Customer Returns Policy, Section 3.2 (Digital Goods): Returns must be initiated within 30 days of receipt."
```
The augmented version embeds with much richer context, making it findable for queries like *"What's the digital goods return window?"*

### 🎯 Interview Insight
Mention Anthropic's **Contextual Retrieval** technique by name — it's well-known in 2025–2026 RAG literature and showing awareness scores points.

---

## Q32: What are the pros and cons of chunk enhancement techniques in RAG?

### ✅ Answer
Chunk enhancement techniques in RAG, such as HyPE, Contextual Chunk Header, and Document Augmentation, improve retrieval accuracy by enhancing semantic alignment, preserving context, and bridging query-document chunk gaps, leading to better generation performance.

HyPE boosts relevance through precomputed question embeddings without query-time latency, Contextual Chunk Header clarifies ambiguous chunks with document or section titles, and Document Augmentation enriches chunks with additional metadata.

However, these methods increase indexing complexity and storage requirements, potentially raising computational costs. Balancing enhanced retrieval quality with resource demands is a key consideration.

### 💡 In-depth Explanation
| Aspect | Pro | Con |
|--------|-----|-----|
| Retrieval quality | +5–50% on benchmarks | Diminishing returns past 2–3 enhancements |
| Indexing cost | One-time | Adds LLM calls (HyPE) or compute (summaries) |
| Storage | Often ~1.5–3× more vectors | Linear cost on large corpora |
| Reindex on update | Must regenerate enhancements | Slower iteration |
| Debuggability | Clearer "why this matched" | Pipeline complexity grows |

The right enhancement is the one that fixes *your* failure mode. Use eval data to tell you which: low recall on factoid queries → HyPE; chunks lacking context → Contextual Chunk Header; queries about recent events → metadata-based recency boost.

### 📝 Example — Cost Math
50K chunks × 1 LLM call to generate 5 hypothetical questions @ Haiku ($0.0008 per call) = **$40 one-time**. For most teams, that's trivial vs. the retrieval-quality gain.

### 🎯 Interview Insight
Frame chunk enhancement as **"buying retrieval quality with indexing-time compute."** It's a classic latency-vs-quality trade where you push work to offline.

---

## Q33: Explain how the contextual chunk header technique enhances RAG retrieval.

### ✅ Answer
The Contextual Chunk Header technique in RAG enhances retrieval by adding document titles, section headings, or summaries to each chunk before embedding, providing critical context that clarifies ambiguous or isolated chunk content.

This additional information helps the retrieval model better understand the chunk’s relevance to a query, improving semantic alignment and ranking accuracy.

### 💡 In-depth Explanation
A bare chunk often loses crucial context: "Step 3: Click 'Confirm Cancellation'." Without the surrounding context, this chunk could match almost any cancellation query. Prefixing it with the doc + section path makes it specific:

> *"[Acme Help Center → How to cancel a subscription → Step 3] Click 'Confirm Cancellation'."*

Now the chunk's embedding encodes "subscription cancellation" without relying on the body text. This is especially valuable for instructional/how-to docs where steps share generic vocabulary.

### 📝 Example
```python
def add_header(chunk, doc_title, section_path):
    return f"[{doc_title} > {' > '.join(section_path)}]\n\n{chunk}"

# Before
"Returns must be initiated within 30 days."

# After
"[Acme Returns Policy > Digital Goods > 3.2 Eligibility]\n\nReturns must be initiated within 30 days."
```
Critically: include the header *only at embedding time*. When you pass the chunk to the LLM, the header can be metadata, not necessarily part of the prompt body.

### 🎯 Interview Insight
A favorite follow-up: *"How do you generate section paths from PDFs?"* Honest answer: parse with `unstructured.io` or `pdfplumber` to get heading hierarchy. For HTML/Markdown, it's free.

---

## Q34: What are some common chunking methods used in RAG?

### ✅ Answer
Common chunking methods used in RAG are fixed-size chunking, recursive chunking, semantic chunking, and agentic chunking.

- Fixed-size chunking divides text into uniform segments based on a predefined token or character length, often incorporating overlap to maintain context.
- Recursive chunking iteratively splits text using natural separators like paragraphs or sentences to preserve logical boundaries. Semantic chunking groups text based on semantic similarity using embeddings, creating coherent, meaning-based chunks.
- Agentic chunking leverages AI agents to dynamically segment text into task-oriented, semantically coherent chunks, often with metadata to enhance retrieval relevance.

### 💡 In-depth Explanation
A practical comparison:

| Method | How it works | Speed | Quality | When to use |
|--------|-------------|------:|--------:|------------|
| **Fixed-size** | Every N tokens | ⚡⚡⚡⚡ | ⭐⭐ | Logs, transcripts, uniform text |
| **Recursive** | Splits on `\n\n` → `\n` → `.` → ... | ⚡⚡⚡ | ⭐⭐⭐ | Default for most prose |
| **Markdown / structure-aware** | Split on `##`, `<section>`, etc. | ⚡⚡⚡ | ⭐⭐⭐⭐ | Docs with clean structure |
| **Semantic** | Split where embedding similarity drops | ⚡ | ⭐⭐⭐⭐ | Narrative with topic shifts |
| **Agentic** | LLM decides boundaries | (slow) | ⭐⭐⭐⭐⭐ | High-value, complex docs |
| **Token-window over sentences** | Sentence-aware fixed length | ⚡⚡⚡ | ⭐⭐⭐ | Compromise of quality+speed |

### 📝 Example — Recursive Chunking (LangChain)
```python
from langchain.text_splitter import RecursiveCharacterTextSplitter
splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=50,
    separators=["\n\n", "\n", ". ", " ", ""]  # try in order
)
chunks = splitter.split_text(doc)
```
The splitter prefers splitting at paragraph breaks, falling back to smaller separators only if needed.

### 🎯 Interview Insight
Don't recommend semantic chunking by default. It's *expensive* and only wins on long-form narrative docs. For most corpora, recursive or markdown-aware chunking is the better cost/quality ratio.

---

## Q35: What are the criteria to choose a specific chunking method in RAG?

### ✅ Answer
The criteria for choosing a specific chunking method in RAG include the nature and structure of the source documents, capabilities of the embedding model, and the specific task or application needs.

For structured or well-formatted data, semantic or agentic chunking ensures logical boundaries and context preservation. The chunk size must balance between being large enough to capture meaningful context and small enough to fit within model constraints for efficient processing.

Task specificity matters since complex tasks may require semantic or agentic chunking for better context and relevance, while simpler cases can use fixed-size chunking.

Ultimately, the chunking method should balance retrieval relevance, context completeness, and computational efficiency.

### 💡 In-depth Explanation
A decision tree I use:

```
Does the doc have natural structure (markdown, HTML, code)?
 ├─ Yes → structure-aware split
 └─ No  → Is it narrative/long-form?
          ├─ Yes → recursive (default) or semantic (if budget)
          └─ No  → fixed-size with overlap
```

Override factors:
- **Tables/figures present** → element-aware chunking; never chop a table.
- **Code corpora** → split on function/class boundaries (tree-sitter).
- **Domain has rigid structure (legal, medical)** → custom splitter that respects that structure.
- **Budget is tight** → fixed-size, period.

### 📝 Example
For a regulatory filings corpus:
- ❌ Fixed-size: chops in the middle of "Risk Factor 1.2"
- ✓ Custom regex on `^Item \d+\.\d+`: every chunk = one risk factor; clean retrieval.

### 🎯 Interview Insight
Show willingness to write **custom splitters** for important domains. The framework defaults are starting points, not endpoints.

---

## Q36: Explain the pros and cons of semantic chunking.

### ✅ Answer
Semantic chunking groups text based on meaning, creating coherent chunks that enhance retrieval relevance and context preservation.

Pros: It aligns chunks with natural topic shifts, improving the quality of retrieved content for complex queries, and reduces information loss across boundaries.

Cons: It is computationally intensive, requiring embedding models. Additionally, it may struggle with highly complex or poorly structured documents where semantic boundaries are unclear.

### 💡 In-depth Explanation
Mechanics: split into sentences → embed each → walk forward, merging sentences while consecutive embedding similarity is high; cut when similarity drops below a threshold (e.g., when cosine drops > 0.4 from baseline).

| Pro | Con |
|-----|-----|
| Topical coherence per chunk | 5–20× slower than recursive |
| Better long-form quality | Embedding model cost at index time |
| Adaptive chunk lengths | Hyperparameter (threshold) is finicky |
| Reduces "topic-bleed" | Can produce wildly variable chunk sizes |

Use it for: long-form articles, books, research papers. Avoid for: FAQs, structured docs, code.

### 📝 Example — Pseudocode
```python
def semantic_chunk(sentences, threshold=0.7):
    embs = [embed(s) for s in sentences]
    chunks, current = [], [sentences[0]]
    for i in range(1, len(sentences)):
        if cosine(embs[i], embs[i-1]) < threshold:
            chunks.append(" ".join(current)); current = []
        current.append(sentences[i])
    chunks.append(" ".join(current))
    return chunks
```
Threshold tuning matters; build a small eval and sweep [0.5, 0.6, 0.7, 0.8].

### 🎯 Interview Insight
A real-world finding to drop: *"In our benchmarks, semantic chunking gave +3-5% on long-form QA but added 10× indexing time. We used it only on our highest-value corpora."* Specifics impress.

---

## Q37: How does the chunking strategy differ when dealing with structured documents (like PDFs with tables and figures) versus plain text documents?

### ✅ Answer
Chunking strategies for structured documents like PDFs with tables and figures differ significantly from plain text chunking due to the need to preserve complex layouts and relationships. For structured documents, the chunking strategy must respect document elements such as tables, figures, headers, and pages to maintain context and semantic meaning.

Agentic and recursive chunking are more suitable for structured documents due to their flexibility in respecting structure and context. Fixed-size and semantic chunking are often better suited for plain text documents where semantic coherence and simplicity are prioritized.

### 💡 In-depth Explanation
Strategy by content type:

| Element | Strategy |
|---------|----------|
| **Headers** | Use as chunk boundary AND prepend to each chunk underneath |
| **Tables** | Keep as one atomic chunk; convert to markdown for embedding; consider an LLM-generated summary for retrieval |
| **Figures** | Embed caption + nearby text; for charts, OCR + describe with VLM |
| **Lists** | Don't split mid-list if possible |
| **Code blocks** | One chunk per block (function/class); preserve language tag |
| **Footnotes / sidenotes** | Inline into the main chunk OR keep as metadata |

Tools that get this right: `unstructured.io`, `LlamaParse`, `Docling`. They emit a structured stream of elements (Title, NarrativeText, Table, FigureCaption, ...) you can chunk intelligently.

### 📝 Example — PDF with a Table
A 10-K filing chunk that includes a revenue table:
```
[Section: Q4 2025 Revenue Breakdown]

| Segment   | Q4 Revenue ($M) | YoY  |
|-----------|----------------:|-----:|
| Cloud     |             420 |+18%  |
| Hardware  |             285 |+3%   |
| Services  |             140 |+9%   |

Cloud led growth driven by enterprise migrations...
```
Embedding includes the section header + the markdown table + 2-3 sentences of surrounding prose. Don't ever bisect the table.

### 🎯 Interview Insight
Mention you'd run a **table-aware extraction pipeline** (LlamaParse / unstructured) first, *before* chunking. This is the single biggest quality lever for PDF-heavy corpora.

---
