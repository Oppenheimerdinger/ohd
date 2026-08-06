# Archive

Settled history that no longer needs to be read, kept where grep can still
reach it. This directory lives under the SAME grep root as the live docs on
purpose: archiving is about read cost, not about hiding evidence.

## What moves here

Campaign docs whose verdict is filled and whose follow-ons are closed; plans
and specs whose work has been executed (an executed plan archives together with
its campaign); analyses superseded by a later result.

## When it runs — a FIXED tax, never a per-land one

Solidation runs at **checkup or milestone time**, never per land. Per-land
cleanup makes the ritual's fixed overhead grow with corpus size, which is the
cost this whole tier exists to remove. `/ohd-checkup structure` generates the
candidate list; moving the files is ordinary project work driven by that list —
the harness never bulk-moves your documents itself.

## The one hard rule: preserve the search key

A claim that gets retracted, superseded, or archived **keeps its literal search
key in the live tier**, pointing here:

```
~~old claim, as written~~ → archive/<file>.md
```

Sessions and agents find things by grepping the words they remember. Moving a
document without leaving its key behind does not just hide the old answer — it
makes the search come back EMPTY, and an empty search reads as "this was never
investigated", which is how settled work gets re-derived from scratch.
