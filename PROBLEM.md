# Challenge: Per-Task Deadline with Cooperative Grace Period

## Repository
- **URL**: https://github.com/tinylibs/tinypool
- **Base commit**: abc247f

## Problem

Add a per-task deadline mechanism to the Tinypool worker pool. A task may be given a wall-clock budget; when it overruns, the pool grants it a short cooperative window to finish, and failing that, hard-terminates its worker and rejects the caller with a typed error. The feature must compose with the existing `teardown`, `terminateTimeout`, and AbortSignal behaviour.

## API surface

Two new options, `taskTimeout` and `gracePeriod` (both in milliseconds), accepted both on the constructor and per call. `taskTimeout` is the budget a task may run after it is dispatched to a worker before a deadline breach is recorded. `gracePeriod` is a cooperative window granted after a breach before the worker is hard-terminated; `0` means terminate immediately.

One new export, `TaskTimeoutError`, with `name === 'TaskTimeoutError'` and the numeric/boolean fields `taskTimeout`, `gracePeriod`, `graceEntered`, `teardownAttempted`, and `teardownCompleted`.

Two read-only counters on the pool: `taskTimeoutCount` (breaches) and `taskTimeoutTerminationCount` (hard terminations).

## Required behaviour

- The deadline timer starts when the task is dispatched, not when it is enqueued: time spent waiting in the queue must not consume the budget.
- On breach, emit a `taskTimeout` event and increment `taskTimeoutCount`. If the task settles within the grace window it resolves or rejects naturally and is not terminated; otherwise the worker is hard-terminated.
- On hard termination, run the worker's `teardown` (if configured) on that same worker before it dies, emit a `taskTimeoutTermination` event, increment `taskTimeoutTerminationCount`, and reject the caller with a `TaskTimeoutError` whose fields report what happened.
- Both event payloads carry a numeric `taskId` and `workerId` along with the effective per-call `taskTimeout` and `gracePeriod` (the values resolved for that call, not the pool defaults); the `taskTimeoutTermination` payload additionally carries a boolean `teardownAttempted`.
- Teardown is bounded by `terminateTimeout`, so caller rejection cannot be delayed beyond it. A teardown that throws and a teardown that exceeds `terminateTimeout` both surface on the pool's `error` event and leave `teardownCompleted` false, without crashing the host.
- An AbortSignal takes precedence: aborting before the deadline yields an `AbortError` with no breach recorded, and aborting during the grace window short-circuits the grace.
- Calling `pool.destroy()` after a deadline has already breached still rejects the in-flight caller with a `TaskTimeoutError`.
- Per-call options override the pool defaults. The deadline applies independently to each in-flight task on a worker running more than one at a time, and behaves identically under the `worker_threads` and `child_process` runtimes.
- A `taskTimeout` of `0`, negative, `NaN`, or otherwise non-finite is treated as no deadline. A `gracePeriod` that is negative, `NaN`, or non-finite is treated as `0`, i.e. immediate termination. With both options unset, existing pool behaviour is unchanged.
