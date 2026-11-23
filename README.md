# Aethel-Core: Neuro-Symbolic WAF & Autonomous Logic Induction Engine

A lightweight Web Application Firewall (WAF) and inductive rule-synthesis framework built in **SWI-Prolog**. Aethel-Core compiles zero-hardcode security rules from raw traffic telemetry and executes sub-millisecond Layer-7 inspection directly over bare TCP/SSL sockets—with **zero GPU dependency** and **no upstream reverse proxy (Nginx/Cloudflare)**.

🔴 **Live Interactive Testbed:** **[https://prologwaf.site/](https://prologwaf.site/)**
*(Exposed directly on a bare-socket SWI-Prolog server running on a 2 vCPU / 1 GB RAM GCP instance. Feel free to submit adversarial payloads via the `/hackme` audit console or inspect live telemetry.)*

---

## 1. Architecture Overview

Aethel-Core separates **offline inductive learning** from **stateless/stateful production inference**:

### A. Offline Neuro-Symbolic Induction Pipeline
Instead of relying on manually written regular expressions, the rulebase is synthesized automatically from labeled adversarial and clean traffic (`knowledge_base/4`):

1. **Structural Tokenization & Differential Entropy (`sintesis_payload.pl`):**
   Decomposes payloads into structural AST/token primitives and weights them using two-way contrast entropy (`log2(P_attack / P_legal)`) scaled by cross-domain specificity.
2. **Domain-Isolated Medoid Clustering (`self_evolving.pl`):**
   Groups structural attack variants per threat domain using unsupervised medoid clustering with dynamic Jaccard distance thresholds.
3. **Epsilon-Margin Natural Selection (`validasi.pl`):**
   Forges candidate binary signatures with thresholds set strictly above the maximum similarity score observed across clean traffic (`MaxCleanScore + epsilon`).
4. **CLP(FD) Bidirectional Self-Attention (`attention.pl`):**
   Uses Constraint Logic Programming over Finite Domains to solve optimal left/right context windows to equilibrium, compiling log-odds token pairs into static integer rules.

### B. Production Runtime Engine (`analyzer.pl` + `rules.pl` + `dictionary.pl`)
In production, training modules are stripped out. The runtime engine loads only compiled static facts into volatile memory:

- **Multi-Layer Obfuscation Decoder (`decoder.pl`):** Recursively unpacks nested URL encodings (`%XX`), hex sequences, and obfuscated wrappers prior to tokenization.
- **Unified Token Dictionary (`dictionary.pl`):** Maps structural primitives, token entropy weights, semantic abstraction classes, and threat descriptions.
- **Bit-Packed Rulebase (`rules.pl`):**
  - `biner/4` (**~3,666 clauses**): Multi-argument JIT-indexed across 4,096 buckets (up to **~2,897x** lookup speedup).
  - `attentions/2` (**~79,699 clauses**): 24-bit bit-packed token pair IDs (`(ID1 << 24) \/ ID2`) indexed across 131,072 buckets (**~79,699x** lookup speedup, cross-platform deterministic).

---

## 2. Empirical Benchmark & Evaluation Summary

Evaluated directly via `analyzer:periksa_waf/3` against **17,160 payloads** (12,315 malicious vectors across RCE, SSTI, Path Traversal, SQLi, XSS, and Zero-Day mutations vs. 4,844 clean technical/CLI strings):

- **Total Operational Clauses:** ~83,365 clauses (`~3,666` binary signatures + `~79,699` bit-packed attention pairs)
- **Attack Detection Recall:** **96.50%** (11,884 blocked / 3.50% false negative)
- **Clean Traffic Specificity:** **99.07%** (4,799 passed / 0.93% false positive)
- **Evaluation Throughput:** **~2,796 requests/second** (`~0.358 ms/req` average; `~0.0381 ms` on live socket telemetry)
- **Logical Inference Speed:** **~16,170,505 LIPS** (~99.29M inferences in 6.14 seconds)

📄 Full audit details and sample test vectors are documented in [`CYBER_SECURITY_AUDIT_REPORT.md`](CYBER_SECURITY_AUDIT_REPORT.md).

---

## 3. Standalone Runtime Quickstart

To run `analyzer.pl` locally in SWI-Prolog (requires `analyzer.pl`, `rules.pl`, `dictionary.pl`, `tokenisasi_struktural.pl`, and `decoder.pl` in the working directory):

```bash
swipl analyzer.pl
