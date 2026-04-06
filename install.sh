#!/bin/bash
# 1199-coleman install script
# Corporate bureaucrat for efficient research
#
# Usage:
#   cd /path/to/1199-coleman
#   bash install.sh
#
# This creates symlinks from the repo into /mnt/skills/user/
# so Claude Code can discover and use all skills.
# Symlinks mean edits to the repo are immediately live.

set -e

SKILLS_DIR="/mnt/skills/user"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "1199-coleman skill installer"
echo "============================"
echo "Repo:   $REPO_DIR"
echo "Target: $SKILLS_DIR"
echo ""

# Create target directory if needed
mkdir -p "$SKILLS_DIR"

# Counter
installed=0
skipped=0

# Install all skills (flat structure — no atomic/composite subdirs)
for skill_dir in "$REPO_DIR"/*/; do
    # Skip non-skill directories
    skill_name=$(basename "$skill_dir")
    case "$skill_name" in
        .git|node_modules|__pycache__|.venv|scripts|references|assets)
            continue
            ;;
    esac

    # Must have SKILL.md to be a valid skill
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        continue
    fi

    # Create or update symlink
    target="$SKILLS_DIR/$skill_name"
    if [ -L "$target" ]; then
        # Existing symlink — update it
        rm "$target"
        ln -s "$skill_dir" "$target"
        echo "  ↻ $skill_name (updated)"
    elif [ -d "$target" ]; then
        # Existing real directory — back it up, replace with symlink
        mv "$target" "$target.bak"
        ln -s "$skill_dir" "$target"
        echo "  ↻ $skill_name (replaced, backup at $skill_name.bak)"
    else
        # New install
        ln -s "$skill_dir" "$target"
        echo "  ✓ $skill_name"
    fi
    installed=$((installed + 1))
done

echo ""
echo "Done. $installed skills installed to $SKILLS_DIR"
echo ""
echo "Verify:"
echo "  ls -la $SKILLS_DIR/"
echo ""
echo "To uninstall:"
echo "  for f in $SKILLS_DIR/*/; do [ -L \"\$f\" ] && rm \"\$f\"; done"