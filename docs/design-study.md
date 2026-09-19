# Seven designs, measured

Written for the Klavis reviewers. This is the part of the submission I would
want read first: what I tried, what the models did to it, and what the
measurements changed my mind about.

## Summary

I built seven complete Terminal-Bench tasks for this submission, each attacking
a different theory of what makes a task hard for a frontier agent. Every one
was taken to the point where it passed the TB3 static checks, built under
Docker, and had a passing oracle and a failing nop — and then probed with the
CI's own agent configurations before any further polish.

| # | Task | Theory of difficulty | Fastest solve |
|---|------|----------------------|---------------|
| 1 | `eval-ledger-audit` | Recover ~12 coupled rules from documents, reconcile against published numbers | codex, inside a 5.8-minute budget |
| 2 | `rollout-episode-races` | Five concurrency defects visible only under fleet load | codex named 4 of 5 and the right fix architecture in under 5 minutes, by reading |
| 3 | `constrained-decode-masks` | A calibrated performance bar a naive rewrite cannot clear | codex, 6m42s |
| 4 | `grammar-decode-masks` v1 | Exact CFG semantics from a specification, no reference implementation | codex 17m22s; opus-5 used the full hour and solved it |
| 5 | `grammar-decode-masks` v3 | v1 plus 28 grammar families, adversarial vocabulary, a speed bar | codex **12m45s — faster than v1**; 3/3 in the full trial matrix |
| 6 | `conformal-coverage-repair` | Statistical correctness derived from a guarantee, silent failure modes | codex 8m35s; opus-5 solved it |
| 7 | `vm-cleanroom-reimpl` | 74 mutually independent instruction semantics, recoverable only by probing a stripped binary | codex 12m18s; 3/3 in the full trial matrix |

Fourteen probes across seven designs and two agents. Every one was solved.

## The measurement that mattered most

Design 5 is design 4 with more than twice the graded grammar families, a
vocabulary built so tokens straddle terminal boundaries, and a ninety-second
per-bundle cap that excludes re-deciding the prefix from scratch. It was solved
**four minutes faster** than the version it hardened.

That killed the theory I had been working under for four designs. Widening the
failure surface does nothing when the failure surface is *correlated*: an
implementation that gets the model of the problem right gets nearly every
corner at once, and one that does not fails on the first. There is no product
of independent probabilities to drive down.

Design 7 was built specifically to break that correlation. An instruction set
is the cleanest case of independent facts I could construct: knowing how `ADD`
sets carry tells you nothing about whether a shift of sixteen delivers the
departing bit to carry, whether a signed divide of −32768 by −1 wraps or
saturates, whether an unsigned divide by zero yields 0xFFFF or the dividend, or
whether a rotate through carry runs on a 16- or 17-bit cycle. Seventy-four
mnemonics, each needing its own experiment against a stripped binary that is
the only specification. `gpt-5.6-sol` recovered all of them, including every
boundary convention, in twelve minutes, matching the appliance byte for byte on
200 unseen programs.

## What each of the other designs showed

**Documents are not difficulty.** Hiding a scoring protocol across eight
operational documents and three partially-published artifacts, with a verifier
comparing nine run bundles at 1e-9, was solved inside six minutes. Reading
carefully and implementing exactly is what these models are best at.

**Textbook concurrency bugs are legible.** Five defects invisible to a
sequential worker — a shared PRNG pool, an idempotency record written after the
effect, an aliased mutable observation, a missing per-episode lock, a recycled
id cache leak. The agent ran nothing; it read 200 lines and named four of them
plus the correct fix architecture.

**A performance bar only bites if no standard recipe clears it.** The bar was
calibrated, not guessed: three implementations timed on the graded workload
(66.9s prototype, 16x incremental rewrite, 70x memoised), with the bar set so
the middle misses by 2.1x and the good clears by 2.2x. Sound bar, irrelevant
outcome — lazy determinisation with per-state memoisation is a known recipe.

**Removing the oracle helps and is not enough.** Shipping no reference
implementation tripled the time to solve and consumed opus-5's whole hour. Not
enough.

**Domain statistics did not transfer.** Stating a coverage guarantee and
refusing to state the construction, with three silent errors measured over 25
calibration draws — the (n+1) omission costing 0.907→0.873, the missing
test-point weight 0.929→0.878, one pooled threshold turning per-group coverage
of 0.894/0.897 into 0.966/0.838. Both models derived the right constructions.

## Why, with the evidence I could find

Two published numbers reframed this.

The TB 4.0 leaderboard in this repository records `gpt-5.6-sol` at **37.3%**
over 330 trials with a mean trial duration of 2388 seconds. Roughly 63% of
*merged* tasks defeat this model; all seven of mine landed in the 37%.

