## Summary

**The problem.** When a block of code is cut from one place in a file and pasted
somewhere else, the diff shows it as a red deletion and, further down, a green
addition that has nothing visibly to do with it. Anyone reviewing a refactor —
reordering functions, hoisting a helper, moving a method to the end of a class —
has to read both blocks line by line to discover that nothing actually changed.
On a real refactor that is most of the diff, and it hides the few lines that did
change.

**What changes.** The diff viewer now recognises moved code, in the spirit of
git's own `--color-moved`: a run of deleted lines that reappears, line for line,
as a run of added lines elsewhere in the same file's diff.

- Both ends of a move are tinted blue instead of red/green, in the unified view
  and in both split modes (wrap on and off).
- The sign column (unified) or the gutter (split) shows an arrow pointing at the
  other end — ↓ on the removed copy, ↑ on the added one. Hovering it names the
  other end's line number ("Moved to line 14" / "Moved from line 3").
- Neighbouring moved blocks alternate between two shades of blue, so two moves
  that touch read as two.
- Moved lines skip word-level marks, which would otherwise compare them with
  whatever line happens to sit opposite rather than the copy they came from.
- A **Moved code** toggle in the diff toolbar, on by default, turns it off. Like
  **Word diff**, it only appears when the diff actually contains a move, and its
  state is remembered (`gitcito-diff-moved` in localStorage).

Nothing changes underneath: a moved line is still an ordinary −/+ line, so hunk
staging and line staging behave exactly as before.

**Implementation.** The detection is a pure function,
`lib/movedLines.ts#findMovedLines(lines)`, over the `DiffLine[]` that
`parseDiff` already produces. It indexes added lines by trimmed text, grows a
candidate block from every matching deletion, accepts the longest blocks first
(so a big move is not split by a coincidental small one), and gives each line to
at most one block. `DiffViewer` only adds a class and an arrow to lines it
returns. CSS adds three tokens (`--diff-moved-bg`, `--diff-moved-alt-bg`,
`--diff-moved-fg`) with light-mode values.

**Limits** (also stated on the handbook page):

- Like git, a block needs at least 20 letters and digits to count, so a shuffled
  `}` or `return` is never flagged.
- Moves are found within one file's diff only; code moved to another file is
  still a deletion in one diff and an addition in the other.
- A block that was moved *and* edited is not marked as a whole — only unchanged
  runs around the edit are, if they are long enough on their own.
- Re-indenting lines in place (a deletion run immediately followed by its
  addition run) is not a move. Lines compare trimmed, so a block moved *into* a
  deeper indent elsewhere still counts. Blank lines never start or end a block.

**Tests.** `test/movedLines.test.ts` covers: a simple move with roles, directions
and peers; a move into a deeper indent; the 20-character minimum; in-place
re-indent not counted; an edited block not counted; two separate moves numbered
apart; and longest-block-wins when one line appears twice. A new playground
scenario, `moved-code` (`examples/scenarios/67-moved-code.sh`), leaves a
function moved to the end of `utils.ts` next to an ordinary one-line edit; it is
listed in `test/playground.smoke.test.ts` and drives the new screenshot.

**How to test by hand.**

1. `bash examples/setup-playground.sh 67` (or the full playground), then
   `npm run dev` and open `examples/playground/moved-code`.
2. Select `utils.ts` (unstaged). `parseConfig` is blue at the top (↓) and at the
   bottom (↑); hover an arrow to see the other end's line number. The
   `DEFAULT_TIMEOUT` edit stays red/green with its word-level marks.
3. Click **Split**: the same lines are blue on each side, arrows in the gutter.
   Try with **Wrap** on and off.
4. Turn **Moved code** off: the move reads as plain −/+ again. Open a diff with
   no move — the toggle is not shown.
5. Click a few moved lines and **Stage lines**, or **Stage hunk**: staging is
   unchanged.

**Docs.** `docs/help/diffs.md` gets a row in the toggle table and a "Moved code"
section with the screenshot and the limits. No new modal, page or command, so
`scripts/docs-map.json` is unchanged. New strings (`diff.moved`,
`diff.movedTitle`, `diff.movedTo`, `diff.movedFrom`) are translated in all 16
locales with the same `{line}` placeholder.

**Review order.** This touches `DiffViewer.tsx`, as does the hunk and line actions PR. Each merges on its own; whichever lands second I'll rebase.

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
- [ ] `npm test` passes — the touched and related files pass (`movedLines`, `diff`, `i18n`, `pureLogic`, `playground.smoke`, `docs`: 907 tests); the full suite was not run
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command — n/a, no new surface
- [ ] `README.md` mentions it in one line, linked to its page — left to the maintainer
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` — not proposed
- [ ] Destructive actions confirm first; reversible ones offer an undo — n/a, read-only display
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/9fe196f89d302f49edf5820de3da0c6db4b3d049/moved-code-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/111b1ed5267dcb1a668a9b3d34ec501d005fb63e/docs/screenshots/moved-code.webp)

A function moved from the top of `utils.ts` to the bottom: both copies tinted
blue with arrows pointing at each other, while the one real edit
(`DEFAULT_TIMEOUT`) stays red/green with word marks. Before this change the same
diff showed the move as a red block and an unrelated green block.

---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
