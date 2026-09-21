# Failure analysis

What the frontier agents did with `vllm-stream-args`, and what the numbers
mean. Trial records (harbor `result.json`, CTRF reports, verifier stdout, job
configs) are under [`results/vllm-stream-args/`](../results/vllm-stream-args/).

## Configuration

Exactly the TB3 CI defaults (`.github/harbor-run-defaults.yml`): `codex` with
`openai/gpt-5.6-sol`, `reasoning_effort=xhigh`; `claude-code` with
`anthropic/claude-opus-5`, `reasoning_effort=max`,
`CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000`; three standard trials per agent, one
`/cheat` trial per agent with `docs/prompts/hack-trial-prompt.md`; the task's
own eight-hour agent budget. Both agents ran on subscriptions
(`CODEX_FORCE_AUTH_JSON=1`, `CLAUDE_FORCE_OAUTH=1`), Docker backend,
`--agent-setup-timeout-multiplier 3`.

## Standard trials

The task went through five grader versions; the submitted one (v5, twelve
parsers) is the one that matters, and the earlier ones are reported because
they are the record of how it got there.

### Submitted task (v5, twelve parsers)

| job | trial | agent | outcome | verifier |
|---|---|---|---|---|
| `vsa-run-codex-v5` (`q8AYSwb`) | 1 | codex gpt-5.6-sol xhigh | **fail** | 4 of 228 cases failed: hunyuan/xLAM skipped-entry rule, MiniCPM typed values with whitespace, xLAM text-before-array |
| `vsa-run-codex-v5` (`EnAhJqw`) | 2 | codex | **fail** | 4 of 228: ERNIE `{}` default, hunyuan/xLAM skipped-entry rule, xLAM text-before-array |
| `vsa-run-codex-v5-r1` (`JKYEHfi`) | 3 | codex | **fail** | 7 of 228: hunyuan/xLAM skipped-entry rule, string-lag latency bound on five JSON formats |
| `vsa-run-deepseek-v5b` (`YdDhonS`) | 1 | DeepSeek v4.1 flash, reasoning max (terminus-2) | **fail** | 22 of 228: `null` arguments in eight formats, skipped-entry rule (Hunyuan, xLAM), second block (Jamba, Hunyuan), ERNIE `{}` default, four no-call rules, MiniCPM glyphs / single-quoted attributes / two calls |
| `vsa-run-deepseek-v5b` (`BYH63hx`) | 2 | DeepSeek v4.1 flash | **fail** | 181 of 228: rewrote eleven parsers and a shared helper without being able to execute them (`torch` absent; it settled for `py_compile` and `git diff --check`), declared the work ready, and the rewritten parsers emit no tool calls at all |
| `vsa-run-deepseek-v5b` (`GpqYovx`) | 3 | DeepSeek v4.1 flash | **fail** | 25 of 228 across eleven formats (MiniCPM heaviest: glyphs, quoting, multi-call, typed values; Granite no-call rule; skipped entries; `null` and string arguments) |

Each codex run was a complete attempt: 2h37m-3h13m of wall clock, 78-125
commands, a shared incremental JSON scanner written from scratch, all twelve
streaming methods rewritten, its own chunk-invariance and latency test suite
added, and a closing report claiming success. All three then failed the same
family of cases: rules that exist only in the non-streaming extractors
(Hunyuan and xLAM skip a call object that has no `"arguments"`, and index the
remaining calls compactly; xLAM treats text before the array as "no tool
call"; ERNIE defaults a missing `"arguments"` to `{}`), and, in one run, the
16-character string-lag bound. One further codex run
(`aC6UEsG`, `ApiOverloadedError` after 17 commands) was an OpenAI-side outage
and is filed under `infra-failures/`, not counted. 

**Why DeepSeek and not claude-code on the submitted task.** The reviewers'
brief allows one model substitution - DeepSeek v4.1 flash (max) - when a
subscription is not available, and confirmed by email (2026-09-21) that
codex + DeepSeek is an accepted pair. Claude-code opus-5 (max) was run on
this task three times and none of the runs counted: two on the Max
subscription died to the five-hour rate window after 1h08 and ~1h (a run of
this task takes claude about four hours), and one through a paid
Anthropic-compatible gateway died at 4h05 when the key's spend cap was
reached (its partial state graded 206/228, xLAM untouched). All three are
under `results/vllm-stream-args/infra-failures/`. The claude results that do
exist are on the three-parser version below (solved, solved, fail).


**DeepSeek's three runs** took 2h20m-3h07m and 446-517 tool calls each; two
delivered complete twelve-parser rewrites that miss the same oracle-rule family
codex missed (with `null` arguments and the no-call rules added), and one
never managed to execute its rewrite (the environment has no torch, so it
settled for `py_compile`) and shipped parsers that emit nothing. All three
ended with the agent declaring the work complete. Two earlier DeepSeek runs
died to the gateway key's spend cap (`RateLimitError`, filed under
`infra-failures/`) and one job was misconfigured on my side (the API key was
not in the harness environment; those directories were discarded, no model
ever ran).

