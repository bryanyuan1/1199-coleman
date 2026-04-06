---
name: prd-draft
description: "Composite skill. Draft the first version of a PRD from a web-side chat discussion. Trigger whenever the user says 'write a PRD', 'draft a design doc', 'create a PRD for {feature}', or when a conversation has reached the point where the user knows what they want to build. The first draft is allowed to be incomplete — sections lacking information are written with placeholders and flagged as inline comments for the user to fill in later. After drafting, the natural next step is prd-critique or prd-edit."
---

# PRD Draft

## Purpose
Capture the first version of a design document from a web-side chat discussion.
The user has been talking through an idea and is now ready to formalize it.

**Key principle: the first draft is NEVER complete.**
A real research conversation does not produce all six sections at once.
The goal is to write what IS known, and explicitly flag what ISN'T.
Missing information becomes inline comments for the user to address later
via `prd-critique` or `prd-edit`.

---

## Atomic Dependencies

| Step | Skill | Required? | Purpose |
|------|-------|-----------|---------|
| 1 | `read-wiki` | yes | Paper background for informed drafting |
| 2 | `read-all-prds` | yes | Existing PRD format and interface contracts |
| 3 | `read-tracker` | yes | Current progress context |
| 4 | `read-experiment-logs` | conditional | Past results if relevant to this design |
| 5 | `write-wiki-page` | yes | Write PRD to Product team PRDs folder |
| 6 | `write-comments` | yes | Flag incomplete sections as inline comments |
| 7 | `append-version-log` | yes | Initialize as v0.1 |

---

## Execution Steps

### Step 1: Extract from Conversation

Before any reads, scan the current chat conversation to extract:
- **What the user wants to build** (→ Goal)
- **Why** (→ Background motivation)
- **Referenced papers or prior work** (→ Related Works)
- **Any design ideas discussed** (→ Method)
- **How to test it** (→ Evaluation)
- **Expected outcomes** (→ Results)

Mark each as `[HAVE]` or `[NEED]` based on what the conversation actually covered.

### Step 2: Gather Context

Execute reads:
1. `read-wiki` — find relevant wiki pages for the topic
2. `read-all-prds` — read existing PRDs for format reference and interface checking
3. `read-tracker` — understand current task status

Conditional:
4. `read-experiment-logs` — only if conversation referenced experiments

### Step 3: Draft Six-Section PRD

Write each section based on what is available.
For sections with insufficient information, write a placeholder and mark `[INCOMPLETE]`:

```
## Goal
{From conversation: what the user wants to build and why.
 This section is almost always writable from the chat.}

## Background
{Current state, prerequisites, context from wiki.
 If the conversation didn't cover this deeply:}
[INCOMPLETE] Background needs more detail on: {specific gaps}

## Related Works
{Papers and approaches discussed in chat + relevant wiki entries.
 If conversation didn't reference specific papers:}
[INCOMPLETE] No specific papers referenced yet. Suggest:
- {candidate paper from wiki that seems related}
- {candidate paper from wiki that seems related}

## Method
{Design ideas from the conversation.
 This may range from detailed to very rough.
 If only high-level ideas were discussed:}
[INCOMPLETE] Method needs:
- Algorithm specification
- Interface design (check against existing PRDs: {list})
- Data flow description

## Evaluation
{How to test, if discussed.
 Often the least developed section in a first draft:}
[INCOMPLETE] Evaluation needs:
- Specific parameters and datasets
- Baseline comparisons
- Success criteria
→ Use experiment-design skill when ready to specify

## Results
{Expected outcomes, if discussed.
 May be entirely placeholder in first draft:}
[INCOMPLETE] Results section pending:
- Performance targets not yet defined
- Need experiment results to populate

## Open Questions
{Unresolved points from the conversation.
 Questions the user raised but didn't answer.
 Disagreements between chat participants.}

## Version Log

| Version | Date | Changed By | Summary |
|---------|------|------------|---------|
| v0.1 | {today} | prd-draft | Initial draft from chat discussion |
```

