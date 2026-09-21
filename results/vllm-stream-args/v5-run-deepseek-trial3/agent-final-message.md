(digits shown as 1 may have been redacted by harbor)

Analysis: The implementation covers all twelve requested parsers. Shared incremental streaming helpers handle JSON-wrapped tool calls with bounded per-delta work, DeepSeek V3 uses a dedicated incremental fenced-call streamer, xLAM supports its common wrappers incrementally, Llama supports standalone JSON tool calls, and MiniCPM5XML has a bounded single-string fast path with char-level argument emission. Compilation, direct chunking checks, and targeted parser regression tests pass.
Plan: No further commands are needed.
