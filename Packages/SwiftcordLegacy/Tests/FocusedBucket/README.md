# Focused Bucket regression tests

From this package directory run:

```sh
bash Tests/FocusedBucket/run.sh
```

The runner compiles only the production Bucket and LegacyWorkItem sources plus
this standalone host entry point, in Swift 5 language mode. The entry point
uses the same public `DispatchWorkItem = LegacyWorkItem` alias as Gateway,
not Apple's dispatch-block-backed work item. No application build, package
resolution, UIKit, or SocketRocket is required. Binaries go to a printed temporary
directory outside the repository.

Coverage:

- Current generation: a limit of two, five FIFO items, exactly-once execution,
  and no early reuse of either slot.
- Reset with old replenishments pending: a semaphore holds the bucket's serial
  queue while reset and new work are submitted, then keeps it held until an old
  timer is due. This forces the stale callback to encounter current queued work.
  Only pre-reset pending work is discarded; all five current items survive,
  in FIFO order, without borrowing old generation capacity.
- Empty/repeated reset: let an invalidated timer fire while the new generation
  has no work, then verify limit-one spacing. This detects a negative counter
  behaviorally, without exposing private production state.

Intervals are 160 ms, with a 15 ms early-execution tolerance. Sequencing uses
bounded semaphores and the bucket's serial submission order, not unsynchronized
shared state or arbitrary sleeps. Every execution wait has a three-second
failure timeout. Delayed execution on a loaded host is allowed; only premature
execution fails the rate assertions.

Each reset regression can also run independently:

```sh
bash Tests/FocusedBucket/run.sh --pending-reset
bash Tests/FocusedBucket/run.sh --empty-reset
```

For regression sensitivity checks, `BUCKET_SOURCE=/absolute/path/to/Bucket.swift`
selects an alternate implementation without altering production sources. Against
the original implementation, `--pending-reset` fails because current queued work
is removed, and `--empty-reset` fails because the stale timer grants extra capacity.
