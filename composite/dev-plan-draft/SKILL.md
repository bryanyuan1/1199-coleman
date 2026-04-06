---
name: dev-plan-draft
description: "Composite skill. Draft a dev plan from an approved PRD, producing docs/draft.md locally, then using humanize to generate and refine docs/plan.md. Trigger whenever the user says '撰写 dev plan', 'draft a dev plan', 'write dev plan for {feature}', 'create implementation plan', or when a PRD has been approved and the next step is implementation planning. This is the PRD→local plan bridge: it reads the PRD from Notion, reads the codebase for file-level context, writes a draft, and runs humanize to produce the final plan.md. After this skill completes, the natural next step is dev-plan-review (upload plan.md to Notion for human review)."
---

# Dev Plan Draft

## Purpose
Bridge the gap between an approved PRD (planning layer, Notion) and an executable
dev plan (development layer, local repo). This skill reads the PRD and codebase,
drafts an implementation plan, then uses the humanize toolchain to produce
a polished, human-reviewable plan.md.

**Core principle: PRD 是设计，dev plan 是施工图。**
PRD 说 "要做什么、为什么"；dev plan 说 "改哪些文件、怎么改、怎么验证"。
draft.md 是 AI 初稿，plan.md 是经 humanize 处理后的人类可读版本。

**Pipeline position:**
```
PRD (Notion, approved)
    ↓ read (this skill)
docs/draft.md (AI-generated implementation draft)
    ↓ humanize:gen-plan
docs/plan.md (structured plan)
    ↓ humanize:refine-plan
docs/plan.md (refined, ready for review)
    ↓ dev-plan-review (separate skill)
Notion (human review)
    ↓ dev-plan-execute (separate skill)
Code execution
```

---

## Atomic Dependencies

| Step | Skill | Required? | Purpose |
|------|-------|-----------|---------|
| 1 | `read-all-prds` | **yes** | Read the target PRD + all other PRDs for interface context |
| 2 | `read-wiki` | **yes** | Technical background (architecture, formats, algorithms) needed for accurate file-level planning |
| 3 | `clone-codebase` | **yes** | Read actual file structure, existing interfaces, and current implementation state |
| 4 | `read-tracker` | recommended | Current task status to avoid scope overlap with completed work |
| 5 | `read-experiment-logs` | conditional | Past experiment results if PRD Evaluation references them |

**Not used by this skill** (belong to downstream skills):
- `write-wiki-page` → dev-plan-review writes to Notion
- `write-tracker` → dev-plan-review updates tracker
- `write-comments` → dev-plan-review posts PRD link
- `read-comments` → dev-plan-edit handles review feedback

---

## Draft Format

Every `docs/draft.md` follows this fixed structure:

```markdown
# Dev Plan Draft: {feature name}

> PRD: {PRD title}
> PRD URL: {Notion URL}
> Date: {today}
> Scope: {which PRD section(s) this plan implements}

## Objective
{One paragraph: what this plan accomplishes, in implementation terms.
 Not "what" (PRD covers that) but "how" at the file level.}

## Files to Modify

| File | Action | Change Summary |
|------|--------|---------------|
| {src/path/file.cpp} | {create/modify/delete} | {concrete change description} |
| {src/path/file.h} | {modify} | {interface change description} |

## Implementation Steps

### Step 1: {name}
{What to do, which file(s), key logic.
 Reference PRD Method section for design spec.
 Reference wiki for technical details (formats, algorithms).}

### Step 2: {name}
...

## Dependencies
{Existing modules affected.
 Interface contracts from other PRDs that must be respected.
 Build/toolchain requirements (TAPA version, board target, etc.).}

## Risks
{What could go wrong.
 Edge cases not covered by this plan.
 Assumptions being made (with justification).}

## Verification
{How to verify correctness after implementation.
 Specific test commands, expected outputs, matrices to use.
 Reference experiment-design spec card if one exists.}
```

---

## Execution Steps

### Step 0: Identify Target PRD

Determine which PRD to implement:
- User specifies directly: "撰写 {feature} 的 dev plan"
- User references a tracker task → find linked PRD
- Ambiguous → ask user which PRD

**If no approved PRD exists (HARD STOP):**
```
No approved PRD found for this feature.
Draft a PRD first via prd-draft, then return here.
```

### Step 1: Gather Context (read-all-prds + read-wiki + clone-codebase)

Execute in order:

1. **`read-all-prds`** — Read ALL PRDs, not just the target.
   - Target PRD: extract Goal, Method, Evaluation sections in full
   - Other PRDs: extract interface contracts (module names, data formats,
     function signatures) to ensure this plan doesn't break existing designs

2. **`read-wiki`** — Read relevant wiki pages.
   - Match by topics mentioned in PRD Method section
   - Key info needed: data formats (edge 64-bit encoding, CSR layout),
     architecture details (PEG structure, HBM channel allocation),
     algorithm specifics (tiling, scheduling)

