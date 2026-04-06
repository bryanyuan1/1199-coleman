---
name: slides-report
description: "Composite skill. Generate a MARP-format progress report slide deck for advisor meetings. Trigger whenever the user says 'generate slides', 'make a presentation', 'prepare for advisor meeting', 'create progress report'. Reads all data sources for context, then generates a .md file in MARP format. Often preceded by the user asking about progress (which triggers progress-digest first), so this skill should leverage any digest already in the conversation."
---

# Slides Report

## Purpose
Generate a presentation-ready MARP slide deck for advisor meetings.
Outputs a local `.md` file to `/home/claude/slides/`.

If `progress-digest` was already run in this conversation,
reuse that context instead of re-reading all data sources.

---

## Atomic Dependencies

| Step | Skill | Required? | Purpose |
|------|-------|-----------|---------|
| 1 | `read-tracker` | yes (unless digest in context) | Task status |
| 2 | `read-all-prds` | yes (unless digest in context) | Active designs |
| 3 | `read-experiment-logs` | yes (unless digest in context) | Recent results |
| 4 | `read-wiki` | yes | Background for technical highlight slides |

---

## Execution Steps

### Step 1: Gather Context

**If progress-digest output is already in this conversation:**
Reuse it. Only execute `read-wiki` for technical highlight context.

**If no digest available:**
Execute all reads:
1. `read-tracker` — filter to current + previous week
2. `read-all-prds` — focus on PRDs with recent activity
3. `read-experiment-logs` — filter to last 2 weeks
4. `read-wiki` — context for technical highlights

### Step 2: Plan Slide Structure

Based on gathered data, determine content per slide:

```
Slide 1:  Title + date range
Slide 2:  Overview (counts: done/wip/blocked + one-line highlight)
Slide 3-N:  Last week's completed work (1 slide per major item)
Slide N+1-M: Technical highlight (key result or design decision)
Slide M+1-K: Challenges & blockers
Slide K+1:   Next week's plan (table)
Slide K+2:   Questions for advisor (from PRD Open Questions)
```

Target: **8-12 slides max.** Each slide ≤ 5 bullet points.

### Step 3: Present Slide Plan (HARD STOP)

```
[SLIDES PLAN]
Total: {N} slides
Structure:
  1. Title
  2. Overview
  3-{X}. Progress ({count} items)
  {X+1}-{Y}. Technical highlights ({count})
  {Y+1}-{Z}. Challenges ({count})
  {Z+1}. Next week plan
  {Z+2}. Questions for advisor

Key content:
  Highlight: {the most interesting result or decision to present}
  Questions: {list of open questions for advisor}

Type "confirm" to generate, or adjust the structure.
```

### Step 4: Generate MARP File

Create the MARP markdown file:

```markdown
---
marp: true
theme: default
paginate: true
---

# Progress Report
## {project context}
### {date range}

---

## Overview

- Completed: {N} tasks
- In progress: {M} tasks
- Blocked: {K} issues
- Highlight: {one-line summary of most significant result}

---

## Completed: {task name}

- {what was accomplished}
- {key result or evidence}
- {impact on overall project}

---

## Technical Highlight: {topic}

- {design decision or result, with wiki context}
- {specific numbers from experiments}
- {why this matters for the project}

---

## Challenges

### {blocker name}
- **Issue**: {description}
- **Impact**: {what's affected}
- **Proposed**: {suggested resolution}

---

## Next Week

| Priority | Task | Due | PRD |
|----------|------|-----|-----|
| {p} | {task} | {date} | {link} |

---

## Questions for Discussion

1. {open question from PRD — needs advisor input}
2. {design decision pending}
```

### Step 5: Save and Present

```bash
mkdir -p /home/claude/slides
```

Save to `/home/claude/slides/progress_{YYYY-MM-DD}.md`

Present the file to the user.

```
[SLIDES GENERATED]
File:   /home/claude/slides/progress_{YYYY-MM-DD}.md
Slides: {N} total
Render: marp progress_{YYYY-MM-DD}.md --pdf
        or open in VS Code with MARP extension
```

---

## Output Contract

- Output is a local `.md` file in MARP format at `/home/claude/slides/`
- Target 8-12 slides — never exceed 15
- Each slide ≤ 5 bullet points
- Technical highlights must include specific numbers, not vague claims
- Questions for advisor must come from PRD Open Questions — do not invent
- Data window: current + previous week
- If progress-digest was already run, reuse context — do not re-read everything
- Always present slide plan for approval before generating

---

## Notes

- MARP renders markdown to PDF/HTML/PPTX: https://marp.app
- Technical highlight slides are highest value — spend effort making them clear and specific
- The slide plan HARD STOP lets you adjust structure before generation (e.g. "add a slide about X", "skip the blockers slide")
- Common flow: "当前进度怎么了" → progress-digest runs → "生成 slides" → slides-report reuses digest context