(digits shown as 1 may have been redacted by harbor)

Fixed. All three parsers now produce identical tool calls regardless of how the decoder chunks the output.

## Root causes

Each parser inferred its position in the output from `delta_text` instead of from the accumulated `current_text`:

- **Jamba / InternLM2** re-parsed the whole partial JSON every step and diffed snapshots (`cur_arguments_json.index(delta_text)`, `extract_intermediate_diff`). With multi-token deltas the index lookup lands in the wrong place, producing the garbled `{"city": ", "opts": {}"units": ""C`. Both also emitted content without holding back a start token split across a step, leaking `Sure!<tool_calls` / `Sure!<|action_start|` as content.
- **MiniCPM** guarded on `"<function" not in current_text`, so a step boundary inside `<function` leaked the tag as content and the parser never recovered — and when a whole call arrived in one step it returned only the preceding content and dropped the tool call entirely (`chunk=1000` above).

## Fix

New `vllm/tool_parsers/json_streaming.py`:
- `JsonValueStreamer` — incrementally re-serializes raw JSON into the canonical `json.dumps(..., ensure_ascii=False)` form the non-streaming extractors return, emitting the longest already-determined prefix (string characters released as generated; numbers held to their terminator since `1.50` and `1.5` serialize alike; `\uXXXX` and surrogate pairs decoded before re-encoding).
- `JsonToolCallStreamer` — drives it over `{"name", "arguments"}` objects or an array of them.
- `JsonToolCallStreamParser` — the shared parser base; Jamba and InternLM2 now just declare their start token and streamer layout.

`minicpm5xml_tool_parser.py` gets an explicit XML state machine over a forward-only cursor, delivering the name on the `>` and each parameter on its `</param>`, appending only the newly added arguments rather than re-dumping the dict.

All three scan `current_text` through a cursor that only moves forward, hold back a suffix that could still grow into a start token, and emit content plus tool calls in the same delta when one step covers both.

## Contracts verified

`tests/tool_parsers/test_streaming_chunk_independence.py` (new, 57 tests): 33 chunkings per case give byte-identical arguments and content; `streamed_args_for_tool` + `get_remaining_unstreamed_args()` reconstruct exactly the non-streaming `arguments`; name arrives on the delta that completes it; string arguments stay ≤16 characters behind; MiniCPM params land within 2 deltas of `</param>`; 150 000 characters one at a time stream in **4.2 s / 4.1 s / 0.6 s** (jamba / internlm / minicpm) against the 20 s budget. On the pre-fix parsers 11 of these fail and the throughput test has to be killed.

Also: 1482-stream fuzz over malformed/truncated/unicode/CDATA/collapsed-tag inputs — zero chunk-dependent results, zero protocol violations; 809 tool-parser tests pass; removed the 7 now-stale strict `xfail_streaming` markers from the InternLM2 config.

Two things worth flagging:
- Inputs the non-streaming extractor rejects outright (truncated JSON, duplicate `<param name>`, missing required props) still yield a streamed tool call, because the name went out under the ≤2-delta rule and cannot be retracted. Behaviour is now at least identical across chunkings.
- MiniCPM parameters are delivered on `</param>`, not character-by-character: whether to strip a `<![CDATA[...]]>` wrapper and how to coerce the value are only knowable at the close, so incremental delivery would break the byte-for-byte requirement.

I installed torch/pytest/etc. into the container to run the suite; nothing in the repo's dependency files changed.
