Implemented the server-side streaming fix for all twelve parsers.

Key changes:

- Added a shared incremental JSON streaming engine in [streaming_json.py](/app/vllm/vllm/tool_parsers/streaming_json.py:47), supporting nested JSON, Unicode, escapes, dynamic tool names, arguments-before-name, repeated markers, delimiters, and DeepSeek fences.
- Added incremental MiniCPM5 XML parsing in [minicpm5xml_tool_parser.py](/app/vllm/vllm/tool_parsers/minicpm5xml_tool_parser.py:5[REDACTED]0), including CDATA, entities, schema coercion, multiple calls, and prompt content.
- Kept `prev_tool_call_arr`, `streamed_args_for_tool`, and remaining arguments synchronized with emitted deltas.
- Added chunk-boundary, latency, content, and state regression coverage in [test_multi_token_streaming_regression.py](/app/vllm/tests/tool_parsers/test_multi_token_streaming_regression.py:202).

Verification:

- [REDACTED]34 combined regression/XML tests passed.
- Existing affected parser suites passed; only pre-existing expected skips/xfails remain.
- All pre-commit hooks passed, including Ruff and mypy.
- [REDACTED]50,000-character, one-character-at-a-time benchmarks:
  - JSON: 3.95s
  - DeepSeek: 3.95s
  - XML: [REDACTED].04s

The upstream Llama tokenizer-dependent test module could not run because its Hugging Face tokenizer is gated; Llama is covered by the new offline chunking matrix. No commit or PR was created.
