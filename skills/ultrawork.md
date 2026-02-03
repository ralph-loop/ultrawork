---
name: ultrawork
aliases: [ulw]
description: Zero-learning-curve intelligent task orchestration with Hive-mind consensus (Sisyphus-style)
---

# Ultrawork (ulw) - Intelligent Task Orchestration

> "Human Intent → Agent Execution → Verified Result"
> Ultrawork Manifesto: Users only need to express intent. Everything else is the agent's job.

## Usage

```
/ultrawork <task description in natural language> [options]
/ulw <task description in natural language> [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--ralph-loop` | Auto-retry until completion | disabled |
| `-iter=N` | Max iterations for ralph-loop | 100 |
| `--completion-promise=TEXT` | Completion signal tag content | "DONE" |
| `--force-swarm` | Force Swarm activation | disabled |
| `--no-skills` | Disable skill matching | enabled |

## Core Principles (from oh-my-opencode)

1. **Human Intervention = Failure Signal**: Minimize user intervention
2. **Indistinguishable Code**: Code indistinguishable from senior engineer's work
3. **Delegatable**: Delegate to agents like trusting a reliable team member

---

## Implementation (Claude-Flow Based)

When this command is invoked, execute the following phases automatically:

### Phase 0: Intelligent Intent Gate (Intent Analysis + Optimized Routing)

#### 0-1. Skills.sh Lazy Loading (Metadata Indexing Only)

**Context Optimization**: Index only metadata instead of loading full skill content

```typescript
// Scan skill directories (auto-detect skills installed via skills.sh)
const SKILL_PATHS = [
  "~/.claude/skills/",      // Global skills
  ".claude/skills/"         // Project skills
];

// Lazy Loading: Store metadata only (not full content)
for (const skillDir of scanSkillDirs(SKILL_PATHS)) {
  const skillMd = readFile(`${skillDir}/SKILL.md`);
  const { name, description } = parseFrontmatter(skillMd);
  const contentSize = skillMd.length;  // Record content size

  // 1. Store metadata only (exclude content)
  mcp__claude-flow__memory_store({
    key: `skill_${name}`,
    namespace: "skills",
    value: {
      name,
      description,
      path: skillDir,
      contentSize,  // For reference when loading
      loadedAt: null  // Record actual load time
    },
    tags: ["skill", "registry", "lazy"]
  });

  // 2. HNSW indexing (description only - token savings)
  mcp__claude-flow__hooks_intelligence_pattern-store({
    pattern: `${name}: ${description}`,  // Not full content
    type: "skill-description",
    confidence: 1,
    metadata: { skillName: name, path: skillDir }
  });
}
```

**Token Savings**: Average 2,000-5,000 tokens per skill → 100-200 tokens (95% reduction)

#### 0-2. User Request Analysis and Skill Matching (Deferred Loading)

```typescript
// Vector matching between user request and skills (<5ms)
const matchedSkills = mcp__claude-flow__hooks_intelligence_pattern-search({
  query: "<user request>",
  namespace: "pattern",
  topK: 3,
  minConfidence: 0.7  // 70%+ similarity (prevent false positives)
});

// Deferred Loading: Return metadata only, actual load in Phase 2C
// Do NOT load skillContent at this point!
const skillReferences = matchedSkills.map(skill => ({
  name: skill.metadata.skillName,
  path: skill.metadata.path,
  confidence: skill.confidence,
  loaded: false  // Not loaded yet
}));

// → Actual load when agent needs it (Phase 2C)
```

#### 0-3. Intent Classification

Analyze and classify user request:

| Type | Signal | Action |
|------|--------|--------|
| **Trivial** | Single file, clear location | Direct execution (Phase 2C) |
| **Explicit** | Specific file/line specified | Direct execution (Phase 2C) |
| **Exploratory** | "How does X work?", "Find Y" | Explore agent (Phase 2A) |
| **Open-ended** | "Improve", "Refactor", "Add feature" | Codebase evaluation (Phase 2A→2B) |
| **Ambiguous** | Unclear scope, multiple interpretations | **Phase 0.5 Clarification** (before Phase 1!) |

