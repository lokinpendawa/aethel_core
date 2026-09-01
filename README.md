# Aethel-Core: Automated Cognitive Defense & Cyber Threat Simulation Dataset

A high-fidelity, high-velocity synthetic dataset optimized for **LLM Instruction Tuning**, **Chain-of-Thought (CoT) Benchmarking**, and **Neuro-Symbolic AI Training**. This dataset simulates complex automated cyber threat scenarios evaluated through a dynamic Truth Maintenance System (TMS) engine built in SWI-Prolog.

---

## Engine Benchmark & Performance Report

The dataset was generated under a high-stress fuzzing simulation to test the limits of cognitive reasoning in memory storage. Below is the official system state audit log:

| Metric Parameter | Benchmark Result |
| :--- | :--- |
| **Total Inferences Executed** | 200,036,384 logical steps |
| **CPU Computation Duration** | 72.844 seconds |
| **Peak Inference Speed** | **2,731,929 LIPS** (Logical Inferences Per Second) |
| **Volatile RAM Footprint** | ~110 KB (Ultra-lightweight state) |
| **Garbage Collection (GC) Cost** | 0.000 seconds (Optimal lifecycle management) |

---

## Dataset Schema & High-Fidelity Structure

The exported file is formatted in standard `.jsonl` (JSON Lines) to support high-scale machine learning streaming pipelines. Each record forms a perfect `prompt-response` pair for instructions tuning:

### JSONL Sample Instance
```json
{
  "prompt": {
    "instruction": "Analyze the following network security telemetry, execute abductive-deductive reasoning, and determine the mitigation verdict.",
    "attacker_ip": "72.204.144.56",
    "anomaly_vector": "zero_day_exploit",
    "threat_description": "Kernel-Space Zero-Day Payload Exploit Attempt"
  },
  "response": {
    "deductive_verdict_status": "ABSOLUTE VERIFIED",
    "hardware_kernel_mitigation_action": "BLOCKED_AND_ISOLATED",
    "processing_speed_ms": 4.3208599
  }
}
```

---

## Cyber Threat Mutation Matrix

The simulation fuzzer covers 4 core vertical domains of advanced cyber security threats:
1. **Layer-7 Traffic Flooding**: Traffic volume spike breaching application-layer velocity thresholds.
2. **Kernel-Space Zero-Day Exploit**: Injection of unpatched raw memory/buffer manipulation vectors.
3. **Session Hijacking**: Unauthorized authorization token theft and active session intervention.
4. **Bypass Attempt**: Deceptive subversion tactics attempting to forge false override signals to defeat firewall rules.

---

## Target Research Value
This dataset provides a rare solution to **The Data Scarcity Problem** in cyber security research, where real-world attack logs cannot be shared due to strict privacy regulations (GDPR / Corporate NDAs). It serves as a rigorous playground to train LLMs to master complex conditional subversion logic (Truth Maintenance System) without experiencing hallucinations.
