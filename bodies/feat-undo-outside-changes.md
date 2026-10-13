## Summary

**The problem.** Gitcito's Undo only knows what Gitcito did. Anyone who works half in a terminal, half
in the app (or who lets a coding agent, an editor's git panel or a script commit for them) hits the
same wall: they commit in the terminal, notice a typo, switch to Gitcito and press Undo, and the
button is greyed out. The reflog has the exact record needed to walk it back (which ref moved, from
where, when, by whom), but the app's undo stack is in-memory and only ever sees its own actions.

**What changes.**

- **Undo reaches the reflog.** When the newest change to `HEAD` was made outside the app, Undo (toolbar,
  ⌘Z, app menu) offers to walk it back. Whichever happened last, an app action or an outside one, is
  what gets undone; app entries now carry a timestamp so the two are ordered correctly.
- **Never silent.** An outside change is previewed in the standard confirm dialog first: what it was
  ("commit “fix: …”", "reset of main", "switch from main to dev"), when, the identity git recorded, and
  exactly what the undo will do. If the commit is already on a remote, the preview says so and warns
  that pushing afterwards would need a force push.
- **Safe actions per kind** (the mode of the original reset is not recorded, so it always picks the
  one that cannot lose work):

  | Last outside change | Undo | Redo |
  |---|---|---|
  | Commit / amend | `reset --soft` to before it; changes stay staged | `reset --soft` back |
  | Reset | `reset --keep` (clean tree) or `--mixed` (dirty tree) to where it was | the same, forward |
  | Merge, pull, rebase, cherry-pick, revert | `reset --keep`; git refuses rather than overwrite local changes | `reset --keep` forward |
  | Checkout / switch | checks the previous ref out again | checks the later one out |

- **Stale-proof.** Both Undo and Redo re-check that `HEAD` is still where the preview said; if anything
  moved it in the meantime, nothing happens and a toast explains why.
- **Walks back further.** Pressing Undo again continues to the outside change before; the resets the
  feature itself wrote are skipped. The walk stops at the first change the app made itself, so things
  are never undone out of order.
- **Tooltips name the next step.** Hovering Undo / Redo shows "Undo commit “…”" / "Redo …", and says
  when the undo comes from git's reflog.

**How it works.**

- `gitService.recentRefMoves` (a `READ_METHODS` read) tails the HEAD reflog and the checked-out branch's
  reflog straight from disk (the last 64 KB; no process spawn) and parses old/new sha, actor, time and
  message (`src/shared/refMoves.ts`). It rides along with the `branches` refresh slice.
- To tell the app's own moves from foreign ones, the git dispatcher stamps a wall-clock window around
  every write it runs under the repo's exclusive lock (`src/main/appWrites.ts`); a reflog line inside
  one is `byApp` and stays on the app's own undo stack. The window ends on the floor of the end
  second, so an outside change made in the second right after an app write is not mistaken for the
  app's own.
- All decisions (classification, which line to undo, which reset mode, labels and effect text as
  `{ key, vars }`) are pure logic in `src/renderer/src/lib/externalUndo.ts`; the store only executes
  the plan. After an outside undo the step becomes an ordinary entry on the redo stack.

**Benefits.** Undo becomes trustworthy across tools: the app is a safe place to back out of something
done anywhere, with a preview rather than a blind `git reset` copied from Stack Overflow.

**Limits** (also in the handbook):

- The reflog records only ref moves. Staging, stashing, file edits, and creating or deleting branches
  or tags outside the app cannot be undone this way.
- Uncommitted work that an outside `reset --hard` discarded was never recorded and cannot come back.
- A branch's first commit has no earlier position, so it cannot be uncommitted this way.
- Git records one identity for every tool on a machine, so "by" names the identity, not the tool.
- Write windows live in memory: after a restart, the app's own earlier commits look like outside
  ones and become undoable this way too.

**Tests.** New `test/externalUndo.test.ts` (13 tests): reflog parsing (including a torn first line
from tailing), planning for commit / amend / reset / pull / checkout, leaving app-made moves alone,
refusing a root commit, walking back past moves already undone, refusing when HEAD moved, ordering
against the app's own stack, write-window attribution (including the second right after a write),
`recentRefMoves` registered as a read, and real-git runs that see a terminal commit and a terminal
checkout and verify the planned soft reset keeps the change staged. 18 new keys, translated into all
16 locales with identical placeholders.

**How to test by hand.**

1. Open any repository in Gitcito.
2. In a terminal: edit a file, `git commit -am "test: outside commit"`.
3. Back in Gitcito, hover **Undo**: the tooltip reads *Undo commit “test: outside commit” — made
   outside Gitcito, read from git's reflog*. Click it: the preview names the commit, the time and the
   author. Confirm: the commit is gone and its change is staged.
4. Press **Redo**: the commit is back with the same sha.
5. Try `git checkout -b tmp` in the terminal, then Undo: you are back on the previous branch.
6. Make a commit in the app, then one in the terminal, and press Undo twice: the terminal commit is
   offered first (with the preview), then the app's own one (as before, no preview).
7. Push a commit from the terminal, then Undo: the preview warns that it is already on the remote.

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
- [x] `npm test` passes (locally one unrelated failure, `repoChat.test.ts` "honours ignore rules", because this checkout's `node_modules` is a symlink (git: "pathspec is beyond a symbolic link"), not related to this change)
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [x] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (no new surface: the preview reuses the confirm modal)
- [ ] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs`
- [x] Destructive actions confirm first; reversible ones offer an undo
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/f7e0515987d67e70f649de3b84b279bf627c0eaa/undo-outside-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/ee34f82b5a9cabb83aad9e99c6457950703612df/docs/screenshots/undo-outside.webp)

The preview Gitcito shows before undoing a commit made in a terminal (`docs/help/recovery.md#changes-made-outside-gitcito`).

---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