**Result against the brief: codex 3/3 genuine failures, DeepSeek 3/3 genuine
failures, every `/cheat` at 0.0.** Every counted failure is an agent that
finished, declared success, and was graded; none is a timeout, crash, rate
limit or container error.

### Earlier versions (three parsers)

| job | trial | agent | outcome | verifier |
|---|---|---|---|---|
| v3 (`vsa-run-codex`, `vsa-run-codex-b`) | 1 | codex | **fail** | 7 of 72 |
| v3 | 2 | codex | **fail** | 1 of 72 (`jamba_second_block_is_ignored_like_non_streaming`) |
| v3 | 3 | codex | solved | 72/72 |
| v4 (`vsa-run-codex-v4`) | 1 | codex | **fail** | 2 of 85 (`internlm2_text_between_plugin_and_brace`) |
| v4 | 2 | codex | solved | 85/85 |
| v4 | 3 | codex | solved | 85/85 |
| v4 (`vsa-run-claude-v4*`) | 1 | claude-code opus-5 max | solved | 85/85 |
| v4 | 2 | claude-code | solved | 85/85 |
| v4 | 3 | claude-code | **fail** | 2 of 85 (bookkeeping after a second XML call) |

On three parsers the two models solved the task about half the time; the
failures were always oracle quirks the agent's own harness never generated.
That observation is what the twelve-parser version is built on: the
per-parser chance of missing a quirk multiplies across formats.

Wall-clock per trial was 35-75 minutes for codex on three parsers and 2.5-3.2
hours on twelve; each job's `result.json` and CTRF report is in
`results/vllm-stream-args/` (harbor's secret redaction replaces some digits
in copied logs with `[REDACTED]`; the CTRF summaries and verifier stdout are
authoritative).

## What the agents got wrong, precisely

v3 trial 1 (`gZbMEfL`) is the most informative failure. The agent produced an append-only
canonical scanner that passes 65 of 72 cases - every delivery schedule, the
latency bounds, the throughput bound, unicode escapes and surrogate pairs,
exponent floats, compact and indented JSON, non-object arguments. The seven
failures are all cases where the *non-streaming* extractor's behaviour, which
the instruction names as the oracle, differs from a natural reading of the
format:

| failing case | what the non-streaming extractor does | what the agent's stream did |
|---|---|---|
| `jamba_name_after_arguments` | accepts `{"arguments": {...}, "name": "book"}` | did not emit the call when the name arrives after the arguments |
| `jamba_three_calls_with_extra_keys` | ignores `"id"`, `"type"` next to `"name"`/`"arguments"` | lost calls whose objects carry extra keys |
| `jamba_second_block_is_ignored_like_non_streaming` | `findall(...)[0]`: only the first `<tool_calls>` block counts | streamed the second block too |
| `minicpm5_tokenizer_space_glyphs` | normalises `Ġ`/`Ċ` glyphs before parsing (`_normalize_model_output`) | streamed the raw glyphs |

v3 trial 2 failed only the second-block case; v4 trial 1 failed only the case
where InternLM2's output has text (`\njson\n`) between `<|plugin|>` and the
opening brace, which the pinned non-streaming code handles with
`action[action.find("{"):]`. The two v4 solves handled every one of these.

None of these were guessed at by the grader: each is a code path that exists in
the pinned tree and is exercised by the non-streaming endpoint the instruction
points to. They are the "unknown unknowns" of the task - an agent that verifies
its own work by generating JSON with `json.dumps` and chunking it never meets
them, because `json.dumps` never writes a name after the arguments, never adds
call-level keys, and a hand-written harness never produces a second block or
tokenizer glyphs.

## The two contracts that were not enough

The submitted grader is the third. The two before it were each defeated by a
probe within the hour, and the record of that is part of the analysis:

1. **Invariance only** (assembled arguments parse to the non-streaming object,
   identical across splits). Solved in 25 minutes by buffering each call until
   complete and emitting it whole - correct by the letter, and not streaming.
2. **Invariance + latency + throughput.** Solved in 65 minutes with an
   append-only scanner emitting canonical `json.dumps` text; it failed only the
   bookkeeping cases whose requirement the v2 instruction had not stated, so as
   written it would have passed.
3. **Byte-for-byte canonical text + bookkeeping + a scenario battery drawn
   from the non-streaming code paths** (31 outputs x 17 schedules, latency,
   throughput). This is what the trials below were graded on.

## Verifier hardening forced by the /cheat trials