#### 0-4. Category + Model Auto-Selection (MoE-based) + Swarm Necessity Check

| Intent | Category | MoE Expert | Model | Swarm Needed | Phase Flow |
|--------|----------|------------|-------|--------------|------------|
| Trivial | `quick` | `coder` | `haiku` | No | 0→1→2C→3 |
| Explicit | `quick` | `coder`, `reviewer` | `haiku`/`sonnet` | No | 0→1→2C→3 |
| Exploratory | `research` | `researcher` | **`opus`** | No | 0→1→2A→3 |
| Open-ended (UI) | `visual-engineering` | `coder` | `sonnet` | Conditional | 0→1→2A→2B→2C→3 |
| Open-ended (Arch) | `ultrabrain` | `architect` | **`opus`** | Conditional | 0→1→2A→2B→2C→3 |
| **Ambiguous** | - | `coordinator` | `sonnet` | No | 0→**0.5**→reclassify→1→... |

**Model Routing Principles**:
- **Research/Analysis/Exploration** → `opus` (deep understanding needed)
- **Code Implementation/Modification** → `sonnet` (execution efficiency)
- **Simple Tasks** → `haiku` (cost optimization)

#### 0-5. Swarm Necessity Check (New)

```typescript
// Check Swarm activation conditions
function needsSwarm(intent: Intent, task: Task): boolean {
  // 1. Check force option
  if (options.forceSwarm) return true;

  // 2. Simple tasks don't need Swarm
  if (intent === "Trivial" || intent === "Explicit") return false;

  // 3. Check parallelization potential
  const parallelizable = analyzeParallelizability(task);

  // 4. Compare coordination overhead vs parallelization benefit
  const swarmBenefit = parallelizable.independentTasks >= 3;
  const coordinationOverhead = parallelizable.dependencies > 0;

  // 5. Decision
  return swarmBenefit && !coordinationOverhead;
}

// Examples where Swarm is needed:
// ✅ "Implement frontend, backend, and tests simultaneously" → 3 independent tasks
// ❌ "Add user auth API" → Sequential dependency (DB→API→Test)
// ❌ "Fix the bug" → Single task
```

### Phase 0.5: Clarification Gate (Resolve Ambiguity) - Before Phase 1!

**Resolve ambiguity before system initialization → Prevent unnecessary resource waste**

```typescript
// If classified as Ambiguous in Phase 0, or critical info is missing
// Execute BEFORE Phase 1 initialization → Prevent Swarm/memory/trajectory waste
if (intent === "Ambiguous" || hasCriticalAmbiguity(task)) {

  // 1. Analyze ambiguity - identify what's unclear
  const ambiguities = analyzeAmbiguity(task);

  // 2. Interactive questions via AskUserQuestion (max 4)
  const clarifications = await AskUserQuestion({
    questions: ambiguities.slice(0, 4).map(amb => ({
      question: amb.question,
      header: amb.category,  // Max 12 chars
      options: amb.options.map(opt => ({
        label: opt.label,
        description: opt.description
      })),
      multiSelect: amb.allowMultiple ?? false
    }))
  });

  // 3. Merge response into task context
  task.clarifications = clarifications;

  // 4. Reclassify intent (after clarification) → Proceed to Phase 1
  intent = reclassifyIntent(task);
  // Ambiguous → changes to Explicit/Open-ended/Exploratory etc.
}

// Ambiguity analysis function
function analyzeAmbiguity(task): Ambiguity[] {
  const ambiguities = [];

  // Scope ambiguity: "Refactor please" - where?
  if (task.hasVagueScope) {
    ambiguities.push({
      category: "Scope",
      question: "What scope should I target?",
      options: [
        { label: "Current file only", description: "Work only in the open file" },
        { label: "Related modules", description: "Include related files" },
        { label: "Entire project", description: "Target whole project" }
      ]
    });
  }

  // Approach ambiguity: "Improve performance" - how?
  if (task.hasMultipleApproaches) {
    ambiguities.push({
      category: "Approach",
      question: "Which approach should I take?",
      options: task.possibleApproaches.map(a => ({
        label: a.name,
        description: a.tradeoff
      }))
    });
  }

  // Priority ambiguity: "Add features" - which first?
  if (task.hasMultipleTargets) {
    ambiguities.push({
      category: "Priority",
      question: "Which should I handle first?",
      options: task.targets.map(t => ({
        label: t.name,
        description: t.impact
      })),
      allowMultiple: true
    });
  }

  return ambiguities;
}

// Check for critical missing information
function hasCriticalAmbiguity(task): boolean {
  if (!task.hasExplicitTarget && task.requiresTarget) return true;  // Target unclear
  if (task.scopeScore > 0.8) return true;  // Scope too broad
  if (task.hasConflictingRequirements) return true;  // Conflicting requirements
  return false;
}
```

