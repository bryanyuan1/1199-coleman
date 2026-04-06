---
name: wiki-lint
description: "Composite skill. Run a health check on the Knowledge Base wiki: find contradictions between pages, missing entries, broken cross-references, format violations, and stale content. Trigger whenever the user says 'lint the wiki', 'check wiki health', 'audit knowledge base', or periodically after multiple paper-distill runs. Most valuable when wiki has 10+ pages. Outputs a health report with actionable items."
---

# Wiki Lint

## Purpose
Audit the Knowledge Base wiki for consistency, completeness, and format compliance.
Like a code linter but for knowledge — finds problems that accumulate silently
as the wiki grows.

---

## Atomic Dependencies

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `read-wiki` | Read all wiki pages for analysis |
| 2 | `write-wiki-page` | Write lint report to Dev team internal logs |

---

## Execution Steps

### Step 1: Read All Wiki Pages (read-wiki)

Execute `read-wiki` with a broad query to retrieve ALL pages.
For each page, record:
- Title, last updated date
- Which of the six sections are present
- All cross-references to other wiki pages
- All paper citations mentioned

### Step 2: Run Lint Checks

**A. Format Compliance (six-section format)**
- Missing sections: `[FORMAT] {page}: missing {section}`
- Empty sections: `[FORMAT] {page}: {section} is empty`

**B. Cross-Reference Integrity**
- Page A references "Paper X" but no wiki entry for Paper X exists
- `[BROKEN REF] {page} references "{title}" — no wiki entry found`

**C. Contradiction Detection**
- Same metric reported differently across pages
- Conflicting trade-off conclusions without noting conditions
- `[CONTRADICTION] {page A} and {page B} disagree on {topic}`

**D. Staleness**
- Pages not updated in > 30 days that are referenced by recent PRDs
- `[STALE] {page}: last updated {date}, referenced by {PRD}`

**E. Missing Entries**
- Paper names mentioned across wiki + PRDs + experiment logs
  that do NOT have their own wiki entry
- Only flag if cited in ≥ 2 sources (avoid noise)
- `[MISSING] "{paper}" cited in {source1} and {source2} — no wiki entry`

### Step 3: Generate Report

```
[WIKI LINT REPORT — {date}]

Pages scanned: {N}

## Format Issues ({count})
{list}

## Broken References ({count})
{list}

## Contradictions ({count})
{list}

## Stale Pages ({count})
{list}

## Missing Entries ({count})
{list}

---
Total: {sum} issues

Priority actions:
1. {highest-impact item}
2. {second-highest}
3. {third-highest}
```

### Step 4: Save Report (HARD STOP)

```
Save this lint report to Notion (Dev team internal logs)?
Type "confirm" to save, or "skip" to discard.
```

If confirmed, write via `write-wiki-page`:
```
Target folder: "Dev team internal logs"
Page title: "Wiki Lint Report — {date}"
Content: {lint report}
```

### Step 5: Return

```
[WIKI LINT COMPLETE]
Pages:   {N} scanned
Issues:  {total}
Report:  {Notion URL if saved, else "not saved"}
Fix via: paper-distill (missing entries), knowledge-correction (contradictions/factual errors)
```

---

## Output Contract

- Scan ALL wiki pages — do not skip any
- Every finding must cite the specific page and section
- Contradictions must cite both pages and the conflicting claims
- Missing entries only flagged if cited in ≥ 2 sources
- The report is read-only analysis — wiki-lint does NOT fix anything
- Fixes are the user's job via `paper-distill` or `knowledge-correction`

---

## Notes

- Most valuable when wiki has ≥ 10 pages — below that, findings will be sparse
- Run after a batch of `paper-distill` to catch integration issues
- Contradiction detection is approximate — flag for human judgment, do not auto-resolve
- Priority actions should focus on issues that block downstream skills (e.g. a broken ref that a PRD depends on)