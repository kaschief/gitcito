# shellcheck shell=bash disable=SC2154
# 67. branches-behind — "which of my other branches fell behind?"
#
# A clone whose teammate has pushed to several branches since you last pulled.
# Your clone has fetched, so every tracking ref is current, but no local branch
# has been caught up — the state the Pull button's dot and its "Other branches
# behind" section exist for.
#
#   main             checked out, behind 1 (the count pill on Pull)
#   feature/search   behind 3
#   release/2.4      behind 2
#   docs/install     behind 1
#   fix/typo         ahead 1 and behind 1: diverged, so left out of the menu
#   spike/cache      no upstream, so left out of the menu
#
# Verify:
#   • The Pull button shows a 1 pill and a dot on its arrow; the tooltip says
#     3 other branches have commits to pull.
#   • The arrow's menu lists Pull feature/search ↓3, Pull release/2.4 ↓2 and
#     Pull docs/install ↓1, then Pull all 3 branches.
#   • Pull all moves the three refs without touching the working tree; ⌘Z puts
#     all three back.
R="$ROOT/branches-behind"
REMOTE="$ROOT/branches-behind-origin.git"
MATE="$ROOT/branches-behind-teammate"

rm -rf "$REMOTE" "$MATE"
git init -q --bare "$REMOTE"

new_repo "$R"
printf '# Catalog\n\nThe product catalog service.\n' > "$R/README.md"
git -C "$R" add -A && git -C "$R" commit -qm "init: catalog service"
git -C "$R" remote add origin "$REMOTE"
git -C "$R" push -q -u origin HEAD

for b in feature/search release/2.4 docs/install fix/typo; do
  git -C "$R" checkout -qb "$b" main
  printf '%s\n' "$b" > "$R/$(echo "$b" | tr '/' '-').txt"
  git -C "$R" add -A && git -C "$R" commit -qm "start $b"
  git -C "$R" push -q -u origin "$b"
done
git -C "$R" checkout -qb spike/cache main
git -C "$R" commit -q --allow-empty -m "try an in-memory cache"
git -C "$R" checkout -q main

# ── The teammate pushes to everything ──
git clone -q "$REMOTE" "$MATE"
git -C "$MATE" config user.email "playground@example.com"
git -C "$MATE" config user.name "Playground"
mate_commits() {
  local branch="$1" n="$2" i
  git -C "$MATE" checkout -q "$branch"
  for i in $(seq 1 "$n"); do
    printf '%s change %s\n' "$branch" "$i" >> "$MATE/CHANGES.md"
    git -C "$MATE" add -A && git -C "$MATE" commit -qm "$branch: change $i"
  done
  git -C "$MATE" push -q origin "$branch"
}
mate_commits main 1
mate_commits feature/search 3
mate_commits release/2.4 2
mate_commits docs/install 1
mate_commits fix/typo 1

# Your own unpushed commit on fix/typo makes it diverge.
git -C "$R" checkout -q fix/typo
printf 'teh -> the\n' >> "$R/fix-typo.txt"
git -C "$R" add -A && git -C "$R" commit -qm "fix another typo"
git -C "$R" checkout -q main

# Fetched, so the counts are known; nothing pulled.
git -C "$R" fetch -q origin
rm -rf "$MATE"

summary "branches-behind" "Several local branches behind their fetched upstream (plus one diverged, one untracked) for the Pull button's dot and menu"