3. **`clone-codebase`** — Clone the project repo.
   - Read the directory tree to understand file structure
   - Read existing files that will be modified (get current interfaces)
   - Read CLAUDE.md / README.md for project conventions
   - Identify which files already exist vs need creation

4. **`read-tracker`** (recommended) — Check current task status.
   - Avoid planning work that's already Done
   - Identify WIP tasks that may conflict

5. **`read-experiment-logs`** (conditional) — Only if PRD Evaluation
   references past experiment results as baselines.

### Step 2: Analyze and Plan

With all context gathered, determine:

1. **Scope mapping**: Which PRD Method subsections → which source files?
2. **Dependency order**: Which files must be modified first?
   (e.g., header changes before implementation changes)
3. **Interface boundaries**: What crosses module boundaries?
   What must match other PRD interface contracts?
4. **Existing code reuse**: What can be adapted from existing files
   vs what must be written from scratch?
5. **Verification path**: What test infrastructure exists?
   What needs to be created?

### Step 3: Write docs/draft.md (HARD STOP)

Generate the draft following the fixed format above.

**Key quality requirements:**
- Every file in "Files to Modify" must be a REAL path verified against
  the cloned codebase (no guessed paths)
- Implementation Steps must reference specific PRD section numbers
  and wiki page names for traceability
- Risks must include at least one technical risk and one scope risk
- Verification must include concrete commands, not vague "test it"

Present draft to user:

```
[DEV PLAN DRAFT PREVIEW]

PRD:    {PRD title}
Files:  {N} files to modify ({M} create, {K} modify)
Steps:  {N} implementation steps
Risks:  {N} identified

{full draft.md content}

Type "confirm" to write docs/draft.md and proceed to humanize,
or give feedback to revise.
```

**Do NOT write until user confirms.**

### Step 4: Write docs/draft.md

After user approval:

```bash
# Ensure docs/ directory exists
mkdir -p docs

# Write draft
cat > docs/draft.md << 'DRAFT_EOF'
{draft content}
DRAFT_EOF

echo "draft.md written to docs/draft.md"
```

### Step 5: Humanize — Generate plan.md

Run the humanize gen-plan tool to transform the AI draft into
a structured plan:

```bash
humanize:gen-plan --input docs/draft.md --output docs/plan.md
```

If humanize is not available or fails:
```
humanize:gen-plan not available. Manual fallback:
  1. docs/draft.md has been written
  2. Run manually: humanize:gen-plan --input docs/draft.md --output docs/plan.md
  3. Then: humanize:refine-plan --input docs/plan.md
```

### Step 6: Humanize — Refine plan.md

Run the humanize refine-plan tool to polish the plan:

```bash
humanize:refine-plan --input docs/plan.md
```

This step improves readability, fills structural gaps,
and ensures the plan follows project conventions.

If humanize is not available, skip and note for manual execution.

### Step 7: Verify Output

Read the final `docs/plan.md` and verify:
- [ ] All files from draft.md are still present
- [ ] No PRD references were lost during humanize
- [ ] Verification section has concrete commands
- [ ] No hallucinated file paths (cross-check against codebase)

### Step 8: Return

```
[DEV PLAN DRAFTED]
Draft:      docs/draft.md (AI-generated)
Plan:       docs/plan.md (humanized)
PRD:        {PRD title} ({Notion URL})
Files:      {N} files planned
Steps:      {N} implementation steps
Humanize:   {gen-plan ✓/✗} → {refine-plan ✓/✗}

Next step:  dev-plan-review (upload plan.md to Notion for human review)
  → Say "上传 dev plan" or "review this plan"
```

---

## Output Contract

- draft.md MUST follow the fixed format (Objective/Files/Steps/Dependencies/Risks/Verification)
- Every file path in "Files to Modify" MUST be verified against the actual codebase
- Implementation Steps MUST reference specific PRD sections for traceability
- draft.md is written BEFORE humanize runs (it's the input, not a temp file)
- plan.md is the final output — draft.md is preserved as the AI-generated record
- If humanize tools are unavailable, draft.md is still written and the user is
  given manual commands to run humanize separately
- This skill NEVER uploads to Notion — that's dev-plan-review's job
- This skill NEVER executes code changes — that's dev-plan-execute's job

---

## Notes

- This skill fills the gap between prd-draft (design) and dev-plan-review (upload):
  `prd-draft → [PRD approved] → dev-plan-draft → dev-plan-review → dev-plan-execute`
- The two-file design (draft.md + plan.md) preserves the AI's raw reasoning
  while giving the human a polished version to review
- humanize is a local CLI tool in the dev environment; it may not be available
  in all contexts — the skill degrades gracefully
- clone-codebase is critical: without reading actual files, the plan will
  contain guessed paths and miss existing interfaces
- The "Files to Modify" table is the most important section — reviewers
  scan it first to understand scope and blast radius
- One PRD may produce multiple dev plans (e.g., Phase 1 and Phase 2);
  each gets its own draft.md → plan.md cycle
- If the PRD has open items or unresolved comments, flag them in Risks
  rather than blocking the draft entirely