**Clarification Example**:

```
User: "Improve the authentication system"

[Phase 0.5 Clarification Gate Triggered]
┌─────────────────────────────────────────────────┐
│ 🔍 Clarification needed                         │
├─────────────────────────────────────────────────┤
│ Q1. Scope                                       │
│ ○ Login only (Recommended)                      │
│ ○ Login + Registration                          │
│ ○ Entire auth flow                              │
├─────────────────────────────────────────────────┤
│ Q2. Approach                                    │
│ ○ Security - 2FA, token refresh                 │
│ ○ UX - Social login, auto-login                 │
│ ○ Performance - Caching, session optimization   │
└─────────────────────────────────────────────────┘

→ After user response, reclassify Intent → Proceed to Phase 1
```

### Phase 1: System Initialization (Conditional)

```typescript
// 1. Initialize Swarm only if needed (based on Phase 0-5 result)
if (needsSwarm) {
  mcp__claude-flow__hive-mind_init({
    topology: "hierarchical",
    queenId: "ultrawork-queen"
  })
}
// ❌ Skip Swarm initialization for simple tasks → Remove overhead

// 2. Store task context in memory (TTL for auto-cleanup)
mcp__claude-flow__memory_store({
  key: "ulw_current_task",
  namespace: "ultrawork",
  value: {
    request: "<original user request>",
    classification: "<task type>",
    startedAt: "<start time>",
    phase: "init",
    swarmEnabled: needsSwarm,
    skillRefs: skillReferences  // Metadata only from Phase 0-2 (no content)
  },
  tags: ["ultrawork", "task"],
  ttl: 3600  // Auto-delete after 1 hour (memory optimization)
})

// 3. Start intelligence trajectory (for learning)
mcp__claude-flow__hooks_intelligence_trajectory-start({
  task: "<task description>",
  agent: "ultrawork"
})
```

### Phase 2A: Exploration & Research (Conditional Parallel Execution)

**Explore = Contextual Grep (Internal)** - `sonnet`
**Librarian = Reference Grep (External)** - `opus` (deep research)

```typescript
// Execute only for Exploratory/Open-ended intents (skip for Trivial/Explicit)
if (intent === "Exploratory" || intent === "Open-ended") {

  // Internal codebase exploration (sonnet - fast search)
  Task({
    subagent_type: "Explore",
    model: "sonnet",  // sonnet is sufficient for code exploration
    run_in_background: true,
    prompt: "[CONTEXT] {what's being implemented} [GOAL] {what to achieve} [QUESTION] {what to find out}"
  })

  // External docs/reference exploration (opus - deep understanding)
  Task({
    subagent_type: "researcher",
    model: "opus",  // Research recommends opus
    run_in_background: true,
    prompt: "[CONTEXT] {what's being implemented} [GOAL] {verify best practices} [FIND] {official docs, examples}"
  })
}
// ❌ Skip research for Trivial/Explicit → Token savings
```

### Phase 2B: Hive-mind Consensus (Complex Decisions)

For complex architectural decisions or trade-offs:

```typescript
// 1. Create expert workers
mcp__claude-flow__hive-mind_spawn({
  count: 3,
  prefix: "expert",
  role: "specialist",
  agentType: "system-architect"  // Or appropriate expert type
})

// 2. Generate proposals and voting
mcp__claude-flow__hive-mind_consensus({
  action: "propose",
  type: "architecture-decision",
  value: {
    question: "<decision to make>",
    options: ["Option A", "Option B", "Option C"],
    context: "<relevant context>"
  }
})

// 3. Collect expert votes
mcp__claude-flow__hive-mind_consensus({
  action: "vote",
  proposalId: "<proposal ID>",
  voterId: "<expert ID>",
  vote: true  // or false
})

// 4. Check consensus result
mcp__claude-flow__hive-mind_consensus({
  action: "status",
  proposalId: "<proposal ID>"
})
```

