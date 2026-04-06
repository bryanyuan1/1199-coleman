---
name: dev-plan-review
description: "Composite skill. Upload a dev plan from Claude Code to Notion for human review before execution. Trigger whenever the dev environment generates a plan.md, or when the user says 'review this plan', 'upload plan to Notion', 'submit dev plan'. Reads the local plan file, validates against the corresponding PRD, writes a dev plan page to Notion, links it from the PRD, and updates the tracker. No code execution happens until the human approves the plan in Notion."
---

# Dev Plan Review

## Purpose
Bridge the gap between Claude Code's local dev planning (plan.md) and the
Notion-based human planning system. Every dev plan must be uploaded to Notion
and approved by the human before execution begins.

**Core principle: dev端不能自己决定怎么改代码。**
plan.md 生成后必须经过 Notion 上报 → 人类审核 → 确认后才能执行。

---

## Atomic Dependencies

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `read-all-prds` | Find the corresponding PRD, validate plan consistency |
| 2 | `read-wiki` | Check technical decisions against knowledge base |
| 3 | `write-wiki-page` | Write dev plan page to Dev team internal logs |
| 4 | `write-comments` | Post link comment on the corresponding PRD |
| 5 | `write-tracker` | Create or update tracker task for this plan |

---

## Dev Plan Format

Every dev plan page follows this fixed structure:

```
## Objective
{One sentence: what this plan accomplishes.
 Link to corresponding PRD section.}

## PRD Reference
{PRD title + Notion URL.
 Which PRD section(s) this plan implements.}

## Files to Modify

| File | Action | Change Summary |
|------|--------|---------------|
| {path/to/file.cpp} | {modify/create/delete} | {what changes and why} |
| {path/to/file.h} | {modify} | {what changes and why} |

## Dependencies
{Which existing modules are affected.
 Interface changes (if any) — must match PRD Method section.
 Build/toolchain requirements.}

## Risks
{What could go wrong.
 Edge cases not covered.
 Assumptions being made.}

## Verification
{How to verify correctness after implementation.
 Test commands, expected outputs, sanity checks.
 Reference experiment-design spec card if applicable.}

## Status
- [ ] Uploaded to Notion
- [ ] Human reviewed
- [ ] Approved for execution
```

---

## Execution Steps

### Step 1: Read Local Plan File

Find and read the plan file from the project:
```bash
# Check common locations
for f in docs/plan.md doc/plan.md plan.md; do
    if [ -f "$f" ]; then echo "FOUND: $f"; break; fi
done
```

If no plan file is found, ask the user for the path.
Read the full content of the plan file.

### Step 2: Identify Corresponding PRD (read-all-prds)

Execute `read-all-prds` to find the PRD this plan implements.

Match by:
- Explicit PRD reference in the plan file
- Topic/feature name overlap
- User specification

**If no PRD match is found (HARD STOP):**
```
Cannot find a corresponding PRD for this dev plan.
Which PRD does this plan implement?
1. {list of existing PRDs}
2. None — this plan has no PRD (proceed without PRD link)
```

### Step 3: Validate Against PRD and Wiki

Execute `read-wiki` for relevant technical background.

Check the plan against the PRD:
- **Interface consistency**: do the file changes match the PRD Method section's interface design?
- **Scope alignment**: is the plan implementing what the PRD specifies, or drifting?
- **Missing pieces**: does the PRD require things the plan doesn't cover?

If issues are found, flag them in the dev plan page.

### Step 4: Format Dev Plan Page (HARD STOP)

Transform the local plan.md into the fixed dev plan format (see above).
Add any validation warnings from Step 3.

Present preview to user:

```
[DEV PLAN PREVIEW]

Objective: {one-line summary}
PRD: {PRD title} — {section being implemented}
Files: {N} files to modify
Risks: {N} identified
Warnings: {validation issues from Step 3, or "none"}

{full formatted dev plan content}

Type "confirm" to upload to Notion, or give feedback to revise.
```

### Step 5: Write Dev Plan to Notion (write-wiki-page)

After user approval:
```
Target folder: "Dev team internal logs"
Page title: "Dev Plan: {feature/task name} — {date}"
Content: {formatted dev plan in fixed structure}
```

Record the created page URL as `{dev_plan_url}`.

### Step 6: Link from PRD (write-comments)

Post a comment on the corresponding PRD to create a traceable link:
```
page_id: {PRD page_id}
comments:
  - anchor: "page-level"
    text: "[DEV PLAN: {date}] Implementation plan uploaded: {dev_plan_url}
           Scope: {one-line objective}
           Files: {N} files — awaiting review."
```

### Step 7: Update Tracker (write-tracker)

Create or update a tracker entry:
```
Task: "Implement: {feature/task name}"
Status: "In Progress"
Notes: "Dev plan uploaded: {dev_plan_url} — pending human review"
Source: ["Self-Initiated"]
```

If a tracker task already exists for this PRD, update it
with the dev plan link instead of creating a new entry.

### Step 8: Return

```
[DEV PLAN UPLOADED]
Plan:     Dev Plan: {feature/task name} — {date}
Notion:   {dev_plan_url}
PRD:      {PRD title} — comment posted with link
Tracker:  {task name} — status updated
Warnings: {validation warnings or "none"}

⏳ Awaiting human review in Notion before execution.
```

---

## Output Contract

- Dev plan MUST be written to Notion before any code execution
- Dev plan MUST follow the fixed format (Objective/PRD Reference/Files/Dependencies/Risks/Verification/Status)
- Dev plan MUST be linked from the corresponding PRD via comment
- Tracker MUST be updated to reflect the plan's existence
- NEVER approve the plan on behalf of the human — the status checkboxes are for the human to check in Notion
- If no corresponding PRD exists, the plan can proceed without PRD link but this must be flagged
- Validation warnings from PRD/wiki checks must be visible in the plan, not hidden

---

## Notes

- This skill is the dev端 → planning端 bridge
- The fixed format is designed for quick human scanning: Objective tells you what, Files tells you where, Risks tells you what to watch
- Dev plan pages accumulate in Dev team internal logs — they form a history of implementation decisions
- Future skills (`dev-plan-critique`, `dev-plan-edit`) will operate on these pages with the same critique/comment and edit/resolve pattern as PRDs
- The Status checklist in the dev plan is manually checked by the human in Notion — Claude never modifies it
- One PRD may have multiple dev plans (iterative implementation); each gets its own page and comment