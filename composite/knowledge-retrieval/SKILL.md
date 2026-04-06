---
name: knowledge-retrieval
description: "Composite skill. Quickly retrieve and synthesize project knowledge from wiki, PRDs, and local codebase for development context. Trigger whenever Claude Code needs to understand a technical concept, algorithm, design decision, or implementation detail before acting — e.g. discussing a paper, reviewing code, answering 'how does X work', 'what is Y', 'why did we choose Z'. This is the standard way to build context before any development task."
---

# Knowledge Retrieval

## Purpose
The fast-path knowledge lookup for the Claude Code development environment.
Before writing code, reviewing a PR, designing a module, or answering any
technical question, this skill builds a complete understanding from three sources:
wiki (paper knowledge), PRDs (design decisions), and local code (implementation truth).

This is read-only — it never writes anything.

---

## Atomic Dependencies

| Step | Skill | Required? | Purpose |
|------|-------|-----------|---------|
| 1 | `read-wiki` | yes | Paper knowledge, algorithms, architectural principles |
| 2 | `read-all-prds` | yes | Design decisions, interface contracts, trade-off rationale |
| 3 | (local code) | conditional | Implementation truth from `/tmp/{repo}/` if available |

---

## Execution Steps

### Step 1: Read Wiki (read-wiki)

Execute `read-wiki` with the current topic as query.
If the user mentioned a specific paper, algorithm, or concept, use that as query.
If the topic is broad, run multiple queries to cover related terms.

Extract from matching wiki pages:
- Relevant sections (not the full page — only what matters for this query)
- Cross-references to other wiki entries
- Known contradictions or open issues

### Step 2: Read PRDs (read-all-prds)

Execute `read-all-prds` to find design context.
For the current topic, extract:
- Which PRD(s) reference this concept
- Design decisions and their rationale (from Method sections)
- Interface contracts that constrain implementation
- Open Questions that are still unresolved
- Critique points that flag known issues

### Step 3: Read Local Code (conditional)

Check if a relevant codebase exists in `/tmp/`:

```bash
ls /tmp/ | head -20
```

**If code is available:**
Search for relevant implementations:
```bash
grep -rn "{topic keyword}" /tmp/{repo}/ --include="*.cpp" --include="*.h" --include="*.py" --include="*.v" --include="*.sv" | head -30
```

Then `view` the most relevant files to understand:
- How the concept is actually implemented
- Parameter names and default values
- Discrepancies between wiki/PRD description and code reality

**If no code is available in `/tmp/`, skip this step.**
Do NOT trigger `clone-codebase` — if the user wants code context,
they will clone first or ask explicitly. This skill stays fast.

### Step 4: Synthesize and Return

Combine all three sources into a focused briefing:

```
[KNOWLEDGE: {topic}]

## From Wiki
{Key points from paper knowledge.
 Cite specific wiki page titles.}

## From PRDs
{Relevant design decisions and constraints.
 Cite specific PRD titles.
 Flag any Open Questions or Critique points.}

## From Code
{Implementation details if code was available.
 Flag any discrepancies with wiki or PRD descriptions.
 "No local code available" if /tmp/ is empty.}

## Cross-References
- {wiki page A} is implemented in {PRD B} as {module C}
- {PRD X} references {wiki page Y} for algorithm basis

## Gaps & Warnings
- {topic X referenced but no wiki entry exists}
- {PRD design assumes Y, but wiki says Z — potential conflict}
- {code implements V, but PRD specifies W — verify which is correct}
```

---

## Output Contract

- Return relevant content only — do not dump entire wiki pages or PRDs
- Always cite source (wiki page title, PRD title, file path) for every claim
- Always flag cross-source discrepancies (wiki vs PRD vs code)
- Always flag knowledge gaps (topics referenced but not documented)
- If wiki is empty or Notion MCP is unavailable, state explicitly and proceed with training memory, flagging as unverified
- Never write to any data source — this is strictly read-only
- Response should be concise enough to fit in working context without overwhelming

---

## Six-Section Format Reference

This skill does NOT use the six-section format for its own output.
However, it defines the authoritative format that all wiki WRITE operations must follow:

```
## Goal
## Background
## Related Works
## Method
## Evaluation
## Results
```

Skills that write to the Knowledge Base (`paper-distill`, `knowledge-correction`)
must produce content in this format. `knowledge-retrieval` reads and summarizes
this content but does not enforce the format on its own output.

---

## Notes

- This is designed to be FAST — it reads what's already available, never triggers clones or writes
- The three-source model (wiki + PRD + code) gives three perspectives: theory, design intent, and implementation reality
- Discrepancies between sources are the most valuable output — they reveal where documentation has drifted from code or vice versa
- If called repeatedly on the same topic in one session, subsequent calls can be lighter (skip already-loaded sources)
- Local code search uses `grep` and `view` directly — no need for `clone-codebase` atomic skill