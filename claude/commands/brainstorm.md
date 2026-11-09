# Brainstorm

Structured brainstorming with parallel analysis agents for idea generation, problem solving, and exploration.

## Mode Selection

Parse `$ARGUMENTS` to determine brainstorming mode:

| Argument | Mode | Description |
|----------|------|-------------|
| (empty) | `feature` | Feature ideation and design |
| `feature` | `feature` | Feature ideation and design |
| `problem` | `problem` | Problem analysis and solutions |
| `architecture` | `architecture` | Architecture exploration and design |
| `refactor` | `refactor` | Refactoring strategy and approach |
| `tradeoffs` | `tradeoffs` | Compare approaches with pros/cons |
| `debug` | `debug` | Debugging strategy and hypotheses |

**Mode Configuration:**

| Mode | Agents | Focus |
|------|--------|-------|
| `feature` | 3 (Requirements, Implementation, Risks) | New functionality design |
| `problem` | 3 (Root Cause, Solutions, Validation) | Problem solving |
| `architecture` | 4 (Patterns, Components, Integration, Tradeoffs) | System design |
| `refactor` | 3 (Current State, Target State, Migration) | Code improvement |
| `tradeoffs` | 2 (Option Analysis, Recommendation) | Decision making |
| `debug` | 3 (Symptoms, Hypotheses, Verification) | Issue investigation |

---

## Phase 1: Context Gathering

Before launching agents, gather context:

### 1. Check for Project Directives

```bash
# Look for project-specific directives
if [ -f "context/directives.md" ]; then
    # Read context/directives.md
fi
if [ -f "CLAUDE.md" ]; then
    # Read CLAUDE.md for project context
fi
```

### 2. User Input Analysis

Parse `$ARGUMENTS` for:
- **Mode**: First word determines brainstorming mode
- **Topic**: Everything after mode is the topic/question
- **Scope**: If topic mentions specific files/areas, note them

Example: `problem why are PSI scores always zero for new entities`
- Mode: `problem`
- Topic: "why are PSI scores always zero for new entities"

### 3. Codebase Context (if applicable)

If the topic relates to code:
- Identify relevant files/directories
- Note recent changes (`git log --oneline -10`)
- Check for related tests

---

## Phase 2: Launch Parallel Agents

Launch agents **in parallel** using the Task tool based on selected mode.

### Mode: Feature

#### Agent 1: Requirements Analyst

**Model**: sonnet

```
Analyze the feature request and define clear requirements.

1. Core Requirements:
   - What problem does this solve?
   - Who is the user/beneficiary?
   - What are the must-have capabilities?
   - What are nice-to-have capabilities?

2. Constraints Analysis:
   - Technical constraints (existing architecture, tech stack)
   - Business constraints (timeline, resources)
   - Integration constraints (what must this work with?)

3. User Stories:
   - Write 3-5 user stories in "As a... I want... So that..." format
   - Include acceptance criteria for each

4. Scope Definition:
   - What's in scope for v1?
   - What's explicitly out of scope?
   - What questions need answering before proceeding?

Output: Structured requirements document with prioritized features
```

#### Agent 2: Implementation Strategist

**Model**: sonnet

```
Design implementation approach for the feature.

1. Architecture Impact:
   - What components need to be created/modified?
   - What's the data flow?
   - What APIs/interfaces are needed?

2. Implementation Options:
   - Option A: [approach] - pros, cons, effort
   - Option B: [approach] - pros, cons, effort
   - Recommended approach with rationale

3. Technical Design:
   - Key data structures
   - Main algorithms/logic
   - External dependencies needed

4. Implementation Plan:
   - Phase 1: [deliverables]
   - Phase 2: [deliverables]
   - Testing strategy

Output: Technical design document with recommended approach
```

#### Agent 3: Risk Assessor

**Model**: haiku

```
Identify risks and mitigation strategies.

1. Technical Risks:
   - What could go wrong technically?
   - Performance concerns?
   - Scalability issues?
   - Integration challenges?

2. Implementation Risks:
   - Complexity hotspots
   - Unknown unknowns
   - Dependency risks

3. Operational Risks:
   - Deployment concerns
   - Monitoring needs
   - Rollback strategy

4. Mitigations:
   - For each risk, propose mitigation
   - Identify risks that need resolution before starting

Output: Risk matrix with severity, likelihood, and mitigations
```

---

### Mode: Problem

#### Agent 1: Root Cause Analyst

**Model**: sonnet

```
Analyze the problem to identify root causes.

1. Problem Statement:
   - Restate the problem clearly
   - What are the symptoms?
   - When does it occur?
   - What's the impact?

2. Information Gathering:
   - What do we know?
   - What don't we know?
   - What assumptions are we making?

3. Root Cause Analysis:
   - Apply 5 Whys technique
   - Consider multiple possible causes
   - Look for systemic issues vs symptoms

4. Evidence:
   - What evidence supports each hypothesis?
   - What would disprove each hypothesis?
   - What additional data would help?

Output: Root cause analysis with ranked hypotheses
```