### Step 4: Interface Check

Compare Method section (even if incomplete) against existing PRDs:
- Any naming conflicts with existing modules?
- Any interface assumptions that contradict existing PRD Method sections?

If issues found, note them in Open Questions:
```
[INTERFACE CHECK] Potential conflict with {PRD title}: {description}
```

### Step 5: Present Draft (HARD STOP)

```
[PRD DRAFT: {feature name}]

Sections complete:   {list of [HAVE] sections}
Sections incomplete: {list of [NEED] sections — will be flagged as comments}

{full PRD content}

---
After writing to Notion, {N} inline comments will be posted
on incomplete sections for you to address.

Type "confirm" to write, or give feedback to revise.
```

**Do NOT write until user confirms.**

### Step 6: Write PRD (write-wiki-page)

After user approval:
```
Target folder: "Product team PRDs"
Page title: "PRD: {feature name}"
Content: {PRD content — including [INCOMPLETE] markers in the text}
```

### Step 7: Post Comments on Incomplete Sections (write-comments)

For each `[INCOMPLETE]` marker, post an inline comment:

```
page_id: {new PRD page_id}
comments:
  - anchor: "[INCOMPLETE] Back...{last chars}"
    text: "[DRAFT GAP] Background section needs: {specific items}"
  - anchor: "[INCOMPLETE] Meth...{last chars}"
    text: "[DRAFT GAP] Method section needs: {specific items}"
  - anchor: "[INCOMPLETE] Eval...{last chars}"
    text: "[DRAFT GAP] Evaluation section needs: {specific items}"
  - anchor: "[INCOMPLETE] Resu...{last chars}"
    text: "[DRAFT GAP] Results section needs: {specific items}"
```

Tag: `[DRAFT GAP]` — distinguishable from critique tags.
These comments tell the user exactly what to fill in.

### Step 8: Remove Inline Markers

After comments are posted, update the PRD to remove
the `[INCOMPLETE]` text markers from the page content,
leaving clean placeholder text. The comments carry the gap information now.

```
tool: notion-update-page
page_id: {PRD page_id}
command: update_content
content_updates:
  - old_str: "[INCOMPLETE] Background needs more detail on: {gaps}"
    new_str: "{clean placeholder text — e.g. 'To be expanded.'}"
  ...
```

### Step 9: Initialize Version Log (append-version-log)

```
page_id: {new PRD page_id}
version: "v0.1"
changed_by: "prd-draft"
summary: "Initial draft from chat discussion. {N} sections flagged for completion."
```

### Step 10: Return

```
[PRD DRAFTED]
Title:      PRD: {feature name}
URL:        {Notion page URL}
Version:    v0.1
Complete:   {list of complete sections}
Gaps:       {N} sections flagged with [DRAFT GAP] comments
Next steps:
  1. Fill in [DRAFT GAP] comments in Notion
  2. Run prd-critique to find problems
  3. Run prd-edit to incorporate feedback
```

---

## Output Contract

- ALL six sections MUST be present in the PRD — even if incomplete
- Incomplete sections MUST have inline comments with `[DRAFT GAP]` tag
- `[INCOMPLETE]` markers in text are temporary — removed after comments are posted
- Goal section should almost always be writable from conversation context
- Never invent technical details not discussed in the conversation
- Never skip a section entirely — always write at least a placeholder
- Interface check against existing PRDs is mandatory even for incomplete drafts
- Version Log initialized as v0.1

---

## Notes

- This skill captures the transition from "chatting about an idea" to "formal design document"
- The first draft is intentionally imperfect — perfection comes from critique→edit loops
- `[DRAFT GAP]` comments are the handoff mechanism: prd-draft creates them, the user + prd-edit resolve them
- The natural flow after prd-draft: user fills gaps → prd-critique → prd-edit → repeat
- If the conversation covered all six sections well, there may be zero gaps — that's fine but rare
- Open Questions section should capture any unresolved discussion points from the chat verbatim