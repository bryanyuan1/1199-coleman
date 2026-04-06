---
name: dev-plan-edit
description: "Composite skill. Edit an existing dev plan by incorporating feedback from Notion comments, chat conversation, and local code verification. Resolves addressed comments, modifies plan content, and posts new comments for unresolved issues. Trigger whenever the user says 'update the dev plan', 'revise the plan', 'comments are updated, re-check', or after dev-plan-critique posts comments. This is the dev-side equivalent of prd-edit."
---

# Dev Plan Edit

## Purpose
The edit cycle for dev plans. Same pattern as `prd-edit` but with
access to local codebase for implementation-level verification.

**Role in the review loop:**
- `dev-plan-review` → uploads plan to Notion (human reads)
- `dev-plan-critique` → posts comments (AI finds problems)
- `dev-plan-edit` (this skill) → resolves comments + may post new comments
- Human → reviews, writes new comments → triggers dev-plan-edit again
- Loop continues until plan is approved

**What makes this different from prd-edit:**
- Can verify code-level comments (`[CODE]` tags) against actual files in `/tmp/`
- Can update "Files to Modify" table based on code analysis
- Validates changes against the corresponding PRD

---

## Atomic Dependencies

| Step | Skill | Required? | Purpose |
|------|-------|-----------|---------|
| 1 | `read-all-prds` | yes | Fetch corresponding PRD for consistency |
| 2 | `read-comments` | yes | All comments on the dev plan page |
| 3 | `read-wiki` | yes | Background knowledge |
| 4 | (local code) | conditional | Verify `[CODE]` comments against `/tmp/{repo}/` |
| 5 | `write-wiki-page` | yes | Apply edits to dev plan content |
| 6 | `write-comments` | conditional | Post new comments for unresolved issues |

---

## Execution Steps

### Step 1: Identify Target Dev Plan and Collect Feedback

Locate the dev plan in Notion (in Dev team internal logs).
Execute:
1. `read-comments` — read ALL comments on the dev plan page
2. `read-all-prds` — fetch the PRD linked in the plan's "PRD Reference" section

Categorize every open comment:

```
[FEEDBACK INVENTORY]

From Notion comments:
  Critique tags (from dev-plan-critique):
    - [UNCLEAR] {section}: {summary}
    - [CONTRADICTION] {section}: {summary}
    - [MISSING] {section}: {summary}
    - [RISK] {section}: {summary}
    - [CODE] {section}: {summary} — file: {path}
  User questions:
    - [{author}, {date}]: {question} — on {section}

From current chat:
    - {issue raised in conversation}

From previous edit:
    - [NEEDS INPUT] {section}: {question still open}
    - [OPEN QUESTION] {section}: {question still open}
```

### Step 2: Gather Supporting Context

Execute:
3. `read-wiki` — relevant background knowledge

Check local code:
4. If any `[CODE]` comments exist or plan changes involve specific files:
```bash
ls /tmp/ | head -20
```
If code is available, read the relevant files to verify critique findings
and inform edits.

### Step 3: Triage Each Feedback Item

For every item, classify:

**RESOLVE** — can address by editing the plan:
- `[UNCLEAR]` → clarify the change description
- `[MISSING]` → add missing files to "Files to Modify"
- `[CODE]` → fix file path, update function signature, add ripple-effect files
- `[CONTRADICTION]` with PRD → align plan with PRD (or flag for PRD update)
- User question with known answer → edit the relevant section

**COMMENT BACK** — needs human input:
- Design decision that changes the PRD scope
- Risk that requires human judgment on whether to proceed
- `[CONTRADICTION]` where both plan and PRD might be wrong
- Chat question AI cannot answer

**SKIP** — already resolved

### Step 4: Code Verification (if local code available)

For each `[CODE]` comment being RESOLVED:
```bash
# Verify the fix is correct
view /tmp/{repo}/{file_path}
grep -n "{function_name}" /tmp/{repo}/{file_path}
```

For each file added to "Files to Modify":
```bash
# Check it actually exists and verify dependencies
[ -f "/tmp/{repo}/{new_file}" ] && echo "EXISTS" || echo "NOT FOUND"
grep -rn "include\|import" /tmp/{repo}/{new_file} | head -10
```

Report verification results in the edit plan.

### Step 5: Draft Edit Plan (HARD STOP)

```
[EDIT PLAN: {dev plan title}]
Corresponding PRD: {PRD title}
Code verified: {yes, against /tmp/{repo} / no code available}

=== WILL RESOLVE (edit plan content) ===

1. [{section}] {comment summary}
   Edit: {what will change}
   Code check: {verified / not applicable}

2. [Files to Modify] {adding {file} — missed dependency}
   Edit: add row to Files table
   Code check: file exists at /tmp/{repo}/{path}, imports {modules}

=== WILL COMMENT BACK ===

3. [{section}] {issue}
   New comment: "[NEEDS INPUT] {question}"
   Reason: {why human must decide}

=== SKIP ===

4. {comment} — resolved in previous edit

---
Total: {N} edits + {M} new comments
Type "confirm" to apply, or give feedback.
```

**Do NOT proceed until user confirms.**

### Step 6: Apply Edits (write-wiki-page)

Execute `write-wiki-page`:
```
Target folder: "Dev team internal logs"
Action: UPDATE
Content: {modified dev plan with all RESOLVE items applied}
```

Maintain the fixed dev plan format:
Objective / PRD Reference / Files to Modify / Dependencies / Risks / Verification / Status

### Step 7: Post New Comments (write-comments)

For each COMMENT BACK item:
```
page_id: {dev plan page_id}
comments:
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[NEEDS INPUT] {question requiring human decision}"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[OPEN QUESTION] {unresolved question from chat}"
```

### Step 8: Return

```
[DEV PLAN EDITED]
Plan:     {plan title}
URL:      {Notion page URL}
PRD:      {PRD title}
Resolved: {N} comments addressed
New:      {M} new comments posted
Code:     {K} items verified against local codebase
Next:     Review {M} new comments in Notion
```

---

## Output Contract

- ALWAYS read Notion comments before editing
- ALWAYS present edit plan and wait for confirmation
- Resolved items → edit plan content directly
- Unresolved items → post new comments with `[NEEDS INPUT]` or `[OPEN QUESTION]`
- `[CODE]` comments MUST be verified against local code if available
- Chat questions AI cannot answer → become `[OPEN QUESTION]` comments in Notion
- Maintain dev plan fixed format at all times
- Never modify the Status checkboxes — those are for human only

---

## Notes

- The key difference from prd-edit: local code access for `[CODE]` comment resolution
- Dev plan has no Version Log (unlike PRD) — edits are tracked by Notion page history
- If code verification reveals NEW issues not covered by existing comments, these become new `[CODE]` comments
- If resolving a dev plan comment requires changing the PRD, post a comment on the PRD instead and flag this to the user
- The edit→comment→edit loop is the same as prd-edit: human writes comment → dev-plan-edit resolves + posts questions → human answers → repeat