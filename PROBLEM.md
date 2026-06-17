# Per-task deadlines for Tinypool

Repository: tinylibs/tinypool
Base commit: abc247f85cba0309e3f1e5655db1837a2a1c2483

Add a per-task wall-clock deadline to Tinypool: on overrun, optionally grant a finish window, then terminate the worker.

The `Tinypool` constructor and each `run()` accept `taskTimeout` and `gracePeriod` (ms). Export `TaskTimeoutError` and `TinypoolEvent`, equal to `{ TaskTimeout: 'taskTimeout', TaskTimeoutGrace: 'taskTimeoutGrace', TaskTimeoutTermination: 'taskTimeoutTermination' }`. Add pool getters `taskTimeoutCount`, `taskTimeoutGraceCount`, `taskTimeoutTerminationCount`, and `deadlineStats` (a `{ timeouts, graceEntries, terminations }` snapshot), initially 0.

`taskTimeout` of `0`, `Infinity`, `null`, or absent means no deadline; any other value must be a positive finite number, and a negative, `NaN`, or non-number value throws `TypeError`. `gracePeriod` is the same but must be finite (so `Infinity` throws); `0`, `null`, or absent means no grace. Validated at construction and per call; the error names the option. E.g. `taskTimeout: 0` has no deadline while `-1` throws. A per-call value overrides the pool default; an omitted one inherits it.

The budget starts when a task is dispatched, not while queued. On expiry the pool emits `taskTimeout`. With grace it emits `taskTimeoutGrace` and waits; a task that settles within it resolves or rejects normally and is not terminated. Otherwise the worker is terminated, `taskTimeoutTermination` is emitted, and the caller rejects with a `TaskTimeoutError`.

`TaskTimeoutError` is built from an object of `taskTimeout`, `gracePeriod`, `graceEntered`, `teardownAttempted`, `teardownCompleted`; `name` `TaskTimeoutError`, `code` `ETASKTIMEOUT`, message includes `taskTimeout`. Event payloads carry `taskId`, `workerId`, and the resolved `taskTimeout`/`gracePeriod`; `taskTimeoutTermination` adds the three booleans and the same `taskId`.

A `teardown` runs before the worker dies, bounded by `terminateTimeout`; one that throws or overruns surfaces on the pool `error` event with `teardownCompleted` false. An `AbortSignal` firing before the deadline yields `AbortError` with no breach. `pool.destroy()` after a breach still rejects with `TaskTimeoutError`. Deadlines are per task when `concurrentTasksPerWorker > 1`. `deadlineStats` is an independent copy; with neither set, nothing changes.
