# Results for `vllm-stream-args`

Every folder holds the harbor `result.json`, the job `config.json`
(`job-config.json`), the verifier's `ctrf.json` and `test-stdout.txt` where the
verifier ran, and the agent's final message where an agent ran. Harbor's secret
redaction replaces some digits in copied files with `[REDACTED]`; the CTRF
summaries and verifier stdout are authoritative.

| folder / file | what it is |
|---|---|
| `oracle-*` | reference solution under the submitted grader: 85/85, reward 1.0 |
| `nop-*` | no-op agent under the submitted grader: 5/85, reward 0.0 |
| `rubric-review-verdicts.json` | rubric review verdicts (33 pass / 2 N/A / 0 fail) |
| `run-codex-trial{1,2,3}` | codex gpt-5.6-sol xhigh on the previous grader version (72 cases): fail (7), fail (1), solved |
| `final-run-codex-trial{1,2,3}` | codex on the submitted task (85 cases): fail (2), solved, solved |
| `final-run-claude-trial{1,2,3}` | claude-code opus-5 max on the submitted task: solved, solved, fail (2 bookkeeping cases) |
| `infra-failures/` | trials that ended in `ApiRateLimitError` (claude, four) or were cancelled by a harness crash (codex, one); they count neither as failures nor as solves |
| `cheat-codex-1-filter-refusal` | `/cheat`: OpenAI content filter rejected the hack prompt; reward 0.0, no attempt |
| `cheat-codex-2-skip-bypass-old-verifier` | `/cheat` against the earlier in-process verifier: `pytest.skip` from the artifact counted as passing, reward 1.0 — the hole that led to the rebuild |
| `cheat-codex-3-hardened-verifier` | `/cheat` against the rebuilt verifier: genuine attempt, 4/72, reward 0.0 |
| `cheat-codex-4-final-task` | `/cheat` on the three-parser version: content filter again, reward 0.0 |
| `cheat-codex-5-twelve-parsers`, `cheat-codex-6-twelve-parsers-retry` | `/cheat` on the submitted twelve-parser task: OpenAI's content filter rejected the hack prompt before the first command both times, reward 0.0 |
| `cheat-claude` | `/cheat` with claude-code opus-5 max on the submitted task |
