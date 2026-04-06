---
name: dev-plan-execute
description: "Composite skill. Pull an approved dev plan from Notion, write it as the local plan.md in the project's docs/ or doc/ folder, and start (or restart) the humanize execution loop. Trigger whenever the user says 'execute the plan', 'start the plan', 'run the dev plan', 'execute plan', or references an approved dev plan for implementation. This is the Notion→local bridge: the reverse of dev-plan-review."
---

# Dev Plan Execute

## Purpose
The reverse bridge of `dev-plan-review`:
- `dev-plan-review`: local plan.md → Notion (for human review)
- `dev-plan-execute` (this skill): Notion → local plan.md (after human approval)

When the user says "执行 plan", this skill:
1. Fetches the approved dev plan from Notion
2. Writes it as `plan.md` locally, matching the original plan.md format as closely as possible
3. Cancels any existing humanize RL loop
4. Starts a fresh humanize loop with the new plan

**No plan executes without having gone through Notion review first.**

---

## Atomic Dependencies

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `read-comments` | Check if plan has unresolved blocking comments |
| 2 | (local file write) | Write plan.md to project docs folder |
| 3 | (bash) | Cancel old humanize loop + start new one |

Note: The dev plan page is fetched directly via `notion-fetch`,
not through a read-* atomic skill (it's a single known page, not a folder scan).

---

## Execution Steps

### Step 0: Load Required Tools (CRITICAL)

```
tool_search("notion fetch page")
```

### Step 1: Identify the Dev Plan

Determine which dev plan to execute:
- User provides a Notion link → fetch directly
- User says "execute the plan" without link → search Dev team internal logs
  for the most recent dev plan page

```
tool: notion-fetch
id: {dev plan page_id or URL}
```

Read the full content. Verify it is a dev plan (has the fixed format:
Objective / PRD Reference / Files to Modify / Dependencies / Risks / Verification / Status).

### Step 2: Check Approval Status

Read the Status section of the dev plan:

```
## Status
- [x] Uploaded to Notion
- [x] Human reviewed
- [x] Approved for execution
```

**If "Approved for execution" is NOT checked (HARD STOP):**
```
Dev plan "{title}" has not been approved for execution.
Status: {current checkbox states}

Please review and approve the plan in Notion before executing.
URL: {dev plan Notion URL}
```

Do NOT proceed. The human must check the box in Notion.

### Step 3: Check for Blocking Comments (read-comments)

Execute `read-comments` on the dev plan page.

Scan for unresolved comments with blocking tags:
- `[CONTRADICTION]` — plan conflicts with PRD or code
- `[MISSING]` — critical information missing
- `[RISK]` with severity: high

**If blocking comments exist (HARD STOP):**
```
Dev plan "{title}" has {N} unresolved blocking comments:

1. [{tag}] {summary}
2. [{tag}] {summary}

Resolve these via dev-plan-edit before executing.
```

Non-blocking comments (`[UNCLEAR]`, `[RISK]` medium/low, `[NEEDS INPUT]`)
are noted but do not prevent execution:
```
Note: {M} non-blocking comments remain open. Proceeding with execution.
```

### Step 4: Find Local Plan File Location

```bash
# Find the project's docs folder
for d in docs doc; do
    if [ -d "$d" ]; then echo "FOUND: $d"; break; fi
done
```

If neither exists, ask the user where to write plan.md.

### Step 5: Convert Notion Content to Local plan.md Format

Transform the Notion dev plan page content back into
the local plan.md format that humanize expects.

**Key principle: match the original plan.md format as closely as possible.**
The Notion page may have richer formatting (tables, links, etc.) —
convert these back to plain markdown that the dev toolchain can parse.

Strip Notion-specific content:
- Remove the `## Status` checklist section (Notion-only)
- Remove `## PRD Reference` Notion URLs (local toolchain doesn't need them)
- Keep all technical content: Objective, Files to Modify, Dependencies, Risks, Verification

### Step 6: Write Local plan.md (HARD STOP)

Preview the file content before writing:

```
[PLAN WRITE PREVIEW]
Target: {docs/plan.md or doc/plan.md}
Source: {Notion dev plan title} ({URL})

--- plan.md content ---
{converted plan content}
-----------------------

This will overwrite the existing plan.md.
Type "confirm" to write and start execution.
```

**Do NOT write until user confirms.**

After confirmation:
```bash
# Backup existing plan if present
[ -f "{docs_dir}/plan.md" ] && cp "{docs_dir}/plan.md" "{docs_dir}/plan.md.bak"

# Write new plan
cat > "{docs_dir}/plan.md" << 'PLAN_EOF'
{converted plan content}
PLAN_EOF
```

### Step 7: Restart Humanize Loop

```bash
# Cancel existing humanize loop if running
pkill -f "humanize" 2>/dev/null && echo "Old loop cancelled" || echo "No existing loop"

# Start fresh humanize loop with new plan
# (adjust command based on actual humanize CLI)
humanize --plan "{docs_dir}/plan.md" &
echo "Humanize loop started with new plan"
```

If the humanize command is not available or fails,
report the error and let the user start it manually:
```
plan.md written successfully. Start humanize manually:
  cd {project_root}
  humanize --plan {docs_dir}/plan.md
```

### Step 8: Return

```
[DEV PLAN EXECUTING]
Plan:      {title}
Source:    {Notion URL}
Written:   {docs_dir}/plan.md
Backup:    {docs_dir}/plan.md.bak (if existed)
Humanize:  {started / manual start needed}
Comments:  {N} non-blocking open (noted)

Execution in progress. Monitor via humanize output.
```

---

## Output Contract

- NEVER execute a plan that hasn't been approved in Notion (Status checkbox)
- NEVER execute a plan with unresolved blocking comments
- ALWAYS preview plan.md content before writing
- ALWAYS backup existing plan.md before overwriting
- ALWAYS cancel existing humanize loop before starting a new one
- The local plan.md should match the original format as closely as possible
- Non-blocking comments are noted but do not prevent execution
- If humanize cannot be started automatically, provide manual command

---

## Notes

- This skill completes the Notion↔local round-trip: review→critique→edit→approve→execute
- The Status checkboxes in Notion are the ONLY authorization mechanism — Claude never checks them on behalf of the user
- plan.md.bak preserves the previous plan for rollback if needed
- The humanize loop command may vary by project — adapt Step 7 to the actual CLI
- After execution starts, progress tracking happens through the normal tracker + experiment log flow