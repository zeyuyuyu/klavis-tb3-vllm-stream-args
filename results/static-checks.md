# Static checks — vllm-stream-args

Run on 2026-09-19 against harbor-framework/terminal-bench at commit 7a337a8 with harbor 0.23.0:

```
check-allow-internet.sh              PASS
check-canary.sh                      PASS
check-compose-host-binds.sh          PASS
check-dockerfile-platform.sh         PASS
check-dockerfile-references.sh       PASS
check-dockerfile-sanity.sh           PASS
check-gpu-types.sh                   PASS
check-instruction-suffix.sh          PASS
check-no-allow-internet-true.sh      PASS
check-nproc.sh                       PASS
check-pip-pinning.sh                 PASS
check-pytest-version.sh              PASS
check-separate-verifier.sh           PASS
check-task-absolute-path.sh          PASS
check-task-fields.sh                 PASS
check-task-package-name.sh           PASS
check-task-slug.sh                   PASS
check-task-timeout.sh                PASS
check-test-file-references.sh        PASS
check-test-sh-sanity.sh              PASS
check-trial-network-fetch.sh         PASS
check-verifier-tooling-baked.sh      PASS
```

check_ai_detection.py needs GPTZERO_API_KEY and is skipped locally; it is a CI-side check.
