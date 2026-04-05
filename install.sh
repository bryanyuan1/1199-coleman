#!/bin/bash
SKILLS_DIR="/mnt/skills/user"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p $SKILLS_DIR/atomic
mkdir -p $SKILLS_DIR/composite

for skill in atomic/*/; do
    skill_name=$(basename $skill)
    ln -sf "$REPO_DIR/$skill" "$SKILLS_DIR/atomic/$skill_name"
    echo "✓ atomic: $skill_name"
done

for skill in composite/*/; do
    skill_name=$(basename $skill)
    ln -sf "$REPO_DIR/$skill" "$SKILLS_DIR/composite/$skill_name"
    echo "✓ composite: $skill_name"
done

echo "\nDone. Skills installed to $SKILLS_DIR"
