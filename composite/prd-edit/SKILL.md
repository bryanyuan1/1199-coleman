---
name: prd-edit
description: "Composite skill. Edit an existing PRD by incorporating feedback from three sources: Notion comments (including critique comments and user questions), current chat conversation, and uploaded advisor notes. Resolves addressed comments, modifies PRD content, and posts new comments for unresolved issues. Trigger whenever the user says 'update the PRD', 'revise the PRD', 'latest comments are in Notion, update it', 'incorporate feedback'. Maintains the six-section format and versions every edit."
---

# PRD Edit

## Purpose
The edit cycle for PRDs. Collects feedback from all sources, modifies
the document, resolves addressed comments, and posts new comments for
issues that cannot be resolved in this edit.

**Role in the review loop:**
- `prd-critique` → posts comments (AI finds problems)
- `prd-edit` (this skill) → resolves comments by editing + may post NEW comments
- Human → reviews edits, writes new comments → triggers prd-edit again
- The loop continues until all comments are resolved

**Three feedback sources:**
1. **Notion comments** — critique tags, user questions, advisor notes
2. **Chat conversation** — user raises issues verbally, AI attempts to resolve
3. **Uploaded files** — advisor feedback documents (conditional)

---

## Atomic Dependencies

| Step | Skill | Required? | Purpose |
|------|-------|-----------|---------|
| 1 | `read-all-prds` | yes | Fetch target PRD + other PRDs for interface checking |
| 2 | `read-comments` | yes | All comments: critique tags, user questions, replies |
| 3 | `read-wiki` | yes | Background knowledge for informed editing |
| 4 | `read-tracker` | yes | Current task context |
| 5 | `read-experiment-logs` | conditional | If edit involves Evaluation/Results sections |
| 6 | `write-wiki-page` | yes | Apply edits to PRD content |
| 7 | `write-comments` | conditional | Post new comments for unresolved issues |
| 8 | `append-version-log` | yes | Version the edit |

---

## Execution Steps

### Step 1: Identify Target PRD and Collect Feedback

Execute initial reads:
1. `read-all-prds` — locate target PRD, read full content + other PRDs
2. `read-comments` — read ALL comments on the target PRD (open + resolved)

Categorize every open comment:

```
[FEEDBACK INVENTORY]

From Notion comments:
  Critique tags (from prd-critique):
    - [UNCLEAR] {section}: {summary}
    - [CONTRADICTION] {section}: {summary}
    - [MISSING] {section}: {summary}
    - [RISK] {section}: {summary}
  User questions:
    - [{author}, {date}]: {question} — on {section}
  Advisor feedback:
    - [{author}, {date}]: {feedback} — on {section}

From current chat:
    - {issue raised in conversation}
    - {question asked in conversation}

From uploaded files:
    - {filename}: {extracted action items}
    — or "none uploaded"
```

### Step 2: Gather Supporting Context

Execute:
3. `read-wiki` — background knowledge relevant to the feedback
4. `read-tracker` — current task status

Conditional:
5. `read-experiment-logs` — if any comment or chat issue involves Evaluation/Results

### Step 3: Triage Each Feedback Item

For every item in the feedback inventory, classify:

**RESOLVE** — AI can address this by editing the PRD:
- Unclear definition → add definition
- Missing spec → add specification
- Factual correction → fix the content
- Question with a known answer → answer by editing the relevant section

**COMMENT BACK** — AI cannot resolve, needs human input:
- Design question that requires human judgment
- Chat question that AI attempted but couldn't fully answer
- Trade-off decision that needs advisor input
- Contradiction that has multiple valid resolutions

**SKIP** — Already resolved in a previous edit:
- Comment was addressed in an earlier version

### Step 4: Draft Edit Plan (HARD STOP)

Present the plan before any changes:

```
[EDIT PLAN: {PRD title}]
Current version: {vX.Y}
New version: {vX.Y+1}

=== WILL RESOLVE (edit PRD content) ===

1. [{section}] {comment summary}
   Edit: {what will change}
   Source: {Notion comment / chat / uploaded file}

2. [{section}] {comment summary}
   Edit: {what will change}
   Source: {Notion comment / chat / uploaded file}

=== WILL COMMENT BACK (post new comment) ===

3. [{section}] {issue summary}
   New comment: "[NEEDS INPUT] {question for human}"
   Reason: {why AI cannot resolve this alone}

4. [{section}] {issue summary}
   New comment: "[OPEN QUESTION] {question from chat that needs further discussion}"

=== SKIP (already addressed) ===

5. {comment summary} — resolved in v{X.Y-1}

---
Total: {N} edits + {M} new comments + {K} skipped

Type "confirm" to apply, or give feedback to revise the plan.
```

**Do NOT proceed until user confirms.**

### Step 5: Apply Edits (write-wiki-page)

Execute `write-wiki-page` to modify the PRD:
```
Target folder: "Product team PRDs"
Action: UPDATE
Content: {modified PRD content with all RESOLVE items applied}
```

Rules:
- Maintain six-section format at all times
- NEVER delete Version Log
- NEVER change the page title
- For each edit, the change should be traceable to a specific feedback item

### Step 6: Post New Comments (write-comments)

For each COMMENT BACK item, post a new inline comment:
```
page_id: {PRD page_id}
comments:
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[NEEDS INPUT] {question or issue requiring human decision}"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[OPEN QUESTION] {unresolved question from chat conversation}"
```

Tags for new comments:
- `[NEEDS INPUT]` — AI attempted but needs human judgment
- `[OPEN QUESTION]` — question from chat that couldn't be answered here

### Step 7: Version Log (append-version-log)

```
page_id: {PRD page_id}
version: {new version}
changed_by: "prd-edit"
summary: "Resolved {N} comments ({list of categories}). Posted {M} new questions."
```

### Step 8: Return

```
[PRD EDITED]
Title:    {PRD title}
URL:      {Notion page URL}
Version:  {old} → {new}
Resolved: {N} comments addressed by edits
New:      {M} new comments posted (awaiting human input)
Skipped:  {K} already resolved
Next:     Review {M} new comments in Notion
```

---

## Output Contract

- ALWAYS read Notion comments before editing — this is the primary feedback source
- ALWAYS present edit plan and wait for confirmation
- ALWAYS version every edit via `append-version-log`
- Resolved items → edit PRD content directly
- Unresolved items → post new comments with `[NEEDS INPUT]` or `[OPEN QUESTION]` tags
- Chat questions that AI cannot answer → become `[OPEN QUESTION]` comments in Notion
- NEVER change the page title
- NEVER delete Version Log
- Maintain six-section format at all times

---

## Notes

- The edit→comment→edit loop: human writes comment → prd-edit resolves + posts new questions → human answers → prd-edit again
- `[NEEDS INPUT]` and `[OPEN QUESTION]` tags distinguish AI-generated questions from critique tags
- Minor edits (wording, clarification) → v0.x+1. Structural changes → v(N+1).0
- If the edit plan has >5 section changes, suggest splitting into multiple edit passes
- Uploaded advisor files can be PDF, text, or slides — extract action items from any format