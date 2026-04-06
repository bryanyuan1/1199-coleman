---
name: knowledge-correction
description: "Composite skill. Correct or supplement the knowledge base and PRDs when new findings emerge during execution. Trigger whenever the user says 'I found a problem', 'this is wrong in the PRD', 'update the wiki with this finding', 'we discovered that...', or when experiment results contradict existing documentation. Applies corrections at two levels: direct wiki fixes for factual errors, and inline comments on PRDs for design assumption issues. The bidirectional write-back skill that closes the knowledge loop."
---

# Knowledge Correction

## Purpose
Write back corrections, new findings, and lessons learned into the
knowledge base and PRDs. This is the only skill that closes the
knowledge loop — without it, discoveries die in chat history.

**Core principle: the human never skips verify.**
All changes require explicit confirmation before taking effect.

**Two-level correction strategy:**
- **Wiki factual errors** → direct fix via `write-wiki-page` (after user confirms todo list)
- **PRD design assumptions** → inline comments via `write-comments` (user reviews in Notion)

---

## Atomic Dependencies

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `read-all-prds` | Read target PRD(s) — user-specified or last week's active PRDs |
| 2 | `read-tracker` | Read specified or last week's task context |
| 3 | `read-wiki` | Understand current wiki state, find affected pages |
| 4 | `read-comments` | Read existing comments to avoid duplicate feedback |
| 5 | `read-experiment-logs` | Check if experiment results are affected |
| 6 | `write-wiki-page` | Apply direct fixes to wiki pages |
| 7 | `write-comments` | Post comments on PRDs for design-level issues |
| 8 | `append-version-log` | Version any PRD that receives direct content changes |

---

## Execution Steps

### Step 1: Scope the Correction (HARD STOP if ambiguous)

Determine what to read:

**PRDs:** If the user specifies a PRD → read that one.
If not specified → read PRDs with activity in the last week.
**If ambiguous, ask:**
```
Which PRD(s) does this correction affect?
1. {list of recent PRDs from read-all-prds}
2. All active PRDs
3. None — wiki only
```

**Tracker:** If the user specifies a time range → use it.
Otherwise → read last week's entries.

### Step 2: Gather Full Context

Execute all reads:
1. `read-all-prds` — target PRD(s) determined in Step 1
2. `read-tracker` — scoped to specified or last week
3. `read-wiki` — all pages, to find factual content affected by the correction
4. `read-comments` — on affected PRDs, to avoid posting duplicate feedback
5. `read-experiment-logs` — check if experiment results need annotation

### Step 3: Understand the Correction

Extract from conversation or ask the user:
- **What was wrong or missing?**
- **What is the correct information?**
- **How was it discovered?** (experiment, code reading, advisor feedback, etc.)

### Step 4: Classify Each Impact

For every affected document, classify into one of two categories:

**Category A — Wiki Factual Error (direct fix):**
- Wrong numbers, incorrect algorithm descriptions, outdated claims
- Missing cross-references that should exist
- Stale content contradicted by new evidence
→ Will be fixed directly via `write-wiki-page`

**Category B — PRD Design Assumption Issue (comment):**
- A design decision is based on a now-disproven assumption
- An interface contract may need rethinking
- Evaluation criteria need revisiting based on new findings
→ Will be flagged via `write-comments`, human decides how to revise

### Step 5: Present Correction Plan (HARD STOP)

```
[CORRECTION PLAN]

Finding: {one-line summary}
Source:  {how it was discovered}

=== CATEGORY A: Wiki Direct Fixes (will apply after your confirm) ===

TODO 1. "{wiki page title}" — {section}
     Old: {current incorrect content}
     New: {corrected content}

TODO 2. "{wiki page title}" — {section}
     Old: {current incorrect content}
     New: {corrected content}

=== CATEGORY B: PRD Comments (will post for your review in Notion) ===

COMMENT 1. "{PRD title}" — {section}
     Issue: {what assumption is affected}
     Comment to post: "[CORRECTION: {source}] {explanation}"

COMMENT 2. "{PRD title}" — {section}
     Issue: {what assumption is affected}
     Comment to post: "[CORRECTION: {source}] {explanation}"

=== EXPERIMENT LOG ANNOTATIONS ===

NOTE 1. Log entry "{date range}"
     Add note: {annotation about affected results}

---
Type "confirm" to apply all, or specify which items to skip/modify.
```

**Do NOT proceed until the user explicitly confirms.**

### Step 6: Apply Category A — Wiki Direct Fixes

For each confirmed TODO item:

Execute `write-wiki-page`:
```
Target folder: "Knowledge Base"
Action: UPDATE
Content: {modify only the affected section, preserve everything else}
```

Wiki content must maintain six-section format after the fix.

### Step 7: Apply Category B — PRD Comments

For each confirmed COMMENT item:

Execute `write-comments`:
```
page_id: {PRD page_id}
comments:
  - anchor: "{first ~10 chars of affected content}...{last ~10 chars}"
    text: "[CORRECTION from {source}] {explanation of what assumption changed and why}"
```

Do NOT modify PRD content directly — the comment tells the user
where to look and what to reconsider. The actual PRD revision
happens later via `prd-edit`.

### Step 8: Apply Experiment Log Annotations

For each confirmed NOTE item:

Execute `write-wiki-page`:
```
Target folder: "Dev team internal logs"
Action: UPDATE
Content: {add annotation note to the affected log entry}
```

**NEVER modify original experiment data** — only append annotation notes
clearly marked as `[CORRECTION NOTE — {date}]: {text}`.

### Step 9: Version PRDs If Directly Modified

If any PRD received direct content changes (rare — only if user
explicitly requested content fix instead of comment):

Execute `append-version-log`:
```
page_id: {PRD page_id}
version: {incremented version}
changed_by: "knowledge-correction"
summary: "Corrected {what} based on {source of finding}"
```

In the normal flow, PRDs only receive comments (Category B),
so this step is skipped. Version log is only needed when
the user explicitly asks to directly fix PRD content.

### Step 10: Return

```
[CORRECTIONS APPLIED]
Finding: {summary}

Wiki fixes applied:
  - {page title}: {section} — FIXED
  - {page title}: {section} — FIXED

PRD comments posted (review needed):
  - {PRD title}: {section} — COMMENT POSTED
  - {PRD title}: {section} — COMMENT POSTED

Experiment log annotations:
  - {date range}: NOTE ADDED

Action required:
  - Review {N} PRD comments in Notion
  - Consider running prd-edit on affected PRDs
```

---

## Output Contract

- ALWAYS present the full correction plan (Step 5) before writing anything
- ALWAYS wait for user confirmation — no exceptions
- Wiki factual errors → direct fix via `write-wiki-page`, maintaining six-section format
- PRD design assumptions → comment only via `write-comments`, never direct PRD edit
- Experiment log original data → NEVER modified, only append annotation notes
- If the correction invalidates a PRD's core hypothesis, flag as high-impact and recommend `prd-critique`
- Duplicate comments (already posted by prior correction or critique) must be avoided — check `read-comments` first
- Each TODO/COMMENT/NOTE item can be individually accepted or rejected by the user

---

## Notes

- This is the only skill that writes upstream — it closes the knowledge loop
- Common triggers: unexpected experiment results, code bugs, advisor corrections, paper re-reading
- The "how it was discovered" field is important for traceability
- Category A vs B classification is about certainty: if you KNOW the correct answer → fix it; if the DESIGN needs rethinking → comment it
- PRD comments use the `[CORRECTION]` tag prefix so `prd-edit` can find them via `read-comments`
- If a single finding affects both wiki and PRDs, both categories apply in the same run