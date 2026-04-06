---
name: progress-digest
description: "Composite skill. Generate a comprehensive progress digest by reading the tracker, all PRDs, and experiment logs. Trigger whenever the user asks 'what's the current status', 'progress update', 'generate email report', 'what did I do this week', 'understand the progress', or needs a holistic view of project state. Also triggered implicitly when slides-report needs context. Outputs a structured short report and optionally drafts an advisor email."
---

# Progress Digest

## Purpose
Produce a consolidated progress snapshot by cross-referencing three data sources.
Two output modes:
- **Digest mode** (default): structured report in conversation
- **Email mode**: draft a concise professional email to advisor

---

## Atomic Dependencies

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `read-tracker` | Current task status by week |
| 2 | `read-all-prds` | PRD status, open questions, version logs |
| 3 | `read-experiment-logs` | Recent experiment results and open issues |

---

## Execution Steps

### Step 1: Read Tracker (read-tracker)

Execute `read-tracker`.
**Filter**: current week + previous week only.
Group tasks by status.

### Step 2: Read All PRDs (read-all-prds)

Execute `read-all-prds`.
For each PRD, extract:
- Title and latest version
- Open Questions count
- Critique section summary (if exists)
- Whether it has linked tracker tasks

### Step 3: Read Experiment Logs (read-experiment-logs)

Execute `read-experiment-logs`.
**Filter**: last 2 weeks only.
Match results to tracker tasks and PRDs.

### Step 4: Cross-Reference Analysis

**Consistency checks:**
- Task marked Done → corresponding experiment result exists?
- PRD has Evaluation section → matching experiment log entry?
- Experiment log has open TODOs → captured in tracker?
- PRD with unresolved comments → tasks still in Todo?

**Risk detection:**
- Tasks WIP for > 1 week without progress notes
- PRDs with unresolved high-severity critique items
- Experiment results outside expected sanity ranges

### Step 5: Generate Digest

```
[PROGRESS DIGEST: {date range}]

## Done
- {task} | PRD: {link or "none"} | Result: {verified / no experiment}

## In Progress
- {task} | PRD: {link or "none"} | Notes: {latest}

## Todo
- {task} | Priority: {p} | Due: {date or "unset"}

## Blocked
- {task} | Reason: {reason} | Since: {date or "unknown"}

## Risks & Inconsistencies
- {issues found in cross-reference, or "None detected"}

## Recommendations
- {suggested priority adjustments}
```

### Step 6: Email Mode (conditional)

If the user asked for an email report ("generate email", "send update to advisor"):

Draft a concise professional email:

```
Subject: Weekly Progress Update — {date range}

Hi {advisor name},

Here's a quick update on this week's progress:

Completed:
{1-2 sentence per done item, focusing on results}

In progress:
{1-2 sentence per WIP item, focusing on next steps}

Blockers:
{any blocked items, or "None currently"}

Questions for discussion:
{open questions from PRDs that need advisor input}

Best,
{user name}
```

Present the email draft for review — do NOT send automatically.

---

## Output Contract

- Always include all four status groups (Done/WIP/Todo/Blocked), even if empty
- Risks section is mandatory — "None detected" if clean
- Data window: current week + previous week only
- Cross-reference analysis is the core value — not just concatenating three reads
- Email mode requires user approval before any further action
- Never modify any data source — read-only synthesis
- If any atomic skill fails, report which one and proceed with available data

---

## Notes

- This skill is the context source for `slides-report` — when user says "make slides", progress-digest runs first
- The 2-week filter prevents context overflow
- Email draft uses the user's real name and advisor name if known from conversation context
- For "generate email" prompts, default to email mode; for "what's the status" prompts, default to digest mode