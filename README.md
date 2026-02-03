# Ultrawork - Intelligent Task Orchestration for Claude Code

> Zero-learning-curve intelligent task orchestration with Hive-mind consensus

Ultrawork is a Claude Code custom skill that provides Sisyphus-style autonomous task orchestration. It analyzes user intent, routes to optimal agents, and executes complex tasks with minimal human intervention.

## Features

- **Intent Analysis**: Automatically classifies tasks (Trivial, Explicit, Exploratory, Open-ended, Ambiguous)
- **Smart Routing**: Routes to appropriate models (haiku/sonnet/opus) based on task complexity
- **Skill Integration**: Auto-discovers and injects relevant skills from `~/.agent/skills/`
- **Hive-mind Consensus**: Multi-agent collaboration for complex architectural decisions
- **Learning System**: SONA + EWC++ pattern learning for improved future decisions
- **Ralph-loop Support**: Automatic retry until completion

## Quick Start

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ralph-loop/ultrawork/master/install.sh | bash
```

### Basic Usage

```bash
# In Claude Code, use the command:
/ultrawork Build a REST API for user authentication

# Or use the short alias:
/ulw Fix the login page bug
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--ralph-loop` | Auto-retry until completion | disabled |
| `-iter=N` | Max iterations for ralph-loop | 100 |
| `--completion-promise=TEXT` | Completion signal tag | "DONE" |
| `--force-swarm` | Force multi-agent coordination | disabled |
| `--no-skills` | Disable skill matching | enabled |

---

## Integration with Skills.sh & Claude-Flow

Ultrawork is designed to work seamlessly with the **Skills.sh** ecosystem and **Claude-Flow** MCP server.

### Skills.sh Integration

Ultrawork automatically discovers and injects skills installed via [Skills.sh](https://skills.sh):

```bash
# Install skills from the ecosystem
npx skills add anthropics/analysis
npx skills add anthropics/git-master

# Ultrawork auto-detects and uses them
/ulw Analyze codebase and commit changes
```

**How it works:**
1. **Phase 0**: Scans `~/.agent/skills/` for installed skills
2. **Lazy Loading**: Indexes only metadata (95% token savings)
3. **Vector Matching**: Finds relevant skills in <5ms
4. **On-Demand Injection**: Loads full skill content only when needed

### Claude-Flow MCP Integration

For advanced orchestration features, Ultrawork integrates with [Claude-Flow](https://github.com/ruvnet/claude-flow):

```bash
# Install claude-flow MCP server
npx claude-flow init
```

**Unlocked Features:**
| Feature | MCP Tool | Description |
|---------|----------|-------------|
| Hive-mind Consensus | `mcp__claude-flow__hive-mind_*` | Multi-agent voting & decisions |
| Persistent Memory | `mcp__claude-flow__memory_*` | Cross-session state management |
| Pattern Learning | `mcp__claude-flow__hooks_intelligence_*` | SONA + EWC++ learning system |
| Swarm Orchestration | `mcp__claude-flow__swarm_*` | Parallel agent coordination |

**Without Claude-Flow**: Ultrawork still works using Claude Code's built-in agents, but advanced features like Hive-mind consensus and persistent learning are disabled.

---

## Examples

### Feature Implementation
```bash
/ulw Add user authentication API with JWT tokens
```
Ultrawork will: analyze codebase → decide architecture → implement → test → verify

### Bug Fix
```bash
/ulw Fix the error on login page
```
Ultrawork will: analyze error → minimal fix → verify (no unnecessary refactoring)

### Complex Refactoring with Ralph-loop
```bash
/ulw Migrate authentication to JWT --ralph-loop -iter=20
```
Ultrawork will: plan migration → execute step-by-step → verify → retry until done

---

## Requirements

- **Required**: Claude Code CLI
- **Optional**: claude-flow MCP server (for advanced features)
- **Optional**: Skills.sh skills (for domain-specific capabilities)

## Uninstallation

```bash
curl -fsSL https://raw.githubusercontent.com/ralph-loop/ultrawork/master/uninstall.sh | bash
```

To also remove cache, settings, and learned patterns:
```bash
curl -fsSL https://raw.githubusercontent.com/ralph-loop/ultrawork/master/uninstall.sh | bash -s -- --purge
```

## Configuration

Settings are stored in `~/.agent/ultrawork/`:
- `config.json`: User preferences
- `patterns.json`: Learned patterns cache

## Core Principles (from Ultrawork Manifesto)

1. **Human Intervention = Failure Signal**: Agents should work autonomously
2. **Indistinguishable Code**: Output indistinguishable from senior engineer's work
3. **Delegatable**: Trust agents like a reliable team member

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [oh-my-opencode](https://github.com/opencode-ai/oh-my-opencode) Sisyphus orchestration
- Built on [claude-flow](https://github.com/ruvnet/claude-flow) MCP infrastructure
- Integrated with [Skills.sh](https://skills.sh) ecosystem