[Long-Horizon Terminal-Bench](https://zli12321.github.io/LHTB/) reports 29 of
46 tasks never solved by any model, only 7% of runs reaching the solve
threshold, and — the part that matters — **79% of unresolved runs timing out
while the agent is still making progress**, on tasks averaging 120-320 agent
steps. The bottleneck it identifies is long-horizon completion, not problem
solving.

My tasks are 20-40 step tasks. A frontier model with an eight-hour budget is
not short of steps on those. What is merged into this benchmark and does defeat
these models — FreeCAD impellers, photonic waveguide routing, glycan MS2
elucidation, Coq block bounds, SA-CCR regulatory capital — is specialist work
at length, where the difficulty is the domain rather than the engineering, and
where a domain expert spends days rather than hours building the task.

## Design 8: a real regression in a real codebase, graded on a property

The seven designs above share a shape: a self-contained problem the agent can
fully verify on its own. Design 8 changes the shape. It pins
`vllm-project/vllm` at commit `877dae9c` and asks for a fix to three of its
streaming tool-call parsers (Jamba, InternLM2, MiniCPM XML), whose streamed
`arguments` depend on how the decoder happened to chunk the model output. The
grader replays eight model outputs through 17 delivery schedules (single
characters, fixed sizes, whitespace and punctuation boundaries, everything in
one delta, six seeded random cuts) and compares the assembled stream with the
non-streaming extractor, which it first pins to literal expected values so it
cannot be weakened.

The contract went through three versions, each forced by a probe.

| version | contract | probe |
|---------|----------|-------|
| v1 | assembled arguments parse to the non-streaming object, identical across schedules | codex gpt-5.6-sol xhigh solved it in **25 min** by buffering each call until complete and emitting it whole |
| v2 | v1 + latency (name within 2 deltas, string arguments at most 16 characters behind, XML params within 2 deltas of closing) + throughput (150 000 characters one per delta in under 20 s) | codex (65 min) re-architected to append-only scanners with canonical `json.dumps` output; graded later by the v3 suite it passed every invariance, canonical-string, latency and throughput case and failed only the bookkeeping cases its instruction had not stated - so v2 as written would have been solved |
| v3 | v2 + assembled text byte-for-byte equal to the non-streaming `json.dumps` string, and the parser's `prev_tool_call_arr` / `streamed_args_for_tool` / `get_remaining_unstreamed_args()` consistent with what was sent; 31 outputs | official codex trials: fail (7 cases), fail (1 case), **solved** |
| v4 (submitted) | v3 + six more outputs drawn from the non-streaming code paths (text between `<\|plugin\|>` and `{`, missing `<\|action_end\|>`, two `<function>` blocks in one wrapper, single-quoted attributes, `<think>` prefix, `name` inside arguments) and one output the extractor rejects; verifier rebuilt around a privilege-dropped worker after a `/cheat` trial passed via `pytest.skip` | official codex trials: fail (2 cases), **solved**, **solved**; claude: **solved**, **solved**, fail (2 cases) |

Each tightening is a real requirement of the serving layer rather than an
artificial hurdle: clients render arguments as they arrive, these parsers run on
the per-token hot path, and `OpenAIServingChat` reconciles the streamed text
against `json.dumps` of the parsed arguments when the response finishes, so a
stream that echoes compact or ASCII-escaped model JSON produces a garbled tail
in production. Meeting all three at once needs a resumable scanner over the raw
text whose canonical output is provably a prefix of the final `json.dumps` -
with hold-back rules for unfinished escapes, surrogate pairs, numbers and keys -
and an equivalent incremental driver for the XML format. The reference took me
about six hours including the property tests that caught my own first two
attempts (a partial-JSON re-serialisation that is not prefix-stable on nested
objects, and a from-scratch rescan that is quadratic).

Two things this design taught me are worth stating plainly. A property-based
grader is only as strong as the degenerate solutions it forbids: invariance
alone is satisfied by not streaming at all. And once the property is
self-checkable, what separates a solve from a failure is not the property but
the *coverage of the agent's own harness*: every codex failure on v3/v4 was an
output shape the agent's self-written tests never generated (name after
arguments, a second block, tokenizer glyphs, text before the brace), and every
solve came from an agent that had gone and read the non-streaming code paths
instead of trusting `json.dumps`-shaped inputs. That is a coin the agent flips
per run - three heads and three tails in six official trials.

## What I would do next

- **Build for step count.** A task needing a sustained measure-adjust-re-run
  loop over many hours, where each cycle yields partial quantitative signal and
  no single insight collapses the work. Every design here admits one.
- **Probe before documenting.** Adopting a one-hour probe before any polish cut
  the cost of a refuted design from a full day to about seven minutes. It is
  the only part of this process that worked from the start, and I adopted it
  one design too late.
- **Pick a domain where the difficulty is the domain.** Seven designs in, every
  one was a software-engineering task in a different costume, which is exactly
  the category these models are strongest in.
