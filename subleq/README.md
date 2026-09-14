# SUBLEQ

Implements a subleq based cpu. `toolchain/hsq` bundles a compiler which targets the subleq cpu.

Run testbench (test hsq program) with:
```bash
just testbench subleq --simulator=verilator --tb=tb_subleq
```