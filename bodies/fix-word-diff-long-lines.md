## Summary

**The problem.** Opening the diff of a file that has one very long line, such
as minified HTML, a bundled `.js`, a one-line JSON fixture or a generated
lockfile, can take the whole app down. Anyone who commits build output or
vendored minified assets hits it the moment they select that file in the
working tree or in a commit. With word diff on (the default), the Diff View
shows a spinner that never resolves while the renderer tries to allocate the
table; with large enough lines it runs out of memory and the window goes black.
The only way out is to restart the app, and it happens again on the next click
on that file.

**Why it happens.** `wordDiff` in `src/renderer/src/lib/diff.ts` runs an LCS
over the tokens of each edited line pair and allocates the whole
`(n + 1) × (m + 1)` table as nested `number[]` arrays. A minified line of
~100,000 characters is tens of thousands of tokens, so two such lines ask for
hundreds of millions to over a billion cells, even when only one word changed.
On the new `huge-line` playground repo (a ~118,000-character page with
`Spring` changed to `Summer`), current `main` never finishes rendering the diff.

**What changes.**
- `wordDiff` first walks the shared prefix and shared suffix token by token.
  Only the differing middle goes to the LCS, so a small edit inside a huge
  line becomes a tiny table.
- If the middle is still larger than `WORD_DIFF_CELL_BUDGET` (1,000,000 cells),
  it is marked as one changed block on each side instead of being compared
  token by token.
- The LCS table that remains is a flat `Uint32Array`, not an array of arrays:
  far less memory and allocation per cell.
- `markRanges` in `DiffViewer.tsx` used `ranges.some(...)` for every character,
  which is quadratic on a long line. It now walks the sorted ranges with a
  cursor, so marking a huge line is linear too.
- The return shape of `wordDiff` is unchanged; callers are untouched.

**Benefits.** The diff of a huge-line file opens at once, and a one-word edit
inside it is still marked exactly. Ordinary lines get the same marks as before:
the prefix/suffix trimming finds the same LCS on the middle, and the existing
`wordDiff` tests pass unchanged.

**Limits.** When one huge line changes in places far apart, everything between
the first and the last change is marked as a single block rather than word by
word. The budget only applies to the differing middle, so this needs both a
huge line and edits spread across it. The line itself is still rendered in
full; this PR does not truncate or virtualise very long lines, it only stops
word marking from exhausting memory.

**Tests.**
- `test/diff.test.ts`: a pure insertion and a pure deletion (prefix and suffix
  meet), a single edit inside a 6,000-element minified line (marks exactly
  `old` / `new`), and two edits far apart in that line (one block per side,
  spanning both edits).
- New playground scenario `examples/scenarios/68-huge-line.sh` (`huge-line`),
  added to `EXPECTED` in `test/playground.smoke.test.ts`.
- New shot `huge-line-diff` in `examples/screenshots/shots.config.mjs`,
  referenced from `docs/help/diffs.md`, which also gains a paragraph on the
  behaviour and its limit.

Gate run in the branch: `npm run typecheck`, `npm run lint:i18n`,
`npm run lint:docs` and `npm run build` pass. `test/diff.test.ts`,
`test/i18n.test.ts`, `test/pureLogic.test.ts`, `test/docs.test.ts` and
`test/playground.smoke.test.ts` pass (903 tests). The full `npm test` was not
run.

**How to test by hand.**
1. `npm run playground` (or let the tests generate it) so
   `examples/playground/huge-line` exists, then `npm run dev`.
2. Open `huge-line` and select `index.min.html` (unstaged).
3. The Diff View opens straight away with two rows, and word diff marks only
   `Spring` → `Summer` in the `<title>`. On `main` the same click leaves a
   spinner that never resolves (the before shot).
4. Optional: edit the file so it differs near the start and near the end of
   the line. The whole span between the two edits is marked as one block.
5. Open any ordinary diff and check that word marks look as before.

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
- [x] `npm run lint:i18n` passes — every new string is in **every** locale file
- [x] `npm run lint:docs` passes — every new surface has a handbook page
- [ ] `npm test` passes
- [ ] Tested locally

`npm test` was not run as a whole; the test files listed above were run and
pass. No new UI strings are added.

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command
- [ ] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs`
- [ ] Destructive actions confirm first; reversible ones offer an undo
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

The docs map, README, front page and confirm items do not apply: there is no
new surface, command or action.

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/3afa8305fa84adc0c01cb7f5e22b269b727ac5e0/huge-line-diff-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/1c449e19ae61570032b1cb77497fc0a6bd95014f/docs/screenshots/huge-line-diff.webp)


---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