### Phase 2C: Implementation (Delegation-based + Skill Injection)

**Category + Skill System** (Sisyphus style):

| Category | Domain | Claude-Flow Agent | Auto-matched Skills Example |
|----------|--------|-------------------|---------------------------|
| `visual-engineering` | Frontend, UI/UX | `frontend-dev` | `agent-browser`, `frontend-ui-ux` |
| `ultrabrain` | Complex architecture | `system-architect` | - |
| `quick` | Simple tasks | `coder` (haiku) | `git-master` |
| `writing` | Documentation | `api-docs` | - |
| `testing` | Testing | `tester` | `agent-browser` (E2E) |

#### Skill On-Demand Loading (Context Optimization)

```typescript
// Skills are loaded only when agent "needs" them
// Phase 0 passes metadata only, actual content loaded here
function buildDelegationPrompt(task, skillRefs) {
  let skillContext = "";

  // Load only if skill reference exists and actually needed
  if (skillRefs.length > 0 && shouldLoadSkill(task, skillRefs[0])) {
    const skillRef = skillRefs[0];

    // Load skill content for the first time here (Lazy)
    const skillContent = readFile(`${skillRef.path}/SKILL.md`);

    // v3: Load full skill regardless of size
    // (Removed 3000 char limit from previous version - fully utilize skill features)
    const loadedContent = skillContent;

    skillContext = `
<loaded-skill name="${skillRef.name}" confidence="${skillRef.confidence}">
${loadedContent}
</loaded-skill>

Follow the guidelines from the skill above to perform the task.
`;

    // Record load (for learning)
    mcp__claude-flow__memory_store({
      key: `skill_load_${Date.now()}`,
      namespace: "skill-usage",
      value: { skill: skillRef.name, task: task.objective, loadedAt: new Date() },
      ttl: 86400  // Auto-delete after 24 hours
    });
  }

  return `${skillContext}
1. TASK: ${task.objective}
2. EXPECTED OUTCOME: ${task.expectedOutcome}
3. MUST DO: ${task.requirements}
4. MUST NOT DO: ${task.restrictions}
5. CONTEXT: ${task.context}`;
}

// Determine if skill loading is needed
function shouldLoadSkill(task, skillRef): boolean {
  // Don't load if confidence < 70% (prevent false positives)
  if (skillRef.confidence < 0.7) return false;

  // Skill loading unnecessary for simple tasks (Trivial)
  if (task.intent === "Trivial") return false;

  return true;
}

// Apply model routing when spawning agent
mcp__claude-flow__agent_spawn({
  agentType: "<appropriate type>",
  model: task.requiresResearch ? "opus" : "sonnet",  // Research=opus, Implementation=sonnet
  task: buildDelegationPrompt(task, skillRefs),
  config: { swarmId: needsSwarm ? "<current swarm ID>" : undefined }
})
```

**Delegation Prompt Structure (MANDATORY):**
```
[Skill Context - Auto-injected]
1. TASK: Atomic, specific goal
2. EXPECTED OUTCOME: Specific deliverable with success criteria
3. MUST DO: Required requirements (nothing implicit)
4. MUST NOT DO: Prohibited actions
5. CONTEXT: File paths, existing patterns, constraints
```

### Phase 2D: Todo Management (Progress Tracking)

```typescript
// Before starting task - Create Todo
TaskCreate({
  subject: "<task title>",
  description: "<detailed description>",
  activeForm: "<in-progress display text>"
})

// When starting task
TaskUpdate({ taskId: "<ID>", status: "in_progress" })

// When task completes - Mark complete immediately (no batching)
TaskUpdate({ taskId: "<ID>", status: "completed" })
```

### Phase 2.5: Ralph-loop Trigger (When --ralph-loop option used)

