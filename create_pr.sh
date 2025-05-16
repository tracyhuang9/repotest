#!/bin/bash
set -e

DSRC="/Users/vn58d6a/Documents/DSHub/milestones/milestone-dsrc"
cd "$DSRC" || exit 1

IND_LIST=("$@")
if [ ${#IND_LIST[@]} -eq 0 ]; then
  IND_LIST=("ind1" "ind2" "ind3")
fi

TARGET_BRANCH="main"
REPO_SLUG="xxxx/dsrc-repo"

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI not authenticated. Run: gh auth login"
  exit 1
fi

for IND in "${IND_LIST[@]}"; do
  echo "🔁 Processing $IND"
  SOURCE_BRANCH="sync/$IND"
  PR_TITLE="Sync $IND → $TARGET_BRANCH"
  PR_BODY="Automated pull request from $SOURCE_BRANCH to $TARGET_BRANCH"

  git fetch origin "$SOURCE_BRANCH" "$TARGET_BRANCH"

  echo "📍 Checking out $SOURCE_BRANCH"
  git checkout "$SOURCE_BRANCH"
  git reset --hard origin/"$SOURCE_BRANCH"

  echo "🔍 Checking for commits in $SOURCE_BRANCH not in $TARGET_BRANCH..."
  if [ -z "$(git log --oneline origin/$TARGET_BRANCH..origin/$SOURCE_BRANCH)" ]; then
    echo "✅ No new commits in $SOURCE_BRANCH — skipping PR."
    continue
  fi

  echo "🔎 Checking for open PRs"
  if gh pr list --repo "$REPO_SLUG" --head "$SOURCE_BRANCH" --base "$TARGET_BRANCH" --state open | grep -q "$SOURCE_BRANCH"; then
    echo "⚠️ Open PR already exists for $SOURCE_BRANCH — skipping"
    continue
  else
    echo "📬 No open PR found — creating PR"
  fi

  echo "🚀 Creating PR from $SOURCE_BRANCH → $TARGET_BRANCH"
  gh pr create \
    --base "$TARGET_BRANCH" \
    --head "$SOURCE_BRANCH" \
    --repo "$REPO_SLUG" \
    --title "$PR_TITLE" \
    --body "$PR_BODY"

  echo "✅ PR created for $IND"
  echo "--------------------------------------"
done

echo "🎉 All IND branches processed."