#### Agent 2: Solution Designer

**Model**: sonnet

```
Generate and evaluate potential solutions.

1. Solution Brainstorm:
   - Generate at least 3 distinct solutions
   - Include quick fixes and proper fixes
   - Consider unconventional approaches

2. Solution Evaluation:
   For each solution:
   - Effectiveness (does it solve the root cause?)
   - Effort (time, complexity, resources)
   - Risk (what could go wrong?)
   - Side effects (what else does it impact?)

3. Recommendation:
   - Recommended solution with rationale
   - Short-term vs long-term considerations
   - Implementation outline

4. Alternatives:
   - When to use alternative solutions
   - Combination approaches

Output: Evaluated solutions with clear recommendation
```

#### Agent 3: Validation Planner

**Model**: haiku

```
Design validation approach for the solution.

1. Success Criteria:
   - How do we know the problem is solved?
   - Measurable outcomes
   - Acceptance criteria

2. Testing Strategy:
   - Unit tests needed
   - Integration tests needed
   - Manual verification steps

3. Monitoring:
   - What to monitor post-fix
   - Alerting thresholds
   - Rollback triggers

4. Documentation:
   - What needs to be documented?
   - Runbook updates?
   - Knowledge sharing?

Output: Validation plan with specific tests and metrics
```

---

### Mode: Architecture

#### Agent 1: Pattern Analyst

**Model**: sonnet

```
Analyze applicable architectural patterns.

1. Requirements Analysis:
   - Functional requirements
   - Non-functional requirements (scale, performance, reliability)
   - Constraints

2. Pattern Identification:
   - List applicable patterns (e.g., microservices, event-driven, CQRS)
   - For each pattern:
     - How it applies to this problem
     - Benefits in this context
     - Drawbacks in this context

3. Pattern Combinations:
   - Which patterns work well together?
   - Which patterns conflict?

4. Precedents:
   - Similar systems and their architectures
   - Lessons learned from industry

Output: Pattern analysis with applicability assessment
```

#### Agent 2: Component Designer

**Model**: sonnet

```
Design the component structure.

1. Component Breakdown:
   - Major components/services
   - Responsibilities of each
   - Boundaries between components

2. Data Architecture:
   - Data models
   - Data flow between components
   - Storage requirements

3. Interface Design:
   - APIs between components
   - Events/messages
   - Contracts and schemas

4. Component Diagram:
   - ASCII diagram of component relationships
   - Key interactions highlighted

Output: Component design with clear boundaries and interfaces
```

#### Agent 3: Integration Analyst

**Model**: sonnet

```
Analyze integration requirements.

1. External Integrations:
   - Third-party services
   - Legacy systems
   - External APIs

2. Internal Integrations:
   - Existing systems to integrate with
   - Shared resources (databases, queues)
   - Authentication/authorization

3. Integration Patterns:
   - Synchronous vs asynchronous
   - API gateway needs
   - Message broker considerations

4. Failure Handling:
   - Circuit breakers
   - Fallbacks
   - Retry strategies

Output: Integration design with patterns and failure handling
```

#### Agent 4: Tradeoff Evaluator

**Model**: sonnet

```
Evaluate architectural tradeoffs.

1. Key Decisions:
   - List major architectural decisions
   - Options for each decision

2. Tradeoff Analysis:
   For each decision:
   - Option A vs Option B vs Option C
   - Pros and cons matrix
   - Impact on requirements

3. CAP/PACELC Analysis:
   - Consistency vs availability tradeoffs
   - Latency considerations

4. Recommendations:
   - Recommended decisions with rationale
   - What we're trading off and why
   - Reversibility of decisions

Output: Decision matrix with recommendations
```

---

### Mode: Refactor

#### Agent 1: Current State Analyst

**Model**: sonnet

```
Analyze the current state of the code.

1. Code Structure:
   - Current architecture/organization
   - Key components and relationships
   - Pain points and technical debt

2. Issues Identified:
   - Code smells
   - Violations of principles (DRY, SOLID)
   - Performance issues
   - Maintainability concerns

3. Dependencies:
   - Internal dependencies
   - External dependencies
   - Coupling analysis

4. Test Coverage:
   - Current test coverage
   - Test quality assessment
   - Gaps in testing

Output: Current state assessment with prioritized issues
```

#### Agent 2: Target State Designer

**Model**: sonnet

```
Design the target state after refactoring.

1. Goals:
   - What does success look like?
   - Measurable improvements
   - Principles to follow

2. Target Architecture:
   - Proposed structure
   - Component organization
   - Interface changes

3. Code Quality Targets:
   - Patterns to introduce
   - Patterns to remove
   - Naming conventions
   - Documentation standards

4. Comparison:
   - Current vs target side-by-side
   - Key differences highlighted

Output: Target state design with clear improvements
```

#### Agent 3: Migration Planner

**Model**: sonnet

