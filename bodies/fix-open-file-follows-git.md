## Summary

**The problem.** When you open a working-tree file (the Unstaged or Staged diff, or File View), the viewer's source is fixed at that moment. If something outside Gitcito then moves the file — `git add` in a terminal, a coding agent that stages and commits its own work, another Git client — the pane keeps diffing the side the file has left:

- Staged elsewhere: the header still says **Unstaged**, the diff keeps offering **Stage hunk** on a change that is already staged, and as soon as the view reloads (coming back to the window, say) it reads **"No changes to display"** under that Unstaged chip.
- Committed elsewhere: the working-tree diff is empty, so the pane goes blank, although the change is right there in the new commit.
- Undone or amended elsewhere while you read the file at `HEAD`: the view stays on a commit that has left the branch.

Anyone who works with a terminal or an agent next to Gitcito hits this; it is most common with agents, which stage and commit in quick succession while you are reading their diff.

I confirmed it on `main`: open `config.ts` in the `word-diff` playground repo on its Unstaged diff, run `git add config.ts` in a terminal, focus the window again. The pane reads "No changes to display" under **UNSTAGED** (before screenshot below).

**What changes.** A small hook, `useFollowWipFile`, called from `FileViewer`, re-points the open view when the repository is re-read:

| What happens outside Gitcito | What the open file does |
|---|---|
| The file is staged | Switches to the **Staged** diff |
| The file is unstaged | Switches back to the **Unstaged** diff |
| Part of the file is staged | Stays on the side you chose; both are real |
| The file is committed | Follows it into the new commit (`HEAD`), so the diff stays on screen |
| The change is discarded or stashed | Closes, as there is nothing left to show |
| The commit you are reading is undone | Goes back to the Staged or Unstaged diff, wherever the change landed |
| …and its changes thrown away (`reset --hard`) | Closes, rather than show the parent, which is a different change |
| That commit was `HEAD` and is amended or reworded | Moves on to the rewritten commit |

The decisions are pure functions in `lib/wipFileFollow.ts` (`followWipFile`, `followCommitFile`, `headOf`, `headMove`). Two details worth a reviewer's eye:

- **Committed vs discarded.** When the file stops being a working change, the hook compares HEAD with where it was the last time the file was still listed. HEAD moved and holds the file: committed, follow it. HEAD unmoved: discarded or stashed, close. Without this, discarding a file that the last commit had also touched would "follow" it into that old commit.
- **HEAD is read from the checked-out branch**, with the log's `HEAD ->` decoration only as a fallback for a detached HEAD. The graph lists stash bases, so "is the commit still in the log" is not a reliable signal that it was undone; "where did HEAD go" is.

Committing from Gitcito's own composer is unchanged: it still closes the file, as it does today. The hook never acts on a view the user has since replaced or closed (it checks before applying an async answer).

**Benefits.** The chip in the viewer header always says where the file is now; an agent's commit no longer leaves you staring at an empty pane; undo/amend from a terminal no longer strands the view on a commit that left the branch.

**Limits.**
- It reacts when the repository is re-read: immediately via the file watcher, otherwise on the next refresh.
- Paused while the file is being edited in place, so an unsaved draft is never pulled away.
- Follows only into the commit `HEAD` points at. If several commits land at once and the file is not in the newest one, the view closes.
- Conflicted files are left to the conflict resolver.
- A commit that leaves history some other way (rebased away further back) keeps its view; its content still exists.
- Out of scope: re-reading the content of a file that stays on the same side while another tool edits it (today that still happens on window focus, as before).

No new strings, so no locale changes. `docs/help/diffs.md` gets a "When the file changes under you" section with the table above and the limits.

**Tests.** `test/pureLogic.test.ts` covers `followWipFile` (flip to staged, flip to unstaged carrying `untracked`, partly staged keeps the chosen side, conflicted left alone, file gone reported as left), `followCommitFile` (soft and mixed undo land on the right side, amend looks in the new HEAD, hard undo closes, unmoved HEAD keeps the view) and `headMove`/`headOf` (commit vs amend vs undo, an undo seen even when a stash keeps the undone commit in the log, HEAD read from the branch when the log label is missing). I also checked the commit path in the built app: with `config.ts` open on its Unstaged diff, `git add config.ts && git commit` from outside moved the view to the new commit's diff with its short hash in the chip.

**How to test by hand.**
1. `npm run dev`, open `examples/playground/word-diff`, click `config.ts` in the working changes (Unstaged diff).
2. In a terminal: `git -C examples/playground/word-diff add config.ts`. The chip turns **Staged** and the diff stays on screen.
3. `git reset config.ts`: back to **Unstaged**.
4. `git add config.ts && git commit -m test`: the view moves to the new commit (short hash in the chip).
5. `git reset --soft HEAD~1`: back to the **Staged** diff.
6. `git commit -m test` (the view follows into it), then `git commit --amend -m test2`: it moves on to the amended commit.
7. `git reset --hard HEAD~1` while reading that commit: the view closes.
8. Modify a file, open it, then `git checkout -- <file>`: the view closes instead of jumping to an old commit.
9. `npm run playground:rebuild` afterwards.

## Type of change

- [ ] `feat:` New feature
- [x] `fix:` Bug fix
- [ ] `docs:` Documentation
- [ ] `chore:` Maintenance / tooling
- [ ] `refactor:` Code change (no feature, no bug fix)
- [ ] `perf:` Performance improvement
- [ ] `test:` Tests only

## Checklist

- [x] PR title follows `type(scope): description` format
- [x] `npm run typecheck` passes
- [x] `npm run lint:i18n` passes — every new string is in **every** locale file (no new strings)
- [x] `npm run lint:docs` passes — every new surface has a handbook page
- [ ] `npm test` passes (ran `test/pureLogic.test.ts`, `test/i18n.test.ts` and `test/docs.test.ts`; not the full suite)
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (n/a — no new surface)
- [ ] `README.md` mentions it in one line, linked to its page (n/a — a fix to an existing view)
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` (n/a)
- [ ] Destructive actions confirm first; reversible ones offer an undo (n/a — no new actions)
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/44e870b7f4e61ecb3fcbdbb6890b4860735c69d7/file-follows-git-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/402146a01b72b775c8731e054789abbb66d6f570/docs/screenshots/file-follows-git.webp)

`config.ts` opened on its Unstaged diff, then staged from outside the app. Before this change the same steps leave "No changes to display" under an **UNSTAGED** chip; after it, the viewer shows the **STAGED** diff.

---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
