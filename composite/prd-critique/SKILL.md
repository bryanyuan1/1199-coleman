---
name: prd-critique
description: "Composite skill. Critically review a PRD by cross-referencing wiki knowledge, experiment logs, tracker status, and existing comments. Posts each critique point as an inline comment anchored to the specific content it targets, plus writes a summary into the Critique section. Trigger whenever the user says 'critique this PRD', 'review the design', 'find problems in the PRD', or after a prd-draft completes. This is the planning-side equivalent of dev-plan-critique: AI finds problems, posts comments, human decides what to act on. No flow lets the human skip verify."
---

# PRD Critique

## Purpose
AI-driven peer review of a PRD. The output is **comments, never direct edits.**

The role separation across the three PRD operations:
- **prd-critique** (this skill): AI finds problems → posts comments → human reads
- **prd-edit**: human decides which comments to act on → AI drafts changes → human confirms → AI applies + may post new comments
- Neither flow lets the human skip verify. Neither flow lets AI decide alone.

---

## Atomic Dependencies

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `read-all-prds` | Fetch target PRD + all other PRDs for interface checking |
| 2 | `read-wiki` | Background knowledge to verify claims |
| 3 | `read-tracker` | Task status and timeline feasibility |
| 4 | `read-experiment-logs` | Past results to check consistency |
| 5 | `read-comments` | Existing comments — avoid duplicates, surface unaddressed items |
| 6 | `write-comments` | Post each critique point as an inline comment |
| 7 | `write-wiki-page` | Write critique summary into the PRD's Critique section |

---

## Execution Steps

### Step 1: Identify Target PRD

Ask the user which PRD to critique, or infer from conversation context.
If ambiguous, list available PRDs and ask.

### Step 2: Gather Full Context

Execute all reads:
1. `read-all-prds` — fetch target PRD full content + all other PRDs for interface cross-checking
2. `read-wiki` — retrieve knowledge relevant to the PRD topic
3. `read-tracker` — understand current task status and timeline
4. `read-experiment-logs` — check for supporting or contradicting results
5. `read-comments` — read all existing comments on the target PRD
   - Record which issues are already flagged (avoid duplicate comments)
   - Record which prior comments are still unaddressed

### Step 3: Systematic Critique

Analyze the PRD across four dimensions.
Each finding gets a category tag that will prefix its comment:

**`[UNCLEAR]` — Ambiguity**
- Terms used without definition
- Sections that assume knowledge not in the wiki
- Vague specifications ("optimize performance" without metrics)
- Interface descriptions that don't specify data types or protocols

**`[CONTRADICTION]` — Internal or external conflicts**
- Claims that conflict with wiki knowledge
- Method design that conflicts with interfaces in other PRDs
- Evaluation plan that doesn't match the Method
- Results expectations that conflict with known experiment data

**`[MISSING]` — Incomplete specification**
- Method section without clear algorithm pseudocode or data flow
- Evaluation section without specific parameters or datasets
- No success criteria defined
- Open Questions that should have been resolved before drafting

**`[RISK]` — Feasibility concerns**
- Timeline estimates vs tracker reality
- Hardware/resource assumptions that haven't been verified
- Dependencies on components that are themselves in Todo/Blocked status
- Scalability concerns not addressed

**For each finding, record:**
- Category tag
- Which section it targets (for anchor)
- The specific content it references
- The critique explanation
- Severity: high / medium / low

### Step 4: Deduplicate Against Existing Comments

Compare findings from Step 3 against existing comments from Step 2.
Remove any finding that duplicates an already-posted comment.
Keep findings that are related but distinct from existing comments.

### Step 5: Present Critique (HARD STOP)

Present the full critique to the user before posting anything:

```
[CRITIQUE: {PRD title}]

## New Findings

[UNCLEAR] [{section}] {description} — severity: {level}
  → Will comment on: "{anchor snippet}"

[CONTRADICTION] [{section}] {description} — severity: {level}
  → Will comment on: "{anchor snippet}"

[MISSING] [{section}] {description} — severity: {level}
  → Will comment on: "{anchor snippet}"

[RISK] [{section}] {description} — severity: {level}
  → Will comment on: "{anchor snippet}"

## Previously Unaddressed Comments (still open)
- [{author}, {date}]: {summary} — on {section}
- [{author}, {date}]: {summary} — on {section}

## Skipped (already flagged by existing comments)
- {finding} — duplicate of comment by {author}

---
Total: {N} new comments to post
Overall: {1-2 sentence assessment}
Recommended action: {revise and resubmit / minor edits / ready for implementation}

Type "confirm" to post all comments, or specify which to skip.
```

**Do NOT post any comments until the user confirms.**

### Step 6: Post Inline Comments (write-comments)

After user approval, post each critique point as an inline comment:

```
page_id: {target PRD page_id}
comments:
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[UNCLEAR] {description}"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[CONTRADICTION] {description}. Conflicts with: {source}"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[MISSING] {description}"
  - anchor: "{first ~10 chars}...{last ~10 chars}"
    text: "[RISK] {description}. Severity: {level}"
```

For document-wide issues (e.g. structural risks), use page-level comments.

### Step 7: Write Critique Summary Section (write-wiki-page)

Write a summary into the PRD's Critique section via `write-wiki-page`:
```
Target folder: "Product team PRDs"
Action: UPDATE
Content: {append or replace the ## Critique section}
```

The summary is an overview, not a duplicate of comments:

```
## Critique

_Last reviewed: {date}_

| Category | Count | Highest Severity |
|----------|-------|-----------------|
| Unclear | {N} | {high/medium/low} |
| Contradiction | {M} | {high/medium/low} |
| Missing | {K} | {high/medium/low} |
| Risk | {L} | {high/medium/low} |

**Overall**: {1-2 sentence assessment}
**Action**: {revise and resubmit / minor edits / ready for implementation}

_See inline comments for details. Address via prd-edit._
```

Do NOT modify any other section. Do NOT touch the Version Log.

### Step 8: Return

```
[CRITIQUE COMPLETE]
PRD:      {title}
URL:      {Notion page URL}
Comments: {N} inline comments posted
Summary:  Written to Critique section
Issues:   {N} unclear, {M} contradictions, {K} missing, {L} risks
Next:     Review comments in Notion → address via prd-edit
```

---

## Output Contract

- Critique MUST cover all four dimensions (unclear / contradiction / missing / risk)
- If a dimension has no issues, state "None found" — do not omit
- Each finding MUST be posted as an inline comment with its category tag
- A summary MUST be written to the Critique section
- Existing unaddressed comments MUST be surfaced in the preview
- Duplicate findings (already covered by existing comments) MUST be skipped
- Never modify any PRD section other than Critique
- Never modify the Version Log — critique is feedback, not an edit
- Never post comments without user approval
- The user can accept or reject individual findings before posting

---

## Notes

- Critique is deliberately adversarial — the goal is to find problems, not validate
- Category tags (`[UNCLEAR]`, `[CONTRADICTION]`, `[MISSING]`, `[RISK]`) enable `prd-edit` to parse and categorize comments via `read-comments`
- The critique→edit flow: critique posts comments → human reviews → human triggers prd-edit → prd-edit reads comments → resolves addressed ones → may post new comments
- Severity ratings help the author prioritize: high = blocks implementation, medium = should fix before impl, low = nice to have
- A PRD is not "done" until all high-severity items are addressed
- This skill is the planning-side equivalent of `dev-plan-critique` (to be written later)