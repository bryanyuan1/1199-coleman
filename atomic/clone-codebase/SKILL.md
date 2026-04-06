---
name: clone-codebase
description: "Atomic skill. Clone a Git repository to /tmp for code reading and reference. Called by composite skills (paper-distill, prd-draft, prd-edit, prd-critique, knowledge-correction, experiment-design) that need source code access. Also trigger directly when the user mentions 'clone', 'pull the repo', 'fetch the codebase', or provides a GitHub/GitLab URL and wants to inspect source. The calling skill must provide repo_url; this skill returns the local path for downstream file reads."
---

# Clone Codebase

## Purpose
The single path to get external source code into the working environment.
Never called in isolation for its own sake — always serves a downstream task
(PRD drafting, code review, knowledge distillation, experiment design, etc.).

Calling composite skills invoke this skill when they need to read implementation
source that is not yet available locally.

---

## Calling Interface

Composite skills call this skill by providing:

| Parameter | Required | Default | Notes |
|-----------|----------|---------|-------|
| `repo_url` | **yes** | — | Any valid Git HTTPS URL (e.g. `https://github.com/user/repo.git`) |
| `branch` | no | `main` | Branch or tag to checkout after clone |
| `target_dir` | no | `/tmp/{repo_name}` | Auto-derived from repo URL; e.g. `https://github.com/foo/bar.git` → `/tmp/bar` |

**Return value to caller:**
```
{target_dir}   # absolute path where repo is available for reading
```

If `repo_url` is missing or ambiguous, stop and ask the user — do NOT guess.

---

## Execution Steps

### Step 1: Derive Target Directory

Extract repo name from URL:
```
https://github.com/foo/bar.git → /tmp/bar
https://github.com/foo/bar     → /tmp/bar
```

### Step 2: Check Existing Clone

```bash
if [ -d "{target_dir}" ] && [ "$(ls -A {target_dir})" ]; then
    echo "REPO_EXISTS"
else
    echo "NEEDS_CLONE"
fi
```

- **REPO_EXISTS** → Skip clone. Report path to caller:
  `"Repo already at {target_dir} — reusing existing clone."`
  If caller explicitly requests latest, run `git -C {target_dir} pull` instead.
- **NEEDS_CLONE** → Remove empty dir if present (`rm -rf {target_dir}`), proceed to Step 3.

### Step 3: Clone

```bash
git clone --depth 1 --branch {branch} {repo_url} {target_dir}
```

- `--depth 1` for speed; full history is not needed for code reading.
- If `--branch {branch}` fails (branch not found), retry without `--branch`
  to get the default branch, then report which branch was actually checked out.

### Step 4: Verify and Return

```bash
cd {target_dir}
echo "Branch: $(git branch --show-current)"
echo "Commit: $(git log --oneline -1)"
echo "Top-level:"
ls -1
echo "---"
find . -type f \( -name '*.py' -o -name '*.cpp' -o -name '*.h' \
  -o -name '*.v' -o -name '*.sv' -o -name '*.tcl' -o -name '*.mk' \
  -o -name 'Makefile' -o -name '*.cfg' -o -name '*.json' \
  -o -name '*.yaml' -o -name '*.yml' \) | wc -l
```

Return structured output to the calling skill:

```
[CLONE COMPLETE]
Repo:      {repo_url}
Branch:    {branch}
Commit:    {short hash} {subject}
Path:      {target_dir}
Key files: {count} source files detected
```

The calling skill then uses `{target_dir}` for `view`, `grep -rn`, `find`, etc.

---

## Output Contract

- Always return `{target_dir}` on success — this is the primary output consumed by callers
- On failure (network error, repo not found, branch not found), return Git error verbatim — do NOT retry silently
- If repo already exists and is non-empty, skip clone and return existing path
- Never modify any files in the cloned repo — read-only access only
- Never push, commit, or write to the remote

---

## Caller Examples

How composite skills should invoke this skill:

**From `prd-draft`** — need to reference implementation before writing design doc:
```
1. clone-codebase(repo_url="https://github.com/user/project.git", branch="main")
   → receives /tmp/project
2. Read relevant source files from /tmp/project/src/...
3. Draft PRD referencing actual implementation details
```

**From `code-review`** — need source to review:
```
1. clone-codebase(repo_url="{url}", branch="{feature-branch}")
   → receives /tmp/{repo}
2. Read changed files, analyze, produce review
```

**From `paper-distill`** — need to cross-reference paper claims with code:
```
1. clone-codebase(repo_url="{url}")
   → receives /tmp/{repo}
2. grep for algorithm implementations mentioned in paper
3. Validate paper claims against actual code
```

---

## Notes

- Read-only skill — never modify, commit, or push to the cloned repo
- `/tmp` is ephemeral — clones do not persist across sessions; callers should not cache paths across conversations
- If network is restricted (domain blocked), report the error and suggest user update network settings
- For private repos requiring auth, inform the user that token-based clone is not supported in this environment
- This skill does NOT analyze code — it only makes code available; analysis is the caller's responsibility