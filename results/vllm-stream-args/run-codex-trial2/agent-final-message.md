Implemented the streaming tool-parser fix.

Key changes:

- Added a one-pass incremental JSON canonicalizer shared by Jamba and InternLM2.
- Reworked MiniCPM XML parsing into an incremental state machine.
- Preserved pre-tool content while suppressing XML `<tool_call>` wrappers.
- Kept reconciliation state byte-for-byte aligned at completion.
- Added chunk-invariance, latency, reconciliation, and single-chunk parallel-call tests.

Validation:

- Focused suites: **75 passed, [REDACTED] pre-existing xfailed**
- Targeted pre-commit hooks: passed
- Python 3.[REDACTED]2 mypy: passed
- [REDACTED]50,000-character, one-character-per-delta benchmark:
  - Jamba: **3.84s**
  - MiniCPM: **3.77s**

A broader unrelated streaming suite had two existing Kimi K2 required-tool-choice failures; the other [REDACTED]8 tests passed.
