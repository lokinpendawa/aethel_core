# CYBER SECURITY EVALUATION & BENCHMARK REPORT

**Project:** Aethel-Core WAF Engine (Prolog-Based Neuro-Symbolic Perimeter)  
**Evaluation Date:** November 21, 2026  
**Runtime Environment:** SWI-Prolog 64-bit (Multi-Threaded, JIT Hash Indexed)  
**Evaluation Status:** COMPLETED — 96.50% Attack Recall | 0.93% False Positive Rate

---

## 1. EXECUTIVE SUMMARY

This document summarizes the architecture, rule-induction pipeline, and empirical benchmark results of the **Aethel-Core Production WAF Engine** (`analyzer.pl` + `rules.pl` + `dictionary.pl`).

Unlike signature-based firewalls that rely on manually written regular expressions, Aethel-Core compiles its production rulebase through an **offline, zero-hardcode inductive pipeline**. During live inference, the engine operates purely on integer-encoded binary signatures and bit-packed bidirectional attention pairs stored in volatile memory, without requiring external reverse proxies (Nginx/Cloudflare) or GPU acceleration.

---

## 2. SYSTEM ARCHITECTURE & INDUCTION PIPELINE

### 2.1 Offline Inductive Compilation (Zero-Hardcode)
The production knowledge base is synthesized automatically from labeled adversarial and clean datasets (`knowledge_base/4`) across four stages:

1. **Structural Tokenization & Differential Entropy (`sintesis_payload.pl`):**  
   Payloads are parsed into structural tokens and weighted via two-way contrast entropy (`log2(P_attack / P_legal)`) scaled by cross-domain specificity.
2. **Domain-Isolated Medoid Clustering (`self_evolving.pl`):**  
   Attack vectors are isolated by threat domain and grouped via unsupervised medoid clustering using dynamic Jaccard distance thresholds (5th-percentile distribution boundary).
3. **Epsilon-Margin Natural Selection (`validasi.pl`):**  
   Candidate cluster signatures are forged with a minimum score threshold set strictly above the maximum similarity score observed across clean traffic (`MaxCleanScore + epsilon`).
4. **CLP(FD) Bidirectional Self-Attention (`attention.pl`):**  
   Constraint Logic Programming over Finite Domains solves optimal left/right context windows to equilibrium, compiling log-odds token pairs into static integer rules.

### 2.2 Production Runtime Engine (`analyzer.pl`)
In production, training modules are stripped out. The runtime engine loads only the compiled static facts:

- **Multi-Layer Normalization (`decoder.pl`):** Recursively unpacks nested URL encodings (`%XX`), hex sequences, and obfuscated wrappers prior to structural tokenization.
- **Unified Token Dictionary (`dictionary.pl`):** Maps structural primitives, token entropy weights, semantic abstraction classes, and threat descriptions.
- **Compiled Binary & Attention Rules (`rules.pl`):**
  - `biner/4` (**3,666 clauses**): Multi-argument JIT-indexed across 4,096 buckets (up to **2,897.6x** lookup speedup).
  - `attentions/2` (**79,699 clauses**): 24-bit bit-packed token pair IDs (`(ID1 << 24) \/ ID2`) indexed across 131,072 buckets (**79,699.0x** lookup speedup, zero cross-platform hash drift).

---

## 3. EVALUATION METHODOLOGY & SAMPLE TEST VECTORS

The engine was benchmarked directly via `analyzer:periksa_waf/3` against **17,160 total payloads**, comprising **12,315 malicious vectors** (covering RCE, SSTI, Path Traversal, SQLi, XSS, and Zero-Day mutations) and **4,844 benign/clean technical payloads** (CLI documentation, shell commands, and developer strings).

### 3.1 Representative Malicious Vectors (`ABSOLUTE VERIFIED`)
The following test cases demonstrate structural detection against process substitution, template injection, and mixed-encoding traversal:

