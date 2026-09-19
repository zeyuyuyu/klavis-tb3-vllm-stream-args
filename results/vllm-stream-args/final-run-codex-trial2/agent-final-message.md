Implemented server-side chunk-independent streaming for Jamba, InternLM2, and MiniCPM XML tool parsers.

Key changes:

- Added an incremental JSON canonicalizer in [incremental_json_parser.py](/app/vllm/vllm/tool_parsers/incremental_json_parser.py:[REDACTED]8).
- Reworked [Jamba](/app/vllm/vllm/tool_parsers/jamba_tool_parser.py:[REDACTED]33) and [InternLM2](/app/vllm/vllm/tool_parsers/internlm2_tool_parser.py:54) to stream every transition within multi-token chunks.
- Replaced MiniCPM’s repeated full-output regex parsing with a bounded-buffer XML state machine in [minicpm5xml_tool_parser.py](/app/vllm/vllm/tool_parsers/minicpm5xml_tool_parser.py:869).
- Preserved preceding content and synchronized `prev_tool_call_arr`, `streamed_args_for_tool`, and final reconciliation.
- Added exact-byte chunking tests, including escapes, nested values, CDATA, entities, aliases, and wrapped arguments.

Validation:

- `64 passed, [REDACTED] xfailed`—the xfail is the existing unrelated InternLM non-streaming malformed-JSON case.
- Full changed-files pre-commit suite passed.
- Python 3.[REDACTED]0 and 3.[REDACTED]2 mypy passed.
- [REDACTED]50,000-character, one-character-at-a-time benchmarks:
  - Jamba: 2.740s
  - InternLM2: 2.693s
  - MiniCPM: 3.046s
