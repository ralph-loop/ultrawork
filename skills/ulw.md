---
name: ulw
description: Alias for /ultrawork - Zero-learning-curve intelligent task orchestration with Hive-mind consensus
allowed-tools: '*'
---

# ULW (Ultrawork Alias)

This is a shorthand alias for `/ultrawork`. All arguments are passed through.

## Usage

```bash
/ulw [task]
/ulw --ralph-loop -iter=N [task]
/ulw --help
```

## Execution

When invoked, immediately trigger the ultrawork skill with all provided arguments:

```typescript
Skill({
  skill: "ultrawork",
  args: "$ARGUMENTS"  // Pass through all arguments
});
```

**IMPORTANT**: Do not process the task yourself. Immediately invoke `/ultrawork` with the exact same arguments provided to `/ulw`.

Example:
- `/ulw Build a REST API` → `/ultrawork Build a REST API`
- `/ulw --ralph-loop -iter=5 Fix all tests` → `/ultrawork --ralph-loop -iter=5 Fix all tests`
