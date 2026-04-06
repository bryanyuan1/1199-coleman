---
name: paper-distill
description: "Composite skill. Distill an academic paper into a structured wiki entry following the six-section format (Goal/Background/Related Works/Method/Evaluation/Results). Trigger whenever the user says 'distill this paper', 'add paper to wiki', 'summarize paper', or provides a paper title/PDF/URL for knowledge extraction. After writing the new entry, performs a second-pass wiki scan to update cross-references and flag contradictions across existing pages."
---

# Paper Distill

## Purpose
Transform an academic paper into a structured, reusable wiki entry,
then propagate its impact across the existing knowledge base.
Two-phase process: first write the new entry, then update the wiki graph.

---

## Atomic Dependencies

| Phase | Skill | Required? | Purpose |
|-------|-------|-----------|---------|
| Phase 1 | `read-wiki` | yes | Check for duplicates, gather related context |
| Phase 1 | `clone-codebase` | conditional | Cross-reference paper claims with source code |
| Phase 1 | `write-wiki-page` | yes | Write new entry to Knowledge Base |
| Phase 2 | `read-wiki` | yes | Second pass — scan all pages for cross-references |
| Phase 2 | `write-wiki-page` | conditional | Update Related Works sections of other pages |
| Phase 2 | `write-comments` | conditional | Flag contradictions on affected pages |

---

## Input Sources

The user must provide at least ONE of:
- **Paper title** — Claude uses training knowledge + web search
- **Uploaded PDF** — read from `/mnt/user-data/uploads/`
- **URL** — link to paper (arXiv, ACM, IEEE, etc.)

Optional:
- **GitHub repo URL** — for code cross-referencing

If none are provided, ask the user to specify the paper.

---

## Phase 1: Distill and Write

### Step 1: First Read Wiki (read-wiki)

Execute `read-wiki` to:
1. Check if this paper already has a wiki entry — avoid duplication
2. Find related wiki pages for context and cross-referencing
3. Understand existing knowledge landscape on this topic

If an entry already exists:
```
Wiki entry for "{paper title}" already exists (last updated {date}).
Update the existing entry, or skip?
```

### Step 2: Read the Paper

Based on the input source:
- **Uploaded PDF**: read from `/mnt/user-data/uploads/`
- **URL**: use `web_fetch` to retrieve
- **Title only**: use training knowledge + web search, flag as "unverified source"

Extract all content needed for the six-section format.

### Step 3: Cross-Reference with Code (conditional — clone-codebase)

**Only if the user provides a repo URL.**

Execute `clone-codebase` with the provided URL.
After cloning, search the codebase for:
- Algorithm implementations mentioned in the paper
- Parameter names and default values
- Discrepancies between paper description and actual implementation

Add findings to the Method section as implementation notes.

**If no repo URL is provided, skip this step entirely.**

### Step 4: Draft Six-Section Entry (HARD STOP)

Generate the wiki entry in mandatory format:

```
## Goal
{What problem does this paper solve? Core motivation.}

## Background
{Prerequisites, assumptions, target domain.
 Link to related wiki entries found in Step 1.}

## Related Works
{Papers compared against. How this work differs.
 Cross-reference existing wiki entries:
 - "See also: [Wiki: {related paper}] — {relationship}"}

## Method
{Core algorithm and data flow.
 Processing model (parallelism, dataflow pattern).
 Architecture design (hardware/software structure).
 [If code cross-referenced]: Implementation notes from {repo}.}

## Evaluation
{Benchmark setup: datasets, platforms, baselines.
 Experimental methodology.}

## Results
{Key metrics and numbers — exact values, not paraphrased.
 Limitations and applicability scope.
 Claims that could NOT be verified from the paper alone.}
```

**Present the draft to the user. Do NOT write to Notion until approved.**

### Step 5: Write to Wiki (write-wiki-page)

After user approval:
```
Target folder: "Knowledge Base"
Page title: "{Paper title} ({year})"
Content: {approved six-section entry}
```

---

## Phase 2: Cross-Reference Propagation

### Step 6: Second Read Wiki (read-wiki)

Execute `read-wiki` again — this time scanning ALL pages to find:

**A. Pages that should link to the new entry:**
- Other wiki pages that mention this paper by name or cite its authors
- Pages whose Related Works section covers the same topic area
- Pages whose Method section uses similar algorithms or architectures

**B. Pages whose claims contradict the new entry:**
- Conflicting performance numbers for the same benchmark
- Opposite conclusions about trade-offs
- Incompatible architectural assumptions

### Step 7: Generate Changelist (HARD STOP)

Present the changelist to the user:

```
[CROSS-REFERENCE CHANGELIST]

--- Direct Updates (will apply automatically if approved) ---

1. "{page title}" — Related Works section
   Add: "See also: [{new paper title}] — {relationship description}"

2. "{page title}" — Related Works section
   Add: "See also: [{new paper title}] — {relationship description}"

--- Contradictions (will post as inline comments) ---

3. "{page title}" — {section}
   Content: "{existing claim}"
   Contradicts: "{new paper's finding}"
   Comment to post: "[CONTRADICTION from {new paper}] {explanation}"

4. ...

Type "confirm" to apply all changes, or specify which to skip.
```

### Step 8: Apply Changes

After user approval:

**For direct updates (Related Works links):**
Execute `write-wiki-page` for each affected page, updating only the
Related Works section to add a cross-reference link and short description.
Do NOT modify any other section of the affected page.

**For contradictions:**
Execute `write-comments` to post inline comments on the affected pages:
```
page_id: {affected page id}
comments:
  - anchor: "{first ~10 chars of contradicting content}...{last ~10 chars}"
    text: "[CONTRADICTION from {new paper title} ({year})] {explanation of conflict}"
```

### Step 9: Return

```
[PAPER DISTILLED]
Paper:          {title} ({year})
Wiki entry:     {Notion page URL}
Format:         Six-section (Goal/Background/Related Works/Method/Evaluation/Results)
Code:           {cross-referenced / not available}
Cross-refs:     {N} pages updated with links
Contradictions: {M} comments posted on {K} pages
```

---

## Output Contract

- Phase 1 output MUST follow the six-section format — no exceptions
- Phase 1 MUST complete (entry written) before Phase 2 begins
- Exact numbers from the paper must be preserved verbatim in Results
- Claims that cannot be verified must be flagged explicitly
- Related Works link updates are applied directly (lightweight, low-risk)
- Contradictions are NEVER auto-resolved — only flagged as inline comments
- Never write anything to Notion without user approval at each HARD STOP
- If code cross-reference reveals discrepancies with the paper, document them in Method

---

## Notes

- Paper titles in wiki follow the convention: `{Paper title} ({year})`
- One paper = one wiki entry; multi-paper surveys should be split
- Phase 2 is the key differentiator — it keeps the wiki graph connected
- If the paper is behind a paywall and no PDF is provided, work from abstract + training knowledge, flagging as incomplete
- The six-section format is shared across `paper-distill`, `knowledge-correction`, and `write-wiki-page`