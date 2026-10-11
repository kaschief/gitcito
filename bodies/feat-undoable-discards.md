## Summary

**The problem.** Discard is the one everyday action in the commit panel that cannot be taken back.
Right-click → *Discard changes* on the wrong row, or the bin beside the commit button, and the work
is gone: the confirm honestly says "This cannot be undone", and the only way back is to know that a
guard snapshot exists and dig through the snapshots dialog. Everyone who stages by hand hits this
sooner or later.

**And a real bug in Discard all.** Discard all runs `git reset HEAD -- .` first, then discards the
listed files. A file that was `git add`ed but never committed is in the *Staged* list as a tracked,
added file. After the reset it is untracked, so the tracked discard path tries `checkout -- f`, then
`checkout HEAD -- f`, then `git rm -f -- f` — all three fail on a file git no longer knows about,
and the last failure is swallowed. Result: after "Discard all changes", the new file is still on
disk and reappears in *Unstaged* as untracked. Reproduced on `main` (4.12.0) with `git init`,
commit, `echo x > added.txt && git add added.txt`, then the same calls Discard all makes:
`git status --porcelain` afterwards still prints `?? added.txt`. The new
`discard all > removes a staged new file instead of leaving it untracked` test fails on `main` for
exactly this reason.

**What changes.**

- **Every file-level discard is undoable**: a file or a selection (row context menu), a folder
  (folder context menu), and Discard all. When the confirm opens, Gitcito saves what is staged and
  what is on disk as two plain git trees (`captureWork`: `write-tree` for the index, then
  `add -A` + `write-tree` in a throwaway `GIT_INDEX_FILE`; no ref, the real index untouched — the
  same technique the WIP snapshots already use). The discard then lands on the normal undo stack
  ("Undone: discard of "src/a.ts"", "Undone: discard of all changes"), and **Undo** (toolbar, or
  *Repository → Undo last operation*) runs `restoreWork`, which puts back **only the discarded
  paths**: their staged version into the index (`git restore --staged --source=<index tree>`) and
  their content on disk (`git restore --worktree --source=<worktree tree>`). Staged and unstaged
  parts of the same file come back separately; new and untracked files (including a collapsed
  untracked folder such as `fresh/`) are recreated; a path that did not exist at capture time is
  removed. Redo runs the discard again.
- **The confirm tells the truth.** When the work was saved it says "You can undo this." (and for
  Discard all, that new files are included); when it could not be saved, it keeps the existing
  "This cannot be undone." text.
- **Discard all removes newly added files.** When `git rm -f` fails because the path is no longer in
  the index, `discard` deletes the file from disk (after checking the path stays inside the
  repository), exactly as discarding an untracked file would. Discard all also now discards a file
  listed in both *Staged* and *Unstaged* once instead of twice, and runs as one queued operation
  with one undo entry, instead of an unqueued `unstageAll` followed by two separate runs.
- The three call sites in `CommitComposer` now share one store action,
  `repoActions.discardChanges`, which replaces the old `repoActions.discard` (it had no other
  callers). The AI/repo-chat discard path (`askActionRun`) is untouched.

**Benefits.** A mis-click on Discard is now a one-click recovery from the same Undo used for
everything else, with nothing to find in the snapshots dialog. Discard all finally leaves a clean
tree.

**Limits.**

- While a merge still has conflicts, `git write-tree` refuses the index, so nothing is saved: that
  discard gets no undo entry and the confirm keeps "This cannot be undone."
- The state is saved when the confirm opens. If a file is edited while the dialog is up, Undo
  restores the version from when it opened.
- Undo restores the discarded paths only; anything changed elsewhere since is left alone, but a
  discarded file edited again after the discard is overwritten with the saved version.
- Ignored files are never discarded, so they are never saved.
- The saved trees are unreferenced objects: they live as long as the in-memory undo entry, and
  `git gc` may prune them after its grace period (two weeks by default). Guard snapshots remain the
  longer-lived safety net.
- Saving runs `git add -A` in a throwaway index, so a very large untracked file is hashed into the
  object store when the confirm opens (the guard snapshot already does the same on every discard).
- A staged rename that Discard all unstages still leaves the old path deleted, as on `main` — the
  status list carries only the new path. Unchanged by this PR.
- Hunk and line discards are out of scope here.

**Tests.** New `test/discardUndo.test.ts`, real git in throwaway repos:
Discard all removes a staged new file (fails on `main`); undo restores staged + unstaged edits of
one file, an untracked file and a staged new file to the identical `git status` / `git diff
--cached`; undo restores a deleted file and an untracked folder; undo touches only the discarded
paths; a path absent at capture time is removed; nothing is saved during a conflicted merge; a path
outside the repository is refused.

Gate run in the branch: `npm run typecheck`, `npm run lint:i18n`, `npm run lint:docs` and
`npm run build` pass; `npx vitest run test/discardUndo.test.ts test/i18n.test.ts
test/pureLogic.test.ts test/docs.test.ts test/gitOps.test.ts` passes (972 tests). The full suite
passes except `repoChat.test.ts > honours ignore rules even for paths checked as tracked context`,
which fails only in my checkout because its `node_modules` is a symlink (`git check-ignore`:
"beyond a symbolic link"); it is unrelated to this change.

New strings (4 keys) are translated in all 16 locales with identical placeholders.
Docs: the *Discarding* section of `docs/help/staging.md` now covers Discard all and a new
*Undoing a discard* subsection with the limits above, plus a screenshot generated by a new
`discard-all-undo` entry in `examples/screenshots/shots.config.mjs` (uses the `change-summary`
playground repo and stages its untracked file first, so the tree holds a staged new file).

**How to test by hand.**

1. In any repo, edit a tracked file, stage part of it, edit it again, and create an untracked
   file. Right-click the edited file → *Discard changes*. The confirm ends with "You can undo
   this." Confirm, then click **Undo** in the toolbar: the staged part is back in *Staged* and the
   rest in *Unstaged*.
2. `echo x > added.txt && git add added.txt`, then press the bin beside the commit button. The
   confirm mentions new files. Confirm: `added.txt` is gone from disk and from both lists (on
   `main` it stays behind as untracked). Undo: it is back, staged.
3. Right-click a folder with changes → *Discard changes in folder*, then Undo: every file in it,
   including an untracked subfolder, is back.
4. Start a merge that conflicts and discard a non-conflicted file: the confirm still says "This
   cannot be undone.", and the toolbar Undo has no entry for it.

## Type of change

- [x] `feat:` New feature
- [x] `fix:` Bug fix
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
- [x] `npm test` passes (one environment-only failure noted above, unrelated)
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (no new surface; the existing confirm modal is reused)
- [ ] `README.md` mentions it in one line, linked to its page (an improvement to an existing action, not a new feature)
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` (no)
- [x] Destructive actions confirm first; reversible ones offer an undo
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/d8b82a7a7175e79e1c4252b78dab9fedf09f1f1b/discard-all-undo-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/38159564df5ff6fd52cbbe7b15cc5be7c7caea10/docs/screenshots/discard-all-undo.webp)

The Discard all confirm over a tree that holds a staged new file. Before this PR it read
"Discard ALL staged and unstaged changes? This cannot be undone." (and left the new file behind);
now it reads "Discard ALL staged and unstaged changes, new files included? You can undo this."
