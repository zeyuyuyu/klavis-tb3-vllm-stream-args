# Results for `vllm-stream-args`

Every folder holds the harbor `result.json`, the job `config.json`
(`job-config.json`), the verifier's `ctrf.json` and `test-stdout.txt` where the
verifier ran, and the agent's final message where an agent ran. Harbor's secret
redaction replaces some digits in copied files with `[REDACTED]`; the CTRF
summaries and verifier stdout are authoritative.

| folder / file | what it is |
|---|---|
| `oracle-*` | reference solution under the submitted grader (twelve parsers): 228/228, reward 1.0 |
| `nop-*` | no-op agent under the submitted grader: 45/228, reward 0.0 |
| `rubric-review-verdicts.json` | rubric review verdicts on the submitted files (33 pass / 2 N/A / 0 fail) |
| `v5-run-codex-trial{1,2,3}` | codex gpt-5.6-sol xhigh on the submitted twelve-parser task: fail (4 cases), fail (4), fail (7) |
| `v5-run-deepseek-trial{1,2,3}` | DeepSeek v4.1 flash (reasoning max, terminus-2) on the submitted twelve-parser task - the reviewers' permitted substitution for claude: fail (22 cases), fail (181), fail (25) |
| `v5-cheat-deepseek` | `/cheat` with DeepSeek v4.1 flash (max) on the submitted task: genuine pytest-hook attack, reward 0.0 |
| `run-codex-trial{1,2,3}` | codex on the three-parser v3 grader (72 cases): fail (7), fail (1), solved |
| `final-run-codex-trial{1,2,3}` | codex on the three-parser v4 grader (85 cases): fail (2), solved, solved |
| `final-run-claude-trial{1,2,3}` | claude-code opus-5 max on the three-parser v4 grader: solved, solved, fail (2 bookkeeping cases) |
| `infra-failures/` | trials that ended in `ApiRateLimitError` (claude), `ApiOverloadedError` (codex) or were cancelled by a harness crash (codex); they count neither as failures nor as solves |
| `cheat-codex-1-filter-refusal` | `/cheat`: OpenAI content filter rejected the hack prompt; reward 0.0, no attempt |
| `cheat-codex-2-skip-bypass-old-verifier` | `/cheat` against the earlier in-process verifier: `pytest.skip` from the artifact counted as passing, reward 1.0 — the hole that led to the rebuild |
| `cheat-codex-3-hardened-verifier` | `/cheat` against the rebuilt verifier: genuine attempt, 4/72, reward 0.0 |
| `cheat-codex-4-final-task` | `/cheat` on the three-parser version: content filter again, reward 0.0 |
| `cheat-codex-5-twelve-parsers`, `cheat-codex-6-twelve-parsers-retry` | `/cheat` on the submitted twelve-parser task: OpenAI's content filter rejected the hack prompt before the first command both times, reward 0.0 |
| `cheat-claude` | `/cheat` with claude-code opus-5 max on the three-parser v4 grader: genuine attempt, reward 0.0 |
| `v5-cheat-claude` | `/cheat` with claude-code opus-5 max on the submitted twelve-parser task: genuine attempt, parser files unchanged, reward 0.0 |