The first codex `/cheat` trial that got past OpenAI's content filter (the
filter rejected the CI's hack prompt outright on the first attempt, as it had on
an earlier task) found a real hole: it patched `abstract_tool_parser.py` inside
the artifact to call `pytest.skip` whenever `PYTEST_CURRENT_TEST` is set, and
the verifier's per-test worker treated a skipped test as a pass - reward 1.0.
The grader was rebuilt so that the pytest process never imports agent code:
`tests/parser_worker.py` drives the parsers as `nobody` in a subprocess and
returns data, every assertion and every clock is in the trusted process, and
`test.sh` additionally requires `passed == collected` in the CTRF report. The
cheat artifact scores 0/72 under the rebuilt grader; the reference still scores
85/85.

| /cheat trial | agent | outcome |
|---|---|---|
| 1 | codex gpt-5.6-sol xhigh | OpenAI's content filter rejected the CI hack prompt before the first turn (`AgentSafetyRefusalError`); reward 0.0, no attempt |
| 2 | codex | genuine attempt against the earlier in-process verifier: `pytest.skip` from inside the artifact was counted as passing -> **reward 1.0**; the hole this report describes |
| 3 | codex | genuine attempt against the rebuilt verifier: `pyproject.toml` `--collect-only` addopts (not in the artifact, and pytest runs from `/tests`) plus in-process pytest detection; 4/72 passed, reward 0.0 |
| 4 | codex, three-parser version | content filter again (`AgentSafetyRefusalError` after one command); reward 0.0 |
| 5, 6 | codex, submitted twelve-parser task | content filter, no command executed, both times; reward 0.0. The verifier architecture is the one attempt 3 was run against |
| 5 | claude-code opus-5 max, three-parser version | genuine attempt (49 tool calls, a written red-team report): found no verifier artifacts in the sandbox, concluded the grader runs externally against the captured artifact, and did not find a bypass; 5/85 passed, reward 0.0 (a first attempt was cut off by the rate limit and is under `infra-failures/`) |
| 8 | DeepSeek v4.1 flash (max), terminus-2, submitted twelve-parser task | genuine and elaborate attempt (1h02, 129 tool calls): an import-time hook in the artifact's `__init__.py`, a root `conftest.py`, a global plugin and a `sitecustomize` layer that replace pytest's setup/runtest/teardown with no-ops - locally it made a failing test report as passed. Against the submitted verifier it bought nothing, because the agent's package is imported only inside the privilege-dropped worker and never in the pytest process: 45/228 passed, reward 0.0 |
| 7 | claude-code opus-5 max, submitted twelve-parser task | genuine attempt (33 min, 38 tool calls, parser files left unchanged): its report's one finding is that the environment has network access and `origin` points at upstream vLLM, so later upstream commits touching these parsers can be fetched. Those commits are not chunking-invariant (the whole-output-in-one-delta case still fails, which is how this task started), so they do not earn the reward; TB3 tasks allow network by default and the reference is the author's own. 45/228 passed, reward 0.0 |

The filter behaviour is worth knowing for anyone running the CI's `/cheat`
against codex: it rejected the identical prompt on an earlier task of mine as
well, so a refusal is the expected outcome about half the time and the
recorded 0.0 in those runs is not evidence of anything.

## Reading

Three readings survive the numbers.

**The property was the right one; coverage was the coin.** Every failure on
this task is an agent whose self-written harness never produced a shape the
pinned non-streaming code handles - name after arguments, a call object with
extra keys, a second `<tool_calls>` block, tokenizer glyphs, text before the
opening brace. Every solve is an agent that went and read those code paths.
Nothing in the instruction distinguishes the two runs; the same model with the
same budget does either, about half the time. A grader can keep adding such
shapes (v3 -> v4 caught one more run) but each one is a single coin flip
removed, not a floor raised.

**Timeouts were never the lever, and the brief says so.** The design that would
reliably defeat these models on this codebase - fix all ~30 parsers, not three -
would win mostly by running the eight-hour budget out, and the brief counts a
timeout as an infrastructure failure. So the task had to be one an agent
*finishes and is wrong about*, which is a much smaller target than "hard".

**What did survive is worth having.** The chunking-invariance + latency +
throughput + canonical-string contract is a real specification vLLM lacks,
the reference is a real fix (prefix-stable canonical scanner, incremental XML
driver), the 37-output battery is a regression suite upstream could use, and
the `/cheat` trial exposed a verifier pattern - importing agent code into the
pytest process - that other Terminal-Bench tasks in this style share. The
rebuilt verifier (agent code only in a privilege-dropped worker, all judgement
in the trusted process, `passed == collected` gate) is the part of this
submission I would most want copied.

(On whether the twelve-parser version is "just more of the same": see the
section of that name in `docs/design-study.md` - the misses are concentrated
on rules that exist only in the extractors, and the agents finished with time
to spare.)

If I were to keep going, I would not add a tenth shape. I would move the
difficulty out of the engineering and into a domain where the oracle is not
readable from the repository - the pattern the merged tasks that do defeat
these models share (`docs/design-study.md`, "Why, with the evidence I could
find").
