## Summary

**The problem.** A diff in Gitcito can stage a hunk or selected lines, but only from unstaged changes, and nothing else. Anyone who works in small, deliberate commits hits the gaps daily:

- staged one hunk too many? The only way back is to unstage the whole file and start again;
- want to throw away one experiment and keep the rest of the file? Discard works on whole files only;
- want to undo one part of an old commit, or bring back one piece of a stash? There is no way short of copying by hand;
- the existing Stage hunk and Stage N lines leave no undo entry and do not refresh the commit panel, and a line selection that reaches the last line of a file builds a patch git rejects.

**What changes.** Every diff you can act on carries the actions that fit it: on each hunk's `@@` bar, on a line selection's bar, and on a new right-click menu on any diff line.

| Diff | Actions |
|---|---|
| Unstaged changes | Stage hunk, Discard hunk (and the same for selected lines) |
| Staged changes | Unstage hunk |
| A commit | Revert hunk: undone in the working tree, no commit made |
| A stash | Apply hunk: brought into the working tree, the stash is kept |

Right-clicking a line offers *Stage this line* / *Discard this line* (or Unstage, Revert, Apply), its whole hunk, and *Copy line*. On a line that is part of a selection the menu acts on the selection instead, and with text highlighted it offers *Copy*.

How it works:

- One main-process method, `applyHunkPatch(repo, patch, target, reverse, ignoreWhitespace)`, runs `git apply` forwards or reversed against the index or the working tree. It goes through the existing dispatcher as a write (not in `READ_METHODS`).
- Store side, `repoActions.applyHunk` runs it through `run()` with an **undo entry**: the same patch applied the other way. **Discard confirms first**, and working-tree actions take a WIP guard snapshot first, like the other destructive operations.
- Revert and apply cut their patch from history, so the file has often moved on. When plain `git apply` refuses, the method falls back to a **three-way merge** (`git merge-file`) between the blob the patch was cut from, that blob with the patch applied, and the working copy. Non-overlapping edits merge cleanly; overlapping ones get conflict markers (`<<<<<<< working copy` … `>>>>>>> hunk`) and an info toast says so. A merge that changes nothing is reported as "does not apply", not as success.
- With **Ignore whitespace** on, the patch is applied with `--ignore-whitespace`, so the actions do what the visible diff shows and leave hidden whitespace changes in place.
- Line patches are built **mirrored** for reversed application (an unselected addition becomes context, an unselected deletion is dropped), and the trailing empty line from parsing no longer becomes a phantom context line past the end of the file (that bug also broke the existing Stage N lines whenever a hunk reached the end of a file).
- **Split view** gets line selection too. An edited line's old and new cells select together, so staging either side stages the whole edit; only runs that pair one to one join up.
- Hunk buttons are now **sticky** against the visible edge of the diff, so a long line no longer pushes them off-screen, and they stay in place but disabled (with a tooltip) while the last action is landing.

Patch building moved out of `DiffViewer.tsx` into `lib/hunkPatch.ts` (pure, tested); `splitEditPartners` joins `lib/diff.ts`.

**Benefits.** The precision staging already had now applies in every direction: back out of the index, away from the working tree, out of history and out of a stash. Everything is undoable from the toolbar or ⌘/Ctrl+Z.

**Limits.**

- New untracked files have no hunks: stage or discard the whole file. A stash's untracked files are the exception, since Apply hunk creates them.
- Conflicted files show a combined diff (`diff --cc`) that `git apply` cannot read, so they get no hunk actions.
- Undo is the same patch reversed, so it works only while those lines are unchanged.
- The three-way fallback needs the blob named in the patch's `index` line; if git no longer has it, or the file is new or deleted, the original `git apply` error is reported and nothing changes.
- The right-click menu has no icons, matching the other file menus in the app.

**Tests.**

- `test/hunkActions.test.ts` (new, real git against clones of the `line-staging` fixture): discard of selected lines and its undo; unstage of selected lines; revert of selected lines from a commit; apply of selected lines from a stash; the three-way fallback when the file was edited since; conflict markers and the conflict count on overlap; staging from a whitespace-ignoring diff; both halves of a split edit staged from one side; a selection that reaches the end of the file; refusing a hunk that no longer matches without touching the file.
- `test/pureLogic.test.ts`: `extractHunks` / `singleHunkPatch`, forward and reverse line-patch shapes, and no line past the end.
- `test/diff.test.ts`: `splitEditPartners`.
- Every new string is in all 16 locales, using each locale's existing word for "hunk" and "stage".

**How to test by hand.** Run `npm run playground`, open `examples/playground/line-staging`, and open `config.js` from Unstaged files in Diff view.

1. Click the `debug` and `tls` lines. The bar shows *Stage selected (2)* and *Discard selected (2)*. Stage them and check that only those two lines move to Staged. Then press ⌘/Ctrl+Z and check that they come back.
2. Right-click the `host` line and choose *Discard this line*. Confirm, and check the line is back to `localhost`. Undo restores it.
3. Open the staged `config.js` and use *Unstage hunk*.
4. Commit something, open that commit's file and use *Revert hunk*; check the working tree has the reverted change and no commit was made. Edit an overlapping line first to see the conflict markers and the notice.
5. Stash a change, open the stash's file and use *Apply hunk*; check the stash is still listed.
6. Turn on Split. Click either side of the edited `host` row and check both halves select.

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
- [x] `npm test` passes (one failure in `test/repoChat.test.ts`, "honours ignore rules even for paths checked as tracked context", fails the same way on unmodified `main` in my checkout, where `node_modules` is a symlink; unrelated to this change)
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated (Staging gains a "Hunk and line actions" section; Diffs and Stashes point to it)
- [x] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (no new surface: the confirm is the generic confirm dialog)
- [x] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` (not needed: staging is already on the front page)
- [x] Destructive actions confirm first; reversible ones offer an undo
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs` (`hunk-line-actions`)

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/287476506499b93ebdcc1bd22a6dd6c860feb915/hunk-line-actions-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/ddd3ced7ffcf217f8d62aeff46838a703ecd7058/docs/screenshots/hunk-line-actions.webp)

Two lines selected: the bar offers Stage selected and Discard selected, the hunk bar has Stage hunk and Discard hunk, and the right-click menu is open on a selected line. Before this change, the same diff offered only *Stage 2 lines* and *Stage hunk*, and right-click did nothing.