**Utilize Native `/ralph-loop` Plugin** (claude-plugins-official)

```typescript
// If ralph-loop option is active
if (options.ralphLoop) {
  // ✅ Trigger native /ralph-loop plugin
  // Plugin auto-handles repeat via Stop hook
  Skill({
    skill: "ralph-loop:ralph-loop",
    args: `"${originalTask}" --max-iterations ${options.iter ?? 100} --completion-promise "${options.completionPromise ?? 'DONE'}"`
  });

  // Or construct prompt directly:
  // /ralph-loop "<task>" --max-iterations N --completion-promise "DONE"
}
```

**Native Ralph-loop Behavior**:
```
┌──────────────────────────────────────────────────────────────┐
│  /ulw "task" --ralph-loop -iter=10                           │
└──────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Skill("ralph-loop:ralph-loop") trigger                      │
│  → /ralph-loop "task" --max-iterations 10                    │
└──────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Native Ralph-loop Plugin (Stop hook based)                  │
│  ├─ 1. Execute task                                          │
│  ├─ 2. Claude attempts to stop                               │
│  ├─ 3. Stop hook blocks termination                          │
│  ├─ 4. Re-inject same prompt                                 │
│  └─ 5. Repeat until <promise>DONE</promise> output           │
└──────────────────────────────────────────────────────────────┘
```

**Ralph-loop Option Mapping**:

| ultrawork option | ralph-loop option | Description |
|-----------------|-------------------|-------------|
| `--ralph-loop` | (activate) | Enter Ralph loop mode |
| `-iter=N` | `--max-iterations N` | Max iteration count |
| `--completion-promise=TEXT` | `--completion-promise "TEXT"` | Completion signal |

**Usage Examples**:
```bash
# Use ralph-loop with ultrawork
/ulw "Implement REST API. Output <promise>DONE</promise> when complete" --ralph-loop -iter=20

# Above command works same as:
/ralph-loop "Implement REST API..." --max-iterations 20 --completion-promise "DONE"
```

**Cancel Method**:
```bash
/cancel-ralph
```

### Phase 3: Verification & Completion

```typescript
// 1. Verification
// - Build/lint check for changed files
// - Run tests (if available)
// - Verify existing pattern compliance

// 2. Learn skill usage effect (pattern-store → HNSW indexing)
// v3: Use pattern-store instead of memory_store (utilize Claude-Flow learning system)
if (matchedSkills.length > 0) {
  mcp__claude-flow__hooks_intelligence_pattern-store({
    pattern: `task:${taskType} + skill:${skillName} = ${success ? 'success' : 'fail'}`,
    type: "skill-usage",
    confidence: success ? 0.9 : 0.3,
    metadata: {
      task: "<original request>",
      skill: skillName,
      outcome: success ? "success" : "failure"
    }
  });
}

// 3. End trajectory learning (SONA + EWC++ auto-execute)
// - trajectory-end call triggers SONA auto-pattern learning
// - EWC++ prevents catastrophic forgetting
mcp__claude-flow__hooks_intelligence_trajectory-end({
  trajectoryId: "<trajectory ID>",
  success: true,
  feedback: "<pattern to learn>"
})
// ↑ This call replaces ulw_result storage
// Claude-Flow auto-saves trajectory data to HNSW

// 4. Clean up background tasks
// Terminate all running background agents
```

**v3 Changes**: Removed separate `ulw_result_<timestamp>` storage
- Claude-Flow's `trajectory-end` auto-saves learning data
- SONA extracts patterns → pattern-store HNSW indexing
- Memory optimization by removing duplicate storage

---

## Failure Recovery (Phase 2E)

After 3 consecutive failures:

1. **STOP**: Immediately halt further edits
2. **REVERT**: Restore to last known good state
3. **DOCUMENT**: Record attempted actions and failure reasons
4. **CONSULT**: Discuss solutions via Hive-mind consensus
5. **ASK**: If Oracle can't resolve, ask user

---

## Examples

### Example 1: Feature Implementation
```
/ulw Add user authentication API
```
→ Analyze codebase → Architecture decision (consensus if needed) → Implement → Test → Complete

