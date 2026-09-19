Implemented the server-side streaming fix for Jamba, InternLM2, and MiniCPM XML parsers.

Key changes:

- Added an incremental, chunk-invariant JSON lexer/canonicalizer in [incremental_json.py](/app/vllm/vllm/tool_parsers/incremental_json.py).
- Arguments now exactly match non-streaming `json.dumps(..., ensure_ascii=False)` output.
- Preserved pre-tool content and suppressed MiniCPM `<tool_call>` wrappers.
- Streamed XML strings, CDATA, entities, typed parameters, and aliases incrementally.
- Kept `prev_tool_call_arr`, `streamed_args_for_tool`, and final reconciliation consistent.
- Removed InternLM2’s obsolete streaming xfails.

Validation:

- Focused tests: **64 passed, [REDACTED] pre-existing non-streaming xfail**.
- Broader accessible tool-parser suite: **895 passed, [REDACTED] skipped, 27 xfailed**.
- Remaining [REDACTED]5 unfiltered setup errors require gated Llama tokenizer credentials.
- All pre-commit hooks and mypy passed.
- [REDACTED]50,000-character, one-character chunks:
  - Jamba: **3.0[REDACTED]s**
  - InternLM2: **2.96s**
  - MiniCPM: **3.07s**
