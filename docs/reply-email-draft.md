# Draft reply to Klavis (for Zeyu to send; not sent by the assistant)

Subject: Re: BOSS直聘：创始工程师 - 大模型数据 — Terminal-Bench task submission

Hi Xiangkai,

Here is my submission for the coding test: REPO_URL

One original Terminal-Bench 3 task, `vllm-stream-args`: vLLM at a pinned
commit has three streaming tool-call parsers whose streamed `arguments` depend
on how the decoder chunks the model output; the agent must fix them in place so
the stream reproduces the non-streaming extractor byte-for-byte for any split,
while still streaming incrementally and in linear time. It passes all TB3 CI
checks (22 static checks, rubric review 33/2/0, oracle 85/85, nop 5/85).

Honest headline on the trial requirement: it is not met. Under the CI's exact
configurations, codex gpt-5.6-sol (xhigh) failed 3 of 6 genuine trials across
two grader revisions (1 of 3 on the submitted revision) and claude-opus-5 (max)
failed 1 of 3. The repository documents every trial, the two earlier contract
versions that probes defeated, a verifier hole a `/cheat` trial found
(`pytest.skip` from inside the artifact) and the rebuilt verifier that closes
it, and a study of the seven earlier designs I built and probed before this one
— all solved. The failure analysis explains why I think the remaining lever for
tasks like this is not more engineering corners but domains whose oracle is not
readable from the repository.

I would be glad to discuss the design, the verification strategy, and the
model-failure analysis.

Best,
Zeyu Wang