### Example 2: Bug Fix
```
/ulw Fix bug causing error on login page
```
→ Analyze error → Minimal fix → Verify → Complete (no refactoring!)

### Example 3: Complex Refactoring
```
/ulw Migrate this project's auth system to JWT
```
→ Analyze current structure → Hive-mind consensus (migration strategy) → Step-by-step implementation → Test → Complete

---

## Claude-Flow vs oh-my-opencode Feature Mapping

| oh-my-opencode | Claude-Flow (Preferred) |
|----------------|------------------------|
| Sisyphus swarm | `swarm_init` + `agent_spawn` |
| Oracle | `hive-mind_consensus` |
| explore agent | `Task(subagent_type="Explore")` |
| librarian agent | `Task(subagent_type="researcher")` |
| Background agents | `Task(run_in_background=true)` |
| Todo tracking | `TaskCreate`, `TaskUpdate` |
| Memory/Wisdom | `memory_store`, `memory_retrieve` |
| Learning | `hooks_intelligence_trajectory-*` |
| **load_skills** | **`pattern-search` + prompt injection** |
| **Skill discovery** | **Auto-scan `~/.claude/skills/`** |

---

## Skills.sh Integration Summary

```
┌──────────────────────────────────────────────────────────────┐
│  Skills.sh Auto-Integration Pipeline                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  npx skills add <owner/repo>                                  │
│       ↓                                                       │
│  ~/.claude/skills/<skill-name>/SKILL.md                       │
│       ↓                                                       │
│  [Phase 0] Auto-scan + HNSW indexing                          │
│       ↓                                                       │
│  User request → Vector matching (<5ms)                        │
│       ↓                                                       │
│  [Phase 2C] Skill context → Agent prompt injection            │
│       ↓                                                       │
│  [Phase 3] Learn skill usage result → Improve next matching   │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

**Installed Skills Examples**:
- `agent-browser`: Browser automation, web testing, screenshots
- `git-master`: Git commits, branch management
- `frontend-ui-ux`: UI/UX design guidelines

---

## Optimization Summary (v3)

### Token Optimization

| Item | Before | After | Savings |
|------|--------|-------|---------|
| Skill indexing | Full content (2-5K) | Metadata only (100-200) | **95%** |
| Skill loading | Always load | On-Demand (full load when needed) | **70%** (avg) |
| Research execution | Always run | Conditional | **50%** |
| Learning storage | Separate `ulw_result_*` | Auto-learn via `trajectory-end` | **100%** duplicate removal |

### Memory Optimization

| Item | Improvement |
|------|-------------|
| TTL setting | Auto-delete after 1 hour |
| Skill usage logs | Auto-delete after 24 hours |
| Session context | Store metadata only |
| Learning data | Vector search optimized via HNSW indexing |

### Context Optimization

| Item | Improvement |
|------|-------------|
| Swarm initialization | Only when needed (Phase 0-5 decision) |
| Skill loading | Lazy + On-Demand (no size limit) |
| Learning system | SONA + EWC++ auto pattern extraction |
| **Clarification Gate** | Phase 0.5 (before init) → Prevent Swarm/memory/trajectory waste |

### Model Routing Optimization

| Task Type | Model | Reason |
|-----------|-------|--------|
| Research/Analysis | `opus` | Deep understanding, comprehensive judgment |
| Code Implementation | `sonnet` | Fast execution, cost efficient |
| Simple Tasks | `haiku` | Lowest cost |

### v3 Learning System Integration

| Component | Role |
|-----------|------|
| SONA | Self-Optimizing Neural Architecture - trajectory learning |
| EWC++ | Elastic Weight Consolidation - prevent catastrophic forgetting |
| HNSW | Vector search indexing (78% cache hit rate) |
| MoE | 8 expert routing (coder, tester, reviewer, etc.) |
| LoRA | Low-Rank Adaptation (rank=8, alpha=16) |

---

## Communication Style

- **Start immediately**: No greetings like "Starting work now"
- **No flattery**: No "Great question!"
- **No status updates**: Track progress via Todo
- **Be concise**: Don't explain unless asked
- **Match user style**: Short question → short answer
