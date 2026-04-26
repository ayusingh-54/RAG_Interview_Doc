#!/usr/bin/env bash
# Builds RAG_Interview_Master_Guide.html from the master markdown file.
# Open the resulting HTML in any browser, then File → Print → Save as PDF.

set -euo pipefail
cd "$(dirname "$0")"

cat > RAG_Interview_Master_Guide.html <<'HTML_HEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>RAG Interview Questions &amp; Answers — Complete Study Guide</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css@5.5.1/github-markdown-light.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
<style>
  :root { --accent: #0b5ed7; --soft: #f4f7fb; --line: #e5e9f0; }
  body{ box-sizing: border-box; margin: 0; padding: 36px 48px; max-width: 920px; margin: 0 auto;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
        color: #1f2328; background: #ffffff; }
  .markdown-body { font-size: 15.5px; line-height: 1.65; }
  .markdown-body h1 { color: var(--accent); border-bottom: 2px solid var(--accent); padding-bottom: 6px; }
  .markdown-body h2 { color: #134074; margin-top: 2.2em; padding-top: .3em; }
  .markdown-body h3 { color: #2b6cb0; margin-top: 1.6em; }
  .markdown-body blockquote { background: var(--soft); border-left-color: var(--accent); }
  .markdown-body table { display: table; width: 100%; }
  .markdown-body code { background: #f3f4f6; }
  .markdown-body pre { background: #f6f8fa; border-radius: 6px; }
  hr { border: none; border-top: 1px solid var(--line); margin: 1.6em 0; }
  /* Make every Q heading start on a fresh line in print to keep them readable */
  @media print {
    body { padding: 0; }
    .markdown-body h1 { page-break-before: always; }
    .markdown-body h2 { page-break-before: auto; page-break-after: avoid; }
    .markdown-body h3 { page-break-after: avoid; }
    .markdown-body pre, .markdown-body table, .markdown-body blockquote { page-break-inside: avoid; }
  }
  #toc-jump { position: fixed; top: 12px; right: 12px; background: var(--accent); color: #fff;
              padding: 8px 14px; border-radius: 18px; font: 600 13px system-ui; text-decoration: none;
              box-shadow: 0 2px 8px rgba(0,0,0,.15); z-index: 50; }
  #toc-jump:hover { background: #084298; }
  @media print { #toc-jump { display: none; } }
  #status { padding: 16px; color: #555; font: 14px system-ui; }
</style>
</head>
<body>
<a id="toc-jump" href="#table-of-contents">↑ TOC</a>
<div id="status">Rendering… (large doc, give it a moment)</div>
<article id="content" class="markdown-body"></article>

<script type="text/markdown" id="md">
HTML_HEAD

cat RAG_Interview_Master_Guide.md >> RAG_Interview_Master_Guide.html

cat >> RAG_Interview_Master_Guide.html <<'HTML_TAIL'
</script>

<script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/autoloader/prism-autoloader.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
<script>
(function() {
  var md = document.getElementById('md').textContent;
  marked.setOptions({
    gfm: true, breaks: false, headerIds: true,
    highlight: function(code, lang) {
      if (window.Prism && lang && Prism.languages[lang]) {
        try { return Prism.highlight(code, Prism.languages[lang], lang); } catch(e) {}
      }
      return code;
    }
  });
  var html = marked.parse(md);
  // Anchor-friendly id for the TOC heading
  html = html.replace(/<h2[^>]*>Table of Contents<\/h2>/i, '<h2 id="table-of-contents">Table of Contents</h2>');
  document.getElementById('content').innerHTML = html;
  document.getElementById('status').remove();

  // Math rendering (the doc has a few $...$ and $$...$$ snippets)
  if (window.renderMathInElement) {
    renderMathInElement(document.getElementById('content'), {
      delimiters: [
        {left: '$$', right: '$$', display: true},
        {left: '$',  right: '$',  display: false}
      ],
      throwOnError: false
    });
  }
})();
</script>
</body>
</html>
HTML_TAIL

echo "Built: $(pwd)/RAG_Interview_Master_Guide.html"
ls -la RAG_Interview_Master_Guide.html
