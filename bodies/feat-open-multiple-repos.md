## Summary

**The problem.** Open repository takes one folder per trip through the picker. Anyone setting up
Gitcito for the first time, rebuilding a group after a reinstall, or bringing a handful of related
repositories (a service and its libraries, a monorepo's satellites) into a group has to open the
dialog, navigate to the same parent folder and pick one folder, again and again.

**What changes.** The picker now accepts a multiple selection (⌘-click, Shift-click; Ctrl-click on
Windows and Linux). Every place that opens it does the right thing with several folders:

- the welcome screen's **Open repository**, the app menu / command palette command, and the launcher
  each open a tab per repository;
- **Open repository** inside a group, and the launcher opened from a group, add each repository to
  that group.

In a pick of several folders, two kinds are skipped instead of opened, and each is named in an info
toast so nothing disappears silently:

- a repository that is **already open** (in any tab, or already in the target group) - so a picked
  set never produces a duplicate tab;
- a folder that is **not a Git repository** - so one stray folder does not leave a broken tab
  among the good ones.

One skipped folder is named on its own ("app is already open"); several are counted and listed in
one message.

**A single pick behaves exactly as before**: an already-open repository is focused, and a plain
folder still opens with the offer to initialise it.

**How.**

- `src/main/index.ts`: a new `dialog:selectDirectories` handler (`openDirectory`,
  `createDirectory`, `multiSelections`); the existing single-folder `dialog:selectDirectory` used by
  clone, locate and settings pickers is untouched.
- `gitService.isRepository(path)` in `src/main/git.ts`: false for a missing path or a non-directory,
  otherwise `checkIsRepo()`. It is in `READ_METHODS` (it only reads).
- Preload, `env.d.ts` and `infrastructure/api.ts` expose the two new calls.
- `src/renderer/src/lib/repositoryPick.ts`: `planRepositoryPick`, the pure decision of what opens and
  which notices to show, returning `{ key, vars }` per the i18n rules.
- `src/renderer/src/openRepositories.ts`: `chooseRepositories()`, which shows the picker, checks each
  folder (only in a multi-pick), shows the notices and returns what to open. The four call sites
  (`Welcome`, `GroupView` in `App.tsx`, `LauncherModal`, `openRepositoryDialog`) use it.
- Four new keys (`repos.skippedOpenOne/Many`, `repos.skippedNotRepoOne/Many`) translated in all 16
  locales with identical placeholders.
- `docs/help/getting-started.md#open-a-repository` describes the multi-pick and its limits.

**Benefits.** Setting up a workspace or a group goes from N trips through the panel to one. No new
UI, no new setting: the existing button simply does more.

**Limits.**

- The picker cannot grey out already-open repositories (or plain folders) beforehand: Electron's
  `showOpenDialog` does not expose an NSOpenPanel delegate, so the check happens after you click Open.
- A folder inside a repository counts as a repository (that is what `git rev-parse` says), as it
  already does for a single pick.
- The "already open" check compares slash-normalised paths; it does not resolve symlinks.

**Tests.**

- `test/gitService.test.ts` - "picking several folders to open": `isRepository` is true for a
  playground repository, false for a fresh temporary folder and for a missing path.
- `test/pureLogic.test.ts` - `planRepositoryPick`: single pick passes through untouched; a mixed
  pick opens only fresh repositories and names the one open and the one plain folder; several
  skipped folders are counted and listed in one notice each (including a Windows path).

**How to test by hand.**

1. `npm run dev`, close any tabs, click **Open repository** on the welcome screen.
2. In one parent folder, ⌘-click two or three repositories and click Open: one tab each.
3. Open the picker again and select one of those repositories plus a new one plus a plain
   (non-Git) folder: only the new one opens; a toast names the already-open repository and another
   names the plain folder.
4. Create a group, use its **Open repository**, select several repositories: each joins the group;
   pick one already in the group alongside another and see it named and skipped.
5. Pick a single plain folder: it opens as before with the offer to initialise it.

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
- [x] `npm test` passes (the touched files: `gitService`, `pureLogic`, `i18n`)
- [x] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (no new surface)
- [ ] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs`
- [x] Destructive actions confirm first; reversible ones offer an undo (nothing destructive)
- [ ] Screenshot entry added to `examples/screenshots/shots.config.mjs`

### Show it

n/a — the change lives in the native folder picker (a multiple selection), which the screenshot
tooling cannot capture; the only new in-app output is an info toast naming skipped folders.
