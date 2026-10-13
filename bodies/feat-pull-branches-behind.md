## Summary

**The problem.** Anyone who keeps several local branches (a release branch, a long-running feature,
a docs branch) and fetches regularly hits this: the fetch learns that teammates pushed to those
branches, but the toolbar only ever talks about the branch you are on. The Pull button's count
pill says `1` for `main` and nothing else, so the only way to find out that `release/2.4` is three
commits behind is to scan the sidebar's ↓ badges, then right-click each branch and pull it one at a
time. People forget, branch off a stale `release/2.4`, and find out at merge time.

**What changes.**

- When other local branches are behind their upstream, a small accent dot lights on the Pull
  button's dropdown arrow. The tooltip names the branch ("release/2.4 also has commits to pull") or
  gives the count ("3 other branches have commits to pull").
- The count pill keeps its meaning (the checked-out branch), so the two never blur: the pill is
  what the button pulls, the dot is what the menu offers.
- The arrow's menu gains an **Other branches behind** section under the three pull modes: one
  **Pull `<branch>`** row per branch with the sidebar's red ↓N badge, most behind first, then
  **Pull both branches** / **Pull all N branches**.
- Past five branches, the rows fold into a single **Pull a branch** row with a flyout, so the menu
  never grows by more than three rows.
- Each pull reuses the existing `pullBranch` (a fast-forward of the ref without a checkout; the
  working tree is not touched). Pull all is one `run()` action with **one undo** that puts every
  ref back where it was, and a redo that pulls them again.

**Benefits.** Branches that fell behind are visible where you already look after a fetch, and
catching them all up is one click and one ⌘Z instead of a hunt through the sidebar. No new git
code, IPC or settings: it builds on `pullBranch`, `setBranchRef` and the branch data the app
already loads.

**Limits.**

- The dot only knows what the last fetch told it; a branch behind on the server but not yet
  fetched does not light it.
- Diverged branches (ahead and behind) and branches without an upstream are left out, because a
  pull without a checkout would refuse them anyway.
- If one branch in a Pull all is refused (for example it moved between the fetch and the click),
  the ones before it stay pulled and the rest are not attempted; the error is toasted as usual.

**Implementation.** `lib/pullOthers.ts` holds the rule (`pullableOthers`: not current, has an
upstream, behind > 0, ahead == 0, sorted most behind first). `Toolbar.tsx` adds the dot and menu
section, `repoActions.pullBranches` in `stores/repo.ts` adds the batched action with undo, and
`MenuItem` gains an optional `behind` count rendered as the existing `.badge.behind`. New strings
are translated in all 16 locales with identical placeholders.

**Tests.**

- `test/pureLogic.test.ts`: `pullableOthers` ordering, and exclusion of diverged and untracked
  branches.
- `test/newFeatures.test.ts`: against the real new `branches-behind` playground repo, the rule
  offers exactly `feature/search ↓3`, `release/2.4 ↓2`, `docs/install ↓1`.
- `test/playground.smoke.test.ts`: the new scenario is registered and openable.
- New playground scenario `examples/scenarios/69-branches-behind.sh`: `main` behind 1, three
  branches behind, one diverged, one untracked.

**How to test by hand.**

1. `bash examples/setup-playground.sh` and open `examples/playground/branches-behind`.
2. The Pull button shows a `1` pill and a dot on its arrow; hover it for the tooltip.
3. Open the arrow: the section lists the three branches with ↓3, ↓2, ↓1 and **Pull all 3
   branches**. `fix/typo` (diverged) and `spike/cache` (no upstream) are absent.
4. Click **Pull all 3 branches**: the three refs move, the working tree and `main` are untouched,
   and the dot goes away. Press ⌘Z: all three go back and the dot returns.

## Type of change

- [x] `feat:` New feature
- [ ] `fix:` Bug fix
- [ ] `docs:` Documentation
- [ ] `chore:` Maintenance / tooling
- [ ] `refactor:` Code change (no feature, no bug fix)
- [ ] `perf:` Performance improvement
- [ ] `test:` Tests only

## Checklist

- [x] PR title follows `type(scope): description` format
- [x] `npm run typecheck` passes
- [x] `npm run lint:i18n` passes — every new string is in **every** locale file
- [x] `npm run lint:docs` passes — every new surface has a handbook page
- [ ] `npm test` passes (full suite not run; these pass: `test/pureLogic.test.ts`, `test/newFeatures.test.ts`, `test/gitOps.test.ts`, `test/playground.smoke.test.ts`, `test/i18n.test.ts`, `test/docs.test.ts`)
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated (`syncing.md` gains a "From the Pull button" section)
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (n/a: no new modal, page tab or command)
- [ ] `README.md` mentions it in one line, linked to its page (n/a: small toolbar refinement)
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` (n/a)
- [x] Destructive actions confirm first; reversible ones offer an undo (Pull all has a single undo that restores every ref)
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs` (`pull-branches-behind`)

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/27e3eaac8aa6d490ca7bcf0fdd569cbde44ac58f/pull-branches-behind-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/f02b32ab6b19a13045dab3eb88126be300cfbc5e/docs/screenshots/pull-branches-behind.webp)



---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
