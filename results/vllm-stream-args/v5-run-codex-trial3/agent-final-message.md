Implemented the streaming fix for all twelve parsers.

Key changes:

- Added a shared single-pass incremental JSON parser/emitter with exact `json.dumps(..., ensure_ascii=False)` reconstruction and linear processing: [incremental_json_parser.py](/app/vllm/vllm/tool_parsers/incremental_json_parser.py:54).
- Added parser-specific incremental handling for XML/CDATA/entities, DeepSeek fences, split markers, parallel calls, arguments-before-name, and content preservation.
- Kept `prev_tool_call_arr`, `streamed_args_for_tool`, and reconciliation state synchronized.
- Added cross-parser arbitrary-chunk, no-invention, latency, state, and [REDACTED]50k-character performance coverage: [test_multitoken_streaming_parity.py](/app/vllm/tests/tool_parsers/test_multitoken_streaming_parity.py:245).

Verification:

- Combined parser suites: **28[REDACTED] passed**, [REDACTED] skipped, 7 expected xfailed, [REDACTED] xpassed.
- New cross-parser suite: **88 passed**.
- [REDACTED]50k-character JSON, XML, arguments-before-name, and DeepSeek streams complete under 20 seconds with ≤[REDACTED]6-character lag.
- All pre-commit hooks passed.
- Mypy passed for Python 3.[REDACTED]0 and 3.[REDACTED]2.
- `git diff --check` passed.
