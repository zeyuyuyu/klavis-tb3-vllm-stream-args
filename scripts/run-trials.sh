#!/usr/bin/env bash
# Standard (/run) and adversarial (/cheat) trials, using the agent, model,
# reasoning effort and trial count from .github/harbor-run-defaults.yml.
#
# Run from inside a clone of harbor-framework/terminal-bench with
# tasks/vllm-stream-args copied in.
#
#   codex login                       # ChatGPT subscription
#   claude setup-token                # -> CLAUDE_CODE_OAUTH_TOKEN
#   CLAUDE_CODE_OAUTH_TOKEN=... ./run-trials.sh
#
# Claude subscriptions: on a Max plan one opus-5 `max` trial of this task
# roughly exhausts a five-hour window; trials 2 and 3 then fail with
# ApiRateLimitError (an infrastructure failure that does not count) and have to
# be re-run one per window (`-k 1`), which is how the recorded claude trials
# were obtained.
#
# Concurrency is deliberately low: three agent containers at 2 CPUs each plus
# their setup (npm, nvm) is enough to push a 16-core / 30 GB host into agent
# setup timeouts, which are infrastructure failures and do not count as model
# failures.
set -euo pipefail

TASK=${TASK:-tasks/vllm-stream-args}
TRIALS=${TRIALS:-3}
CONCURRENCY=${CONCURRENCY:-2}
CHEAT_PROMPT=docs/prompts/hack-trial-prompt.md

codex_args=(--agent codex --model openai/gpt-5.6-sol
            --ae CODEX_FORCE_AUTH_JSON=1 --ak reasoning_effort=xhigh)
claude_args=(--agent claude-code --model anthropic/claude-opus-5
             --ae CLAUDE_FORCE_OAUTH=1
             --ae "CLAUDE_CODE_OAUTH_TOKEN=${CLAUDE_CODE_OAUTH_TOKEN:?run claude setup-token}"
             --ae CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000
             --ak reasoning_effort=max)

run() {  # run <job-name> <attempts> <extra args...>
  local name=$1 attempts=$2; shift 2
  echo "=== $name ($attempts attempt(s)) ==="
  harbor run -p "$TASK" --env docker --yes \
    -k "$attempts" -n "$CONCURRENCY" \
    --agent-setup-timeout-multiplier 3 \
    --job-name "$name" "$@"
}

# The reviewers allow one model substitution (DeepSeek v4.1 flash, max) for a
# missing subscription. This submission's recorded runs use codex + DeepSeek,
# because the claude subscription's five-hour window could not hold a trial of
# this task and the paid route hit its spend cap (see docs/failure-analysis.md).
# DeepSeek is served through an OpenAI-compatible endpoint by harbor's own
# terminus-2 agent; set OPENAI_API_KEY and, if not using CommonStack, API_BASE.
deepseek_args=(--agent terminus-2 --model openai/deepseek/deepseek-flash-v4.1
               --ak api_base="${API_BASE:-https://api.commonstack.ai/v1}"
               --ak reasoning_effort=max
               --ae "OPENAI_API_KEY=${OPENAI_API_KEY:?set OPENAI_API_KEY for the DeepSeek endpoint}")

run run-codex     "$TRIALS" "${codex_args[@]}"
run run-deepseek  "$TRIALS" "${deepseek_args[@]}"
run cheat-codex   1 "${codex_args[@]}"    --extra-instruction-path "$CHEAT_PROMPT"
run cheat-deepseek 1 "${deepseek_args[@]}" --extra-instruction-path "$CHEAT_PROMPT"
# claude-code opus-5 (max), when a subscription or API budget that fits ~4 h
# of opus is available:
#   run run-claude  "$TRIALS" "${claude_args[@]}"
#   run cheat-claude 1 "${claude_args[@]}" --extra-instruction-path "$CHEAT_PROMPT"

for job in run-codex run-deepseek cheat-codex cheat-deepseek; do
  harbor analyze "jobs/$job" -m sonnet \
    -r docs/prompts/trial-analysis.toml \
    --job-prompt docs/prompts/trial-analysis-job.txt || true
done
