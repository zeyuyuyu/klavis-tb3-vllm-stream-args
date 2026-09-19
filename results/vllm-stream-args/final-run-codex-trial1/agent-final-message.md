Implemented the server-side streaming fix.

Key changes:

- Added an incremental canonical JSON parser shared by Jamba and InternLM2: [streaming_json_parser.py](/app/vllm/vllm/tool_parsers/streaming_json_parser.py:244).
- Reworked [Jamba streaming](/app/vllm/vllm/tool_parsers/jamba_tool_parser.py:[REDACTED]33) and [InternLM2 streaming](/app/vllm/vllm/tool_parsers/internlm2_tool_parser.py:62) to be chunk-independent.
- Replaced MiniCPM’s repeated partial-block parsing with an incremental XML state machine: [minicpm5xml_tool_parser.py](/app/vllm/vllm/tool_parsers/minicpm5xml_tool_parser.py:437).
- Names emit once per index; arguments exactly match non-streaming `json.dumps(..., ensure_ascii=False)`.
- `prev_tool_call_arr`, `streamed_args_for_tool`, and remaining-argument reconciliation now agree.
- Preserved preceding content and added alias, wrapped-argument, CDATA, entity, Unicode, nested JSON, and multi-call coverage.

Validation:

- 67 passed, [REDACTED] pre-existing xfailed.
- Ruff and Python 3.[REDACTED]2 MyPy passed.
- [REDACTED]50,000-character, one-character-at-a-time tests:
  - Jamba: 3.88s
  - MiniCPM XML: 3.97s
- Both stayed well under the required 20 seconds.
