# vllm-stream-args — a Terminal-Bench 3 task

Built for the Klavis AI founding-engineer evaluation. The task is in
[`tasks/vllm-stream-args/`](tasks/vllm-stream-args/); everything needed to
re-run the checks and the trials is in [`scripts/`](scripts/) and the results
are in [`results/`](results/).

Read these two first:

- [`docs/failure-analysis.md`](docs/failure-analysis.md) — the official trial
  results for the submitted task, what the agents got wrong and right, the
  `/cheat` trial that found a verifier hole and how it was closed, and an
  honest reading of the numbers. **Codex failed 3 of 6 official trials on this
  design and solved 3; the submission does not meet the all-trials-fail bar.**
- [`docs/design-study.md`](docs/design-study.md) — eight complete tasks were
  built for this submission and each was probed against the CI's own agent
  configurations. The study reports what each design tested, what the models
  did to it, what the measurements changed, and why design 8 is the one
  submitted.

The seven superseded designs are kept in [`study/`](study/), complete, so the
claims in the study can be checked rather than taken on trust.

## The task

`/app/vllm` is [vllm-project/vllm](https://github.com/vllm-project/vllm) at
commit `877dae9c`. Three of its streaming tool-call parsers (Jamba, InternLM2,
MiniCPM XML) return different `arguments` depending on how the decoder chunks
the model output. The agent has to fix them in place so that, for any split of
the output into deltas, the client assembles exactly the tool calls the
non-streaming extractor returns — one name per index, arguments byte-for-byte
the non-streaming `json.dumps` string, parser bookkeeping the serving layer can
reconcile — while still streaming (name within 2 deltas, string arguments at
most 16 characters behind the model, XML params within 2 deltas of closing) and
in linear time (150 000 characters one per delta in under 20 s).

The grader replays 37 model outputs — compact, indented, ASCII-escaped and
hand-written JSON; non-object arguments; nested `"arguments"` keys; a second
block the extractor ignores; tokenizer glyphs; typed XML values; text between
`<|plugin|>` and `{` — through 17 delivery schedules each, plus latency and
throughput probes. The pytest process never imports the agent's code: a
privilege-dropped worker subprocess drives the parsers and returns data.

The reference fix (`solution/`) is a resumable scanner over the raw model text
whose canonical output is provably a prefix of the final `json.dumps`, and an
incremental driver for the XML format.

## Results at a glance

| check | result |
|---|---|
| 22 static checks (`scripts/checks/`) | all pass — [`results/static-checks.md`](results/static-checks.md) |
| rubric review (`claude-code` sonnet, `scripts/review/`) | 33 pass / 2 not applicable / 0 fail on the pre-final files; RUBRIC_FINAL |
| oracle | reward 1.0, 85/85 |
| nop | reward 0.0, 5/85 |
| codex gpt-5.6-sol xhigh, 3 trials (task as submitted) | **fail, solved, solved** |
| codex, 3 earlier trials on the previous grader version | fail, fail, solved |
| claude-code opus-5 max, 3 trials | **solved**, **solved**, **fail** (2 cases) |
| `/cheat` codex | 0.0 (two runs refused by OpenAI's content filter; one genuine attempt against the hardened verifier scored 0.0; one genuine attempt against the earlier verifier scored 1.0 and is why it was rebuilt) |
| `/cheat` claude-code | CLAUDE_CHEAT_GLANCE |

## Reproducing

Everything was run against
[`harbor-framework/terminal-bench`](https://github.com/harbor-framework/terminal-bench)
at commit `7a337a83` (2026-09-16) with `harbor 0.23.0`, Docker backend, on a
16-core / 30 GB host.

```bash
uv tool install harbor
git clone https://github.com/harbor-framework/terminal-bench.git
cp -r tasks/vllm-stream-args terminal-bench/tasks/
cd terminal-bench

for check in scripts/checks/check-*.sh; do bash "$check" tasks/vllm-stream-args; done
python3 scripts/review/stage_task.py tasks/vllm-stream-args /tmp/stage/rubric-review
harbor run -p /tmp/stage/rubric-review -a claude-code -m sonnet --env docker --yes
harbor run -p tasks/vllm-stream-args --agent oracle --env docker --yes
harbor run -p tasks/vllm-stream-args --agent nop --env docker --yes
```

Trials: [`scripts/run-trials.sh`](scripts/run-trials.sh) uses the agent,
model, reasoning effort and trial count from the repository's
`.github/harbor-run-defaults.yml` (codex `gpt-5.6-sol` xhigh; claude-code
`claude-opus-5` max with `CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000`; three trials;
`/cheat` with `docs/prompts/hack-trial-prompt.md`). Both agents ran on
subscriptions (`CODEX_FORCE_AUTH_JSON=1`, `CLAUDE_FORCE_OAUTH=1`).

## License

MIT, see [LICENSE](LICENSE). Published by the author; no rights transfer to any
reviewing party.
