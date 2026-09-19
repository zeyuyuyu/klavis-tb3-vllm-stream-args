(digits shown as 1 may have been redacted by harbor)

Everything passes. Here's what I found and fixed.

## Root cause

All three parsers made *one step of progress per call* and re-derived the arguments from the whole accumulated text each time, so results depended on where the decoder split the output:

- **Jamba / InternLM2** partial-parsed the whole JSON prefix, re-serialised it, and diffed it against the previous serialisation with prefix/suffix heuristics (`extract_intermediate_diff`). With multi-token chunks the diffs interleaved wrongly — reproduced exactly the garbage in your report: `{"city": ", "opts": {}"units": ""C`. They also leaked a partially decoded `<tool_calls` / `<|action_start|` into `content`.
- **MiniCPM** returned a single `DeltaMessage` per call, so a chunk containing *both* leading content and a complete `<function>…</function>` block emitted the content and dropped the tool call permanently — the "no tool call, only the literal text as content" case. It also streamed partial `<function` tag text as content.

## Fix

New `vllm/tool_parsers/json_stream.py`: an incremental scanner that reads the raw text once, left to right, and re-emits it in exactly the shape `json.dumps(value, ensure_ascii=False)` produces (escapes, surrogate pairs, number normalisation, `", "`/`": "` separators). Nothing is emitted until it's final, so concatenated deltas equal the non-streaming `arguments` byte for byte regardless of chunking. `StreamingToolCall`/`StreamingToolCallList` sit on top and expose the name as soon as its closing quote arrives.

- **Jamba / InternLM2** now feed that scanner and stream `name` + argument deltas; leading content is emitted with a held-back partial-marker suffix (`split_leading_content`, new in `tool_parsers/utils.py`).
- **MiniCPM** got an incremental XML scanner (content → `<function>` tag → body → `<param>` tag → value). It emits all progress made in a call in one `DeltaMessage`, streams schema-typed `string` params character-by-character as canonical JSON (handling the `.strip()` and CDATA rules), and reconciles against `_parse_function_block` on `</function>` so the final arguments are byte-identical to non-streaming.

`prev_tool_call_arr` / `streamed_args_for_tool` are kept equal to what was actually sent, so `get_remaining_unstreamed_args()` returns `""`.

## Verified

Fuzzing 900 outputs × 4 random chunkings plus fixed 1/2/3/5/8/17-char and whole-output chunkings: streaming tool calls match non-streaming byte-for-byte. Measured against your constraints: name delivered in the same delta as the text completing it; `<param>` delivered in the same delta as its `</param>`; string-argument lag 0 chars (Jamba/InternLM2), 8 chars (MiniCPM, from the `</param>`/CDATA lookahead); 150 000 characters one at a time streams correctly in 2.6–3.3 s.

Tests: added chunking-equivalence tests to all three parser test files via a new `assert_streaming_matches_nonstreaming` helper, a unit suite for `json_stream`, and a no-buffering/linear-time guard. The seven `xfail_streaming` markers on InternLM2 are removed — those cases now pass.

One trade-off worth flagging: for MiniCPM the name must go out at the `>` of the `<function>` tag, so a block that only turns out invalid later (missing a required param, duplicate `<param name=…>`) still yields a tool call in streaming where non-streaming returns the block as content. That divergence is inherent to the latency requirement and matches the parser's previous behaviour; it's the only case where streaming and non-streaming still differ.

I couldn't run pytest here — this container has no torch/transformers/pytest — so I validated against the real parser modules with stubbed vLLM protocol classes plus a minimal pytest shim that executes the new and existing tool-parser tests. The Jamba test still needs the `ai21labs/Jamba-tiny-dev` tokenizer, which I substituted with a character-level one.