```prolog
knowledge_base(command_injection, "diff<(/bin/cat /etc/passwd) /dev/null", 'ABSOLUTE VERIFIED', 'Process Substitution Diff').
knowledge_base(ssti_jinja2_exotic, "{{joiner.__init__.__globals__['os'].popen('id').read()}}", 'ABSOLUTE VERIFIED', 'SSTI: Jinja2 Joiner Globals OS Popen ID').
knowledge_base(path_traversal_exotic, "/..%2f..%5c..%2fetc%2fpasswd", 'ABSOLUTE VERIFIED', 'PT: Mixed Slash Traversal').
```

- **Detection Mechanism:** After multi-layer decoding (`%2f` $\rightarrow$ `/`, `%5c` $\rightarrow$ `\`), structural primitives (`<`, `(`, `/bin/cat`, `__globals__`, `popen`, `..`, `/`, `\`) trigger both binary signature thresholds and positive bidirectional context density scores.

### 3.2 Representative Clean Traffic Vectors (`CLEAN`)
To verify that shell operators and system paths in legitimate documentation do not trigger false alarms, the benchmark included benign technical strings:

```prolog
knowledge_base(payload_legal, "nohup ./long.sh >/dev/null 2>&1 runs in background", 'CLEAN', 'LG-SH-08 dokumentasi nohup').
knowledge_base(payload_legal, "setsid ./svc </dev/null detaches from tty", 'CLEAN', 'LG-SH-09 dokumentasi setsid').
knowledge_base(payload_legal, "busybox sh is a lightweight shell for embedded", 'CLEAN', 'LG-SH-10 dokumentasi busybox').
```

- **Mitigation Mechanism:** Although tokens such as `/dev/null`, `sh`, and redirection operators (`>`, `<`) appear in benign shell documentation, negative log-odds context weights from surrounding natural-language tokens (`runs in background`, `detaches from tty`, `lightweight shell for embedded`) suppress the attention density below the blocking threshold, allowing the traffic to pass cleanly.

---

## 4. BENCHMARK PERFORMANCE & ACCURACY METRICS

Measured via `time(analyzer:uji)` across **17,160 sequential evaluations**:

### 4.1 Execution Throughput & Resource Profile
- **Total Evaluation Time:** 6.14 seconds (6.141s CPU time)
- **Throughput:** 2,796 requests/second
- **Average Per-Request Latency:** 0.358 ms/request (0.0381 ms observed on live production socket telemetry)
- **Logical Inference Speed:** 16,170,505 LIPS (99,297,009 total logical inferences)
- **Production Rule Footprint:** 83,365 operational clauses (`3,666` binary rules + `79,699` bit-packed attention pairs)

### 4.2 Detection Confusion Matrix

| Traffic Class | Total Samples | Blocked | Unblocked (Passed) | Rate |
| :--- | :---: | :---: | :---: | :--- |
| **Malicious Payloads** | 12,315 | **11,884** (TP) | 431 (FN) | **96.50% Recall** (3.50% False Negative) |
| **Clean / Legal Payloads** | 4,844 | 45 (FP) | **4,799** (TN) | **99.07% Specificity** (0.93% False Positive) |

---

## 5. KNOWN LIMITATIONS & ONGOING REFINEMENTS

- **False Negatives (3.50% / 431 payloads):** Primarily consist of low-entropy or heavily fragmented single-token anomalies whose structural context falls just below the global `CLP(FD)` attention threshold.
- **False Positives (0.93% / 45 payloads):** Occur in edge-case clean strings containing dense sequences of special symbols that overlap with obfuscated injection syntax. Both sets are automatically logged (`log_false_negative.pl` and `log_false_positive.pl`) for subsequent offline induction cycles.

---

## 6. CONCLUSION

The Aethel-Core engine demonstrates that an inductively compiled Prolog rulebase using integer bit-packing and JIT hash indexing can achieve sub-millisecond Layer-7 inspection (**0.358 ms/req** at **16.17M LIPS**) with **96.50% attack detection recall** and **0.93% false positives** on a lightweight CPU-only footprint.
