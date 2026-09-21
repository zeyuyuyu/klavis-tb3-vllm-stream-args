(digits shown as 1 may have been redacted by harbor)

Analysis: The requested server-side parser changes have been implemented across the twelve target parser files, with a shared incremental JSON streaming helper added. All modified files pass Python syntax compilation and `git diff --check`. Runtime execution was not possible because the environment lacks torch, transformers, numpy, and pytest, but static validation completed successfully.
Plan: No further commands are needed. The implementation is ready for grading.
