## Summary

Follow-up to #56, covering the two items left open in the merge comment.

**1. Undo after a conflicted hunk merge was not exact.**

When a revert, apply or discard falls back to the three-way merge (`mergeHunkIntoFile`), the file on disk is the
result of `git merge-file`, not of the patch. Undo then ran the same patch the other way, which either failed
(the patch never applied as is) or merged again and left a second layer of conflict markers on top of the first.
Redo had the same problem in reverse.

What changes:
- When the merge fallback writes a file, `src/main/git.ts` remembers the file's exact bytes before and after
  (session only, the latest 50) and `applyHunkPatch` returns an id for it as `merge`.
- A new `restoreHunkMerge(repoPath, merge, 'before' | 'after')` writes those bytes back. It refuses if the file no
  longer matches the other side (edited since, or the conflict resolved by hand), so undo never overwrites work
  the undo entry never saw. It takes a guard snapshot first, like the other worktree writes, and is a write under
  the repo lock (not in `READ_METHODS`).
- `repoActions.applyHunk` uses it for undo and redo when `merge` is set; the plain `git apply` path is unchanged.

**2. Cancelling the hunk-discard confirm left its promise pending.**

`applyHunk` waited on the confirm's `onConfirm` only, so Cancel, Esc, the ✕ or a click outside never settled it.

What changes:
- The `confirm` modal spec gets an optional `onCancel`. `ConfirmModal` calls it when the dialog goes away by any
  route other than the confirm or secondary button, including another confirm replacing it.
- `applyHunk` resolves `false` on cancel, so the caller's `.then` runs. Existing confirms are untouched, since
  `onCancel` is optional.

**Limits.** The remembered bytes live in the main process for the session, so an undo entry for a merged hunk
from before a restart cannot be replayed (the undo stack does not survive a restart either). If the file changed
after the merge, undo reports that and leaves the file alone rather than trying to merge back.

**Tests.** `test/hunkActions.test.ts`: a conflicted revert is undone and redone to the exact bytes, and refused
once the conflict is resolved by hand; a plain apply returns no `merge`. The cancel path is UI-only and was not
given a test.

**Gate.** `npm run typecheck`, `npm run lint:i18n`, `npm run lint:docs` and `npm run build` pass. The full suite
passes apart from 7 tests in `test/newFeatures.test.ts` (tree-sitter) and `test/repoChat.test.ts`, which fail the
same way on current `main` in my environment.

No visual change, so no screenshots.

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust,
split or rework it.
