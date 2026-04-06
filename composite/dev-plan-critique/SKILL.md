---
name: dev-plan-critique
description: "Composite skill. Critically review a dev plan by cross-referencing the corresponding PRD, wiki knowledge, local codebase, and experiment logs. Posts each critique point as an inline comment on the dev plan page in Notion. Trigger whenever the user says 'critique this plan', 'check if this plan makes sense', 'review the dev plan', or after dev-plan-review uploads a plan. This is the dev-side equivalent of prd-critique: AI finds problems, posts comments, human decides what to act on."
---

# Dev Plan Critique

## Purpose
AI-driven peer review of a dev plan, with access to the LOCAL codebase
and raw data that the planning-side (`prd-critique`) does not have.

This is what makes dev-plan-critique different from prd-critique:
- **prd-critique** reviews design intent against wiki and experiment history
- **dev-plan-critique** reviews implementation plan against actual code, file structure, build system, and existing tests

The output is always comments. The human decides what to act on.

**Role separation (same pattern as PRD):**
- **dev-plan-review**: upload plan to Notion → human reads it
- **dev-plan-critique** (this skill): AI finds problems → posts comments → human reads
- **dev-plan-edit** (future): human decides which comments to address → AI drafts changes → human confirms

---

## Atomic Dependencies

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `read-all-prds` | Fetch the corresponding PRD for consistency checking |
| 2 | `read-wiki` | Background knowledge to verify technical decisions |
| 3 | `read-experiment-logs` | Past results relevant to this implementation |
| 4 | `read-comments` | Existing comments on the dev plan — avoid duplicates |
| 5 | (local code) | Read `/tmp/{repo}/` for implementation-level verification |
| 6 | `write-comments` | Post each critique point as an inline comment |

---

## Execution Steps

### Step 1: Identify Target Dev Plan

The dev plan must already exist in Notion (uploaded by `dev-plan-review`).
Identify it by:
- User specifying the plan name or link
- Most recent dev plan in Dev team internal logs
- If ambiguous, ask the user

Fetch the dev plan page content from Notion.

### Step 2: Gather Context

Execute reads:
1. `read-all-prds` — fetch the PRD referenced in the dev plan's "PRD Reference" section
2. `read-wiki` — retrieve knowledge relevant to the algorithms and architecture involved
3. `read-experiment-logs` — check for past results that inform implementation choices
4. `read-comments` — read existing comments on the dev plan to avoid duplicates

### Step 3: Read Local Codebase

This is the step prd-critique cannot do.

Check if the relevant codebase exists in `/tmp/`:
```bash
ls /tmp/ | head -20
```

**If code is available**, for each file listed in the dev plan's "Files to Modify" section:

**A. Verify files exist:**
```bash
for f in {list of files from plan}; do
    [ -f "/tmp/{repo}/$f" ] && echo "EXISTS: $f" || echo "MISSING: $f"
done
```

**B. Read current file content:**
```bash
view /tmp/{repo}/{file_path}
```

**C. Check for issues the plan may have missed:**
- Functions or interfaces that the plan references — do they actually exist in the code?
- Dependencies the modified files import — will changes break them?
- Test files — does the plan account for updating tests?
- Build configuration — does the plan require Makefile/CMake/tcl changes?
- Other files that import/include the files being modified — ripple effect?

**If no code is available in `/tmp/`, skip code-level checks** and note this in the critique output. The critique will still run against PRD, wiki, and experiment logs.

### Step 4: Systematic Critique

Analyze the dev plan across five dimensions (four shared with prd-critique + one dev-specific):

**`[UNCLEAR]` — Ambiguity**
- Change descriptions too vague to implement ("refactor the module")
- Missing parameter values or configuration details
- Unclear which branch of logic is affected

**`[CONTRADICTION]` — Conflicts with PRD or code**
- Plan modifies an interface differently than the PRD specifies
- Plan assumes a function signature that doesn't match actual code
- Plan changes a file that another recent dev plan also targets (merge conflict risk)

