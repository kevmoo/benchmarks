# Multi-Language Benchmark Results & Hardware Methodology

## 📌 Executive Context & Upstream Attribution

This document records local benchmark metrics and relative performance comparisons executed against the canonical **[`kostya/benchmarks`](https://github.com/kostya/benchmarks)** open-source macro benchmark suite.

All results in this document were compiled and run directly on a single Linux development workstation (`kevmoo.c.googlers.com`) under identical system load to guarantee hardware, kernel, and memory bus consistency across all language implementations.

---

## 🖥️ Benchmark Host Environment & Hardware Specifications

For complete transparency and reproducibility, all benchmarks were executed on the following host environment:

* **Host Identifier**: `kevmoo.c.googlers.com`
* **Operating System**: Google gLinux (`Debian GNU/Linux rodete`)
* **Kernel**: `Linux 6.18.14-1rodete4-amd64` (x86_64)
* **CPU**: **AMD EPYC 7B13** (Zen 3 Architecture)
  * **vCPUs**: 64 logical CPUs (32 physical cores, 2 threads/core)
  * **L3 Cache**: 128 MiB total
  * **Instruction Extensions**: AVX, AVX2, FMA3, AES-NI, BMI1/2, CLFLUSHOPT
* **System Memory (RAM)**: **117.3 GiB** (~126 GB) DDR4 RAM
* **Measurement Daemon**: `xtime.rb` (Monotonic clock nanoseconds & `/proc/<pid>/statm` RSS memory sampling via TCP socket `localhost:9001`)

---

## 📊 1. JSON Benchmark (Decode / Deserialization)

### Workload Definition
* **Operation**: **JSON Parsing & Object Construction (Decode)**.
* **Payload**: **110.2 MB** synthetic coordinate payload (`/tmp/1.json`) containing **524,288 coordinate point objects**, generated via `ruby generate_json.rb`.
* **Execution Flow**: Each implementation reads `/tmp/1.json`, parses the JSON string into memory (AST or typed struct), iterates over all 524,288 points, calculates average $x$, $y$, $z$ spatial coordinates, verifies correctness, and reports socket timing.

### 13-Contestant JSON Leaderboard

| Rank | Implementation | Architecture / Library | Time (s) | Throughput (MB/s) | Peak RSS (MB) | Slowdown vs 1st |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: |
| 🥇 1 | **C++ (`simdjson` On-Demand)** | C++ SIMD Zero-Copy Token Stream | **0.102 s** | **1,078 MB/s** | 173.9 MB | **1.0x** (Baseline) |
| 🥈 2 | **Rust (`serde_json` Stream)** | Rust Zero-Copy Pull Reader | **0.164 s** | **670 MB/s** | 111.0 MB | **1.6x** |
| 🥉 3 | **Rust (`serde_json` Typed Struct)** | Rust Typed Zero-Allocation Struct | **0.169 s** | **650 MB/s** | 123.0 MB | **1.7x** |
| 4 | **C++ (`gason`)** | C++ In-Place Arena Parser | **0.194 s** | **567 MB/s** | 210.6 MB | **1.9x** |
| 5 | **C++ (`simdjson` DOM)** | C++ SIMD Full Tree Builder | **0.219 s** | **502 MB/s** | 290.8 MB | **2.1x** |
| 6 | **C++ (`RapidJSON`)** | C++ Standard DOM Parser | **0.251 s** | **438 MB/s** | 242.6 MB | **2.5x** |
| 7 | **Node.js (24.19 V8 C++)** | V8 C++ Engine `JSON.parse` | **0.533 s** | **206 MB/s** | 446.0 MB | **5.2x** |
| 8 | **Go (`jsoniter`)** | Go Code-Gen Streaming Reader | **0.721 s** | **152 MB/s** | 116.9 MB | **7.1x** |
| 9 | **Rust (`serde_json::Value` Untyped)** | Rust Dynamic AST Heap Map | **1.076 s** | **102 MB/s** | 951.0 MB | **10.5x** |
| 10 | **CPython (3.12)** | C-extension `json.loads` | **1.275 s** | **86 MB/s** | 448.9 MB | **12.5x** |
| 11 | **Go (`encoding/json`)** | Standard Go Reflection Unmarshaler | **1.351 s** | **81 MB/s** | 116.6 MB | **13.2x** |
| 12 | **Dart AOT (`3.14 dev`)** | `dart:convert` AOT (`jsonDecode`) | **1.352 s** | **81 MB/s** | 551.4 MB | **13.3x** |
| 13 | **Ruby (3.2 / YJIT)** | C-extension `JSON.parse` | **1.980 s** | **55 MB/s** | 343.0 MB | **19.4x** |

### Key Technical Insights
1. **Rust Typed Struct Deserialization (`0.169 s` / `650 MB/s`)**:
   * **8.0x faster** than Dart AOT and Go standard library.
   * `serde_json` populates fixed struct memory on the stack, incurring zero heap allocations during parsing.
2. **Node.js V8 C++ Engine (`0.533 s` / `206 MB/s`)**:
   * **2.5x faster** than Dart AOT.
   * Node delegates `JSON.parse` directly to V8's native C++ scanner.
3. **Untyped AST Cost (Rust `serde_json::Value` at `1.076 s`)**:
   * When Rust builds generic heap `Map` objects, execution drops from 0.16s to 1.07s.
   * Confirms dynamic heap object allocation is the primary bottleneck in Dart `dart:convert`.

---

## 🔤 2. Base64 Benchmark (Encode & Decode)

### Workload Definition
* **Operation**: **Combined Base64 String Encoding & Decoding**.
* **Payload**: **128 KB string** repeated across **8,192 iterations** (~1.0 GB throughput volume).

### Base64 Results

| Implementation | Runtime / Flags | Time (s) | Peak RSS (MB) |
| :--- | :--- | :---: | :---: |
| **Dart AOT (`3.14 dev`)** | `dart compile exe` (`base64.encode` / `base64.decode`) | **8.321 s** | **15.1 MB** |

---

## 🔢 3. Matmul Benchmark (Matrix Multiplication)

### Workload Definition
* **Operation**: **Dense Double-Precision Matrix Multiplication ($C = A \times B^T$)**.
* **Payload**: **$1500 \times 1500$ double-precision matrix** initialized with deterministic seeds ($A=1.0, B=2.0$). Transposes matrix $B$ for optimal cache line locality before computing $1500^3$ scalar dot products.

### Matmul Results

| Rank | Implementation | Compiler / Runtime | Time (s) | Peak RSS (MB) | Slowdown vs 1st |
| :---: | :--- | :--- | :---: | :---: | :---: |
| 🥇 1 | **C (`gcc`)** | `gcc -O3 -march=native` | **3.162 s** | 70.0 MB | **1.0x** (Baseline) |
| 🥈 2 | **Dart AOT (`3.14 dev`)** | `dart compile exe` (`Float64List`) | **4.411 s** | 80.0 MB | **1.39x** |

**Takeaway**: Dart AOT's SIMD optimizations on `Float64List` contiguous memory arrays achieve performance within **1.39x of native `gcc -O3`** on raw matrix multiplication!
