# Per-task deadlines for Tinypool

Repository: tinylibs/tinypool
Base commit: abc247f85cba0309e3f1e5655db1837a2a1c2483

Add a per-task wall-clock deadline to Tinypool: on overrun, optionally grant a finish window, then terminate the worker.

The `Tinypool` constructor and each `run()` accept `taskTimeout` and `gracePeriod` (ms). Export `TaskTimeoutError` and `TinypoolEvent`, equal to `{ TaskTimeout: 'taskTimeout', TaskTimeoutGrace: 'taskTimeoutGrace', TaskTimeoutTermination: 'taskTimeoutTermination' }`. Add pool getters `taskTimeoutCount`, `taskTimeoutGraceCount`, `taskTimeoutTerminationCount`, and `deadlineStats` (a `{ timeouts, graceEntries, terminations }` snapshot), initially 0.

`taskTimeout` of `0`, `Infinity`, or absent means no deadline; any other must be positive and finite; negative, `NaN`, or non-number values throw `TypeError`. `gracePeriod` is the same but must be finite (so `Infinity` throws); absent or `0` means no grace. Validated at construction and per call, the error names the option. For example, `taskTimeout: 0` has no deadline while `-1` throws. A per-call value overrides the pool default; an omitted one inherits it.

The budget starts when a task is dispatched, not while queued. On expiry the pool emits `taskTimeout`. With grace it emits `taskTimeoutGrace` and waits; a task that settles within it resolves or rejects normally and is not terminated. Otherwise the worker is terminated, `taskTimeoutTermination` is emitted, and the caller rejects with a `TaskTimeoutError`.

That error has `name` `TaskTimeoutError`, `code` `ETASKTIMEOUT`, a message with the timeout, and fields `taskTimeout`, `gracePeriod`, `graceEntered`, `teardownAttempted`, `teardownCompleted`. Event payloads carry `taskId`, `workerId`, and the resolved `taskTimeout` and `gracePeriod`; `taskTimeoutTermination` adds those three booleans and the same `taskId`.

A configured `teardown` runs before the worker dies, bounded by `terminateTimeout`; one that throws or overruns surfaces on the pool `error` event with `teardownCompleted` false. An `AbortSignal` firing before the deadline yields `AbortError` with no breach. `pool.destroy()` after a breach still rejects with `TaskTimeoutError`. Deadlines are per task under `concurrentTasksPerWorker > 1`. `deadlineStats` is an independent copy; with neither option set, nothing changes.
