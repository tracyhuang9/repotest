#!/bin/bash
set -e
# === DSRC Configuration ===
DSRC="/Users/vn58d6a/Documents/DSHub/milestones/milestone-dsrc"
cd "$DSRC" || exit 1
git fetch origin
git switch main
git pull --ff-only origin main
IND_LIST=("ind1" "ind2" "ind3")
for IND in "${IND_LIST[@]}"; do
  if [ "$IND" == "ind1" ]; then
    ENG_REPO="/Users/vn58d6a/Documents/DSHub/milestones/eng1-repo-v3"
    ENG_BRANCH="main"
  elif [ "$IND" == "ind2" ]; then
    ENG_REPO="/Users/vn58d6a/Documents/DSHub/milestones/eng2-repo-v3"
    ENG_BRANCH="main"
  elif [ "$IND" == "ind3" ]; then
    ENG_REPO="/Users/vn58d6a/Documents/DSHub/milestones/eng3-repo-v3"
    ENG_BRANCH="dev"
  else
    echo "Unknown IND: $IND — skipping"
    continue
  fi
  echo "➡️ Forwarding $IND to $ENG_REPO:$ENG_BRANCH"
  cd "$ENG_REPO" || { echo "Cannot access $ENG_REPO"; continue; }
  # SAFELY update ENG branch
  git fetch origin "$ENG_BRANCH"
  git switch "$ENG_BRANCH"
  git pull --ff-only origin "$ENG_BRANCH" || {
    echo "❌ Cannot fast-forward $ENG_BRANCH — skipping $IND"
    continue
  }
  # Check for dirty working directory
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "⚠️ Uncommitted changes in $ENG_REPO — skipping $IND"
    continue
  fi
  # Replace IND directory with latest from dsrc
  rm -rf "$IND"
  cp -r "$DSRC/$IND" "$IND"
  echo "Last sync: $(date)" > "$IND/.last_synced"
  # Check for conflict markers
  if grep -r -I -l '<<<<<<<' "$IND" > /dev/null; then
    echo "❌ Conflict markers found in $IND — skipping"
    rm -rf "$IND"
    continue
  fi
  git add "$IND"
  git commit -m "🔄 Sync $IND from dsrc/main to $ENG_BRANCH at $(date)" || echo "✅ No changes to commit for $IND"
  git push origin "$ENG_BRANCH"
done
echo "✅ All INDs processed."
