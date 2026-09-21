# Docker build — vllm-stream-args

The CI's `validate-task` workflow builds the task's environment image before
running oracle and nop. Both that image and the verifier image were built from
the submitted files on 2026-09-21:

```
$ docker build -t task-env-vllm-stream-args   tasks/vllm-stream-args/environment
$ docker build -t task-tests-vllm-stream-args tasks/vllm-stream-args/tests
```

```
=== environment image (the CI's docker-build step)
 ---> 9c62cb119ad4
Successfully built 9c62cb119ad4
Successfully tagged task-env-vllm-stream-args:latest

=== verifier image (tests/)
 ---> 40de21e23aac
Successfully built 40de21e23aac
Successfully tagged task-tests-vllm-stream-args:latest
```

Every oracle, nop and trial run recorded in this directory built the same two
images through harbor, so the build is exercised on every run as well.