**`[MISSING]` — Incomplete plan**
- Files listed in plan but change summary is empty
- Modified files that import/include changed files — not listed in plan
- No test updates for changed functionality
- No build system updates when adding/removing files
- Verification section doesn't actually verify the core change

**`[RISK]` — Implementation risk**
- Large-scope changes across many files in one plan (should be split?)
- Changes to critical shared modules without clear rollback strategy
- Performance-sensitive code changes without benchmark plan
- Hardware-specific assumptions not verified

**`[CODE]` — Code-level findings (dev-specific)**
- Function/class referenced in plan doesn't exist in codebase
- File path in plan is wrong or outdated
- Plan proposes a pattern inconsistent with existing code style
- Existing tests that will break and aren't mentioned
- Include/import chains that create unintended ripple effects

### Step 5: Deduplicate Against Existing Comments

Compare findings from Step 4 against existing comments from Step 2.
Remove any finding that duplicates an already-posted comment.

### Step 6: Present Critique (HARD STOP)

```
[DEV PLAN CRITIQUE: {plan title}]
Corresponding PRD: {PRD title}
Local code: {available at /tmp/{repo} / not available}

## New Findings

[UNCLEAR] [Files to Modify] {description} — severity: {level}
  → Will comment on: "{anchor snippet}"

[CONTRADICTION] [Dependencies] {description} — severity: {level}
  → Conflicts with: {PRD section / actual code at {file:line}}

[MISSING] [Files to Modify] {description} — severity: {level}
  → {file} imports {modified file} but is not listed in plan

[RISK] [Verification] {description} — severity: {level}
  → Will comment on: "{anchor snippet}"

[CODE] [Files to Modify] {description} — severity: {level}
  → {file:line}: function {name} has signature {actual}, plan assumes {planned}

## Previously Unaddressed Comments
- [{author}, {date}]: {summary} — still open

## Skipped (already flagged)
- {finding} — duplicate of existing comment

---
Total: {N} new comments to post
Code checks: {M} files verified against local codebase
Overall: {1-2 sentence assessment}

Type "confirm" to post all comments, or specify which to skip.
```

**Do NOT post any comments until the user confirms.**

### Step 7: Post Inline Comments (write-comments)

After user approval, post each critique point as an inline comment
on the dev plan page in Notion:

```
page_id: {dev plan page_id}
comments:
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[UNCLEAR] {description}"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[CONTRADICTION] {description}. PRD says: {X}. Code says: {Y}."
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[MISSING] {file} imports {modified file} — add to Files to Modify"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[RISK] {description}. Severity: {level}"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[CODE] {file}:{line} — {description of code-level issue}"
```

### Step 8: Return

```
[DEV PLAN CRITIQUE COMPLETE]
Plan:     {plan title}
URL:      {Notion page URL}
Comments: {N} inline comments posted
  [UNCLEAR]: {count}
  [CONTRADICTION]: {count}
  [MISSING]: {count}
  [RISK]: {count}
  [CODE]: {count}
Code verified: {M} of {K} planned files checked against /tmp/{repo}
Next: Review comments in Notion → address via dev-plan-edit
```

---

## Output Contract

- Critique MUST cover all five dimensions (unclear / contradiction / missing / risk / code)
- If a dimension has no issues, state "None found" — do not omit
- Each finding MUST be posted as an inline comment with its category tag
- `[CODE]` findings MUST reference specific file paths and line numbers when available
- Existing unaddressed comments MUST be surfaced
- Duplicate findings MUST be skipped
- Never modify the dev plan content — only post comments
- Never post comments without user approval
- If local code is not available, skip `[CODE]` checks and state this explicitly

---

## Notes

- The `[CODE]` category is what distinguishes this from prd-critique — it requires local codebase access
- If `/tmp/` is empty, this skill degrades gracefully to a prd-critique-like review (no code checks)
- Category tags (`[UNCLEAR]`, `[CONTRADICTION]`, `[MISSING]`, `[RISK]`, `[CODE]`) enable dev-plan-edit to parse comments
- Ripple effect analysis (Step 3C) is critical — dev plans often miss files that depend on changed files
- For large plans (>10 files), recommend splitting into smaller plans before implementation