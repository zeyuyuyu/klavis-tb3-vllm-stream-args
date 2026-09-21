# Draft reply to Klavis (for Zeyu to send; not sent by the assistant)

Subject: Re: BOSS直聘：创始工程师 - 大模型数据 — Terminal-Bench task submission

Hi Xiangkai,

Here is my submission for the coding test: https://github.com/zeyuyuyu/klavis-tb3-vllm-stream-args

One original Terminal-Bench 3 task, `vllm-stream-args`: vLLM at a pinned
commit has twelve streaming tool-call parsers (twelve wire formats) whose
streamed `arguments` depend on how the decoder chunks the model output; the
agent must fix them in place so the stream reproduces each parser's own
non-streaming extractor byte-for-byte for any split, while still streaming
incrementally and in linear time. It passes all TB3 CI checks (22 static
checks, rubric review 33 pass / 2 N/A / 0 fail, oracle 229/229, nop 46/229).

Trial results, using the pair you confirmed (codex + DeepSeek as the
substitution for claude): codex gpt-5.6-sol (xhigh) failed all three official
trials and DeepSeek v4.1 flash (max) failed all three; every /cheat trial
(codex, DeepSeek, and claude-code) scored 0. All six counted failures are
agents that finished and declared success; none is a timeout or an
infrastructure error, and the infrastructure failures that did occur (claude's
rate windows, a gateway spend cap) are filed separately and not counted.

The repository documents every run, the four earlier grader versions and what
the models did to them (the three-parser versions were solved about half the
time, which is what motivated the twelve-parser version), a verifier hole a
/cheat trial found (pytest.skip from inside the artifact) and the rebuilt
verifier that closes it, and a study of the eight designs built and probed
before this one.

I would be glad to discuss the design, the verification strategy, and the
model-failure analysis.

Best,
Zeyu Wang
