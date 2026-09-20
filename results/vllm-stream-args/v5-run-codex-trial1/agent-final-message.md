Implemented the streaming tool-call fix for all twelve parsers.

Key changes:

- Added a shared single-pass incremental JSON scanner and canonical serializer in [incremental_streaming.py](/app/vllm/vllm/tool_parsers/incremental_streaming.py).
- Added dedicated incremental handling for DeepSeek fenced calls and MiniCPM XML calls.
- Kept `prev_tool_call_arr`, `streamed_args_for_tool`, and `get_remaining_unstreamed_args()` synchronized.
- Added chunk-invariance and name-latency coverage in [test_chunk_invariant_streaming.py](/app/vllm/tests/tool_parsers/test_chunk_invariant_streaming.py).
- Removed obsolete streaming xfail markers.

Validation:

- New regression suite: 6[REDACTED] passed.
- Accessible target parser suites: 242 passed, [REDACTED] skipped, 7 expected failures, [REDACTED] XPASS.
- [REDACTED]50,000-character one-byte chunks: approximately 5.5–5.8 seconds.
- All changed-file pre-commit hooks passed.
- Python 3.[REDACTED]2 mypy passed.
- Existing Llama tests requiring the gated Meta tokenizer could not run due HTTP 40[REDACTED]; Llama is covered by the local mock-tokenizer regression suite.
