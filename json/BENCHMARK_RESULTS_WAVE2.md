# Kostya JSON Benchmark (`110 MB` `/tmp/1.json` — `524,288` Coordinates)

Verified post-remediation **Wave 2** results (`2026-09-20`) across **Apple M4 Pro (`macos_arm64`)** and **AMD Ryzen 9 PRO 8945HS (`linux_x86_64`)**.

All runs verify the exact reference coordinate averages:
- `x`: `-5.0014542303081384e-30`
- `y`: `5.0042300345697454e+30`
- `z`: `0.5000908023732762`

## Dual-Architecture Results (`macos_arm64` & `linux_x86_64`)

| Target / Implementation | Semantic Mode | `macos_arm64` Time (s) | `macos_arm64` Peak RSS (MiB) | `linux_x86_64` Time (s) | `linux_x86_64` Peak RSS (MiB) | Speedup vs Stock Dart AOT |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Rust (`serde_json` Borrowed/Struct)** | Hydrated `Vec<Coordinate>` | **`0.13 s`** | `124.2 MiB` | **`0.17 s`** | `134.9 MiB` | `4.85x` (`arm64`) / `5.71x` (`x64`) |
| **Dart `package:codable` (`test_codable_streaming_scalar.dart`)** | **Streaming Scalar [Native]** (`0` heap list) | **`0.23 s`** | **`124.7 MiB`** | **`0.27 s`** | **`119.1 MiB`** | **`2.74x` (`arm64`) / `3.59x` (`x64`)** |
| **Dart `package:codable` (`test_codable.dart`)** | **Hydrated `List<Coordinate>` [Native]** (`524,288` objects) | **`0.25 s`** | **`164.0 MiB`** | **`0.29 s`** | **`157.5 MiB`** | **`2.52x` (`arm64`) / `3.34x` (`x64`)** |
| **Node.js (`JSON.parse`)** | Untyped JS DOM | `0.36 s` | `518.6 MiB` | `0.48 s` | `561.5 MiB` | `1.75x` (`arm64`) / `2.02x` (`x64`) |
| **Go (`encoding/json`)** | Hydrated `[]Coordinate` | `0.54 s` | `149.2 MiB` | `0.70 s` | `145.6 MiB` | `1.17x` (`arm64`) / `1.39x` (`x64`) |
| **Dart Stock AOT (`test_aot.dart`)** | Untyped `Map<String, dynamic>` (`dart:convert`) | `0.63 s` | `562.2 MiB` | `0.97 s` | `553.8 MiB` | `1.00x` (Baseline) |
| **Dart Stock JIT (`test.dart`)** | Untyped `Map<String, dynamic>` (`dart:convert`) | `0.64 s` | `583.0 MiB` | `0.96 s` | `723.7 MiB` | `0.98x` (`arm64`) / `1.01x` (`x64`) |