```
Plan the migration from current to target state.

1. Migration Strategy:
   - Big bang vs incremental
   - Strangler pattern applicability
   - Feature flags needed

2. Migration Phases:
   - Phase 1: [scope, deliverables, validation]
   - Phase 2: [scope, deliverables, validation]
   - Phase N: [scope, deliverables, validation]

3. Risk Mitigation:
   - Risks at each phase
   - Rollback strategy
   - Testing at each phase

4. Success Criteria:
   - Definition of done for each phase
   - Final validation checklist

Output: Phased migration plan with rollback strategy
```

---

### Mode: Tradeoffs

#### Agent 1: Option Analyst

**Model**: sonnet

```
Analyze the options being compared.

1. Options Identified:
   - Option A: [description]
   - Option B: [description]
   - Option C: [description] (if applicable)

2. Criteria Definition:
   - Performance
   - Maintainability
   - Scalability
   - Cost/Effort
   - Risk
   - [Domain-specific criteria]

3. Detailed Analysis:
   For each option:
   - Technical details
   - Implementation approach
   - Assumptions
   - Unknowns

4. Comparison Matrix:
   | Criteria | Option A | Option B | Option C |
   |----------|----------|----------|----------|
   | ...      | ...      | ...      | ...      |

Output: Options analysis with comparison matrix
```

#### Agent 2: Recommendation Engine

**Model**: sonnet

```
Synthesize analysis into recommendation.

1. Summary:
   - Key differentiators between options
   - Critical factors for this decision

2. Recommendation:
   - Recommended option
   - Rationale (link to criteria)
   - Confidence level

3. Conditions:
   - When recommendation changes
   - If [condition], then [different choice]

4. Implementation Notes:
   - Quick start steps
   - Key considerations
   - Common pitfalls

Output: Clear recommendation with rationale and conditions
```

---

### Mode: Debug

#### Agent 1: Symptom Analyst

**Model**: sonnet

```
Analyze the symptoms of the issue.

1. Symptom Collection:
   - What exactly is happening?
   - What should be happening?
   - When did it start?
   - What changed recently?

2. Reproduction:
   - Steps to reproduce
   - Reproduction rate
   - Environment details

3. Impact Assessment:
   - Who/what is affected?
   - Severity
   - Urgency

4. Related Information:
   - Error messages
   - Logs
   - Metrics

Output: Symptom analysis with reproduction steps
```

#### Agent 2: Hypothesis Generator

**Model**: sonnet

```
Generate debugging hypotheses.

1. Hypothesis List:
   - H1: [hypothesis] - likelihood, evidence for/against
   - H2: [hypothesis] - likelihood, evidence for/against
   - H3: [hypothesis] - likelihood, evidence for/against

2. Hypothesis Ranking:
   - Most likely based on symptoms
   - Rationale for ranking

3. Investigation Plan:
   For each hypothesis:
   - How to verify/disprove
   - What to look for
   - Tools/commands needed

4. Quick Checks:
   - Fast things to try first
   - Common causes to rule out

Output: Ranked hypotheses with investigation plan
```

#### Agent 3: Verification Designer

**Model**: haiku

```
Design verification approach.

1. Test Cases:
   - Test case for each hypothesis
   - Expected results if hypothesis is true
   - Expected results if hypothesis is false

2. Debugging Commands:
   - Specific commands to run
   - What to look for in output
   - How to interpret results

3. Fix Verification:
   - How to verify fix works
   - Regression tests needed
   - Monitoring to add

4. Documentation:
   - What to document for future
   - Runbook updates

Output: Verification plan with specific tests
```

---

## Phase 3: Synthesize & Output

After all agents complete:

### 1. Consolidation

Merge agent outputs into coherent summary:

```markdown
# Brainstorm: [Topic]

**Mode**: [mode]
**Date**: YYYY-MM-DD

## Summary

[2-3 sentence summary of key findings]

## Key Insights

1. [Insight from Agent 1]
2. [Insight from Agent 2]
3. [Insight from Agent 3]

## Recommendations

### Primary Recommendation
[Main recommendation with rationale]

### Alternatives
[Alternative approaches and when to use them]

## Next Steps

1. [ ] [Action item 1]
2. [ ] [Action item 2]
3. [ ] [Action item 3]

## Open Questions

- [Question that needs answering]
- [Uncertainty that needs resolution]

---

## Detailed Analysis

### [Agent 1 Section]
[Full output from Agent 1]

### [Agent 2 Section]
[Full output from Agent 2]

### [Agent 3 Section]
[Full output from Agent 3]
```

### 2. Output Options

- **Console**: Display summary and recommendations
- **File**: If substantial, offer to save to `context/brainstorm/[topic]-YYYY-MM-DD.md`

### 3. Follow-up Prompts

After presenting results, suggest:
- "Would you like me to dive deeper into any area?"
- "Should I create a TODO list from the action items?"
- "Want me to start implementing the recommendation?"

---

## Important Notes

- **Exploration Only**: Brainstorming generates ideas, doesn't implement them
- **Context Aware**: Check for project directives and existing architecture
- **Parallel Execution**: Launch agents in parallel for efficiency
- **Actionable Output**: Always end with concrete next steps
- **Iterative**: User can request deeper dives into any area
