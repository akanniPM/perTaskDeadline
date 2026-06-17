# Per-task deadlines for Tinypool

Repository: tinylibs/tinypool
Base commit: abc247f85cba0309e3f1e5655db1837a2a1c2483

Give a Tinypool task a wall-clock deadline; on overrun, optionally allow a grace window, then terminate the worker.

The `Tinypool` constructor and each `run()` accept `taskTimeout` and `gracePeriod` (ms). A pool `teardown` option, a string naming a function exported by the worker module, runs on termination bounded by `terminateTimeout`. Export `TaskTimeoutError` and `TinypoolEvent` = `{ TaskTimeout: 'taskTimeout', TaskTimeoutGrace: 'taskTimeoutGrace', TaskTimeoutTermination: 'taskTimeoutTermination' }`. Add getters `taskTimeoutCount`, `taskTimeoutGraceCount`, `taskTimeoutTerminationCount`, and `deadlineStats` (a `{ timeouts, graceEntries, terminations }` copy), initially 0.

`0`, `Infinity`, `null`, or absent disables `taskTimeout`; any other must be positive and finite, else `TypeError`. `gracePeriod` is the same but finite; `0`, `null`, or absent means no grace. Validated at construction and per call; the error names the option. A per-call value overrides the pool default, so per-call `taskTimeout: 0` opts out while `-1` throws.

The budget starts at dispatch, not in the queue. On expiry the pool emits `taskTimeout`; with grace it emits `taskTimeoutGrace` and waits, and a task that settles within it resolves or rejects normally and is not terminated. Otherwise the worker is terminated, `taskTimeoutTermination` fires, and the caller rejects with `TaskTimeoutError`, built from `{ taskTimeout, gracePeriod, graceEntered, teardownAttempted, teardownCompleted }` (`code` `ETASKTIMEOUT`, message includes `taskTimeout`). Payloads carry `taskId`, `workerId`, and resolved `taskTimeout`/`gracePeriod`; termination adds the three booleans. A teardown that throws or overruns surfaces on the pool `error` event with `teardownCompleted` false. An `AbortSignal` before the deadline yields `AbortError` with no breach. `pool.destroy()` after a breach still rejects `TaskTimeoutError`. Deadlines are per task when `concurrentTasksPerWorker > 1`; with neither option set, nothing changes.
