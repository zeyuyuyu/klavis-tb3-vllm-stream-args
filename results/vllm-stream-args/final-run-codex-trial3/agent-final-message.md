Implemented the server-side streaming fix.

Key changes:

- Added a single-pass incremental JSON canonicalizer/framer in [streaming.py](/app/vllm/vllm/tool_parsers/streaming.py:[REDACTED]67).
- Updated [Jamba](/app/vllm/vllm/tool_parsers/jamba_tool_parser.py:[REDACTED]36) and [InternLM2](/app/vllm/vllm/tool_parsers/internlm2_tool_parser.py:64) to stream chunk-independently with exact non-streaming argument serialization.
- Reworked [MiniCPM XML streaming](/app/vllm/vllm/tool_parsers/minicpm5xml_tool_parser.py:890) with bounded incremental parsing, immediate names, incremental string arguments, entity/CDATA handling, aliases, parallel calls, and consistent reconciliation state.
- Added chunk-boundary, latency, exact-byte reconstruction, alias, content-prefix, and [REDACTED]50,000-character performance regressions.

Validation:

- Focused suites: `76 passed, [REDACTED] pre-existing xfailed`.
- [REDACTED]50k one-character stream: MiniCPM 2.58s, Jamba 2.90s, InternLM2 2.8[REDACTED]s.
- All pre-commit hooks passed, including Ruff and mypy.
- Broader tool-parser suite: `909 passed, [REDACTED] skipped, 27 xfailed`; [REDACTED]5 setup errors were solely due to the gated Llama tokenizer returning HTTP 40[REDACTED].
