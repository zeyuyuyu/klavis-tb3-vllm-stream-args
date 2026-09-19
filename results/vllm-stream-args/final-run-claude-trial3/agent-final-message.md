(digits shown as 1 may have been redacted by harbor)

All three parsers are fixed and verified. Here's what was wrong and what I did.

## Root cause

All three parsers re-derived the delta from scratch each step and diffed against a snapshot, so the result depended on where chunk boundaries fell:

- **Jamba / InternLM2** re-ran `partial_json_parser` over the whole prefix, then used `cur_args_json.index(delta_text)` and `extract_intermediate_diff()`. With a multi-token delta, `delta_text` is often not a substring of the `json.dumps` output (`ValueError` → chunk silently dropped, state not advanced), and the common-prefix/suffix diff mangles nested objects — reproducing exactly the `{"city": ", "opts": {}"units": ""C` garbage you saw.
- **MiniCPM** emitted everything as content whenever `"<function"` wasn't yet in `current_text`, so a step ending mid-tag (`…<fun`) flushed the tag start as content and left `_processed_len` past the block — the whole tool call then arrived as literal text.
- All three were also O(n²): every step re-scanned/re-parsed the entire output.

## Fix

Each parser now consumes the model text **once, in order**, holding back only what is genuinely still ambiguous.

- **New `vllm/tool_parsers/incremental_json.py`** — `JsonValueStreamer` re-serializes a JSON value into `json.dumps(..., ensure_ascii=False)` form as its source arrives, emitting only bytes later input cannot change (scalars wait for their terminator, since `1e5` → `100000.0`; string bodies stream through, at most one escape behind). `JsonToolCallStreamer` layers name/arguments events on top, and `pending_suffix()` closes a stream cut short.
- **New `TaggedJsonToolCallStream` in `streaming.py`** — shared driver for "content, then JSON after a start tag"; keeps `prev_tool_call_arr` / `streamed_args_for_tool` in step with what was sent. Jamba and InternLM2 streaming are now ~5 lines each on top of it.
- **MiniCPM** streaming is a single-pass XML scanner: string-typed `<param>` values stream as written (trailing whitespace held for the `.strip()`, CDATA ruled out first), other values resolve at `</param>`, and alias/unknown `<function>` blocks still fall back to the whole-block rules.

## Verification

I could not run pytest here — the environment has no torch, transformers, pytest, or `uv`, so `.venv/bin/python -m pytest` isn't available. I loaded the parser modules against stub protocol types instead and drove them directly:

- **Chunk-independence**: for every parser and every test output, ~49 chunkings (sizes 1–1000 plus randomized, with special tokens kept atomic) all reconstruct the non-streaming `arguments` byte-for-byte, with `streamed_args_for_tool` matching and `get_remaining_unstreamed_args() == ""`.
- **Latency**: name within 1 delta of its closing quote / `>`; string args never more than 6 chars behind; `<param>` delivered in the same delta as `</param>`.
- **Perf** (150 000 chars, one char per step, this machine): jamba 4.4 s, internlm 4.4 s, minicpm 3.3 s — all under the 20 s budget.
- **Truncation**: at every cut point, streamed args + `get_remaining_unstreamed_args()` parse as JSON.
- I replayed the existing MiniCPM non-streaming assertions (14 cases) and the existing streaming tests — all still pass.

Tests added: `tests/tool_parsers/test_incremental_json.py`, an `assert_streaming_matches_nonstreaming` helper in `tests/tool_parsers/utils.py`, and a chunk-independence test per parser. I removed the seven now-obsolete `strict=True` xfails from the InternLM2 config — they would XPASS and fail the suite.

Two things worth flagging:

- A step wide enough to both finish one call and name the next emits two `DeltaToolCall` entries in one `DeltaMessage` (as Hermes already does). Queuing the second would risk losing it if that step is the last, so the new tests pass `assert_one_tool_per_delta=False`.
- One pre-existing MiniCPM gap I did not close: when a `<param>` value contains well-formed nested markup or XML entities, the non-streaming extractor parses the block with ElementTree (`&amp;` → `&`, `<b>x</b>` → `""`), but which path it takes depends on whether the *whole block* is well-formed — unknowable mid-stream without buffering. Streaming keeps the raw text, same as the old partial-block path.

I have not opened a PR; per `AGENTS.md` that needs the duplicate-work `gh` checks and a human who can defend the change.
