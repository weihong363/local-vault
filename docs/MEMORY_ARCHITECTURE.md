# Memory Architecture

## Overview

Local Vault evolves into a unified local-first memory system built on three layers:

- KV State (operational)
- Summary (semantic)
- Archive (historical)

Goal: fast reads, safe writes, controllable compression, recoverable history.

---

## Core Model

### KV State

- Purpose: active working memory
- Traits: small, structured, mutable, low-latency
- Examples: session state, preferences, task context
- Rule: keep lightweight, compress or archive when stale

### Summary

- Purpose: reusable semantic memory
- Traits: compact, mergeable, meaningful
- Examples: facts, summaries, preferences
- Rule: must be denser than source, avoid duplication

### Archive

- Purpose: source-of-truth history
- Traits: append-only, durable, large
- Examples: raw notes, old versions, logs
- Rule: never treat as trash, always recoverable

---

## Layer Relationship

- State → live
- Summary → distilled
- Archive → history

Flow:
input → route → write (state/archive) → compress → summary → retrieve

Not all writes affect all layers.

---

## Unified Memory API

### Read

```ts
readMemory(query, options)
```

- Prefer: state → summary → archive
- Return minimal sufficient data
- Avoid full archive scan

### Write

```ts
writeMemory(input, options)
```

- Modes: create / update / merge / append
- Must define: tier, merge strategy, archive behavior
- Rule: no silent overwrite, preserve provenance

### Compress

```ts
compressMemory(input, options)
```

- Transform: state/archive → summary
- Rule: explainable, reviewable, reversible (if possible)

---

## Memory Lifecycle

1. input
2. normalize
3. route
4. write (state/archive)
5. evaluate compression
6. update summary
7. index
8. return

Compression is conditional.

---

## Routing

Decides:

- which tier(s) to write
- whether to compress
- how to merge

Examples:

- preference → state + summary
- quick note → archive
- repeated topic → summary merge

---

## Compression

Goals:

- reduce size
- remove duplication
- improve reuse

Triggers:

- size / token threshold
- inactivity
- semantic overlap

Avoid:

- compressing every write
- deleting source data
- duplicate summaries

---

## Merge

- merge by semantic identity
- preserve old versions in archive
- keep merge explainable

---

## Retrieval

Modes:

- operational → state + summary
- search → summary + source
- historical → archive

Rule: smallest sufficient set.

---

## Provenance

Track:

- source
- parent/child
- version
- merge lineage

Rule: all destructive changes must be recoverable.

---

## Model Usage

Allowed:

- summarization
- tagging
- merge suggestion

Not allowed as mandatory:

- write path
- read path

Rule: always have deterministic fallback.

---

## Storage

- local-first
- incremental migration
- backward compatible

---

## Recommended Modules

- MemoryFacade
- MemoryRouter
- StateStore
- SummaryStore
- ArchiveStore
- CompressionService

---

## Success Criteria

- fast reads
- safe writes
- useful summaries
- recoverable archive
- minimal duplication
- offline capable