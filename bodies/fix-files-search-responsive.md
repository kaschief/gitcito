## Summary

**The problem.** Searching file contents from the Files tab (and the content mode of the commit panel's
file filter) froze the app on a large repository. `searchFileMatches` in `src/main/git.ts` read every
candidate file into the main process with one `Promise.all`, split it into lines and ran a JavaScript
regex over each, on every keystroke. The renderer threw away stale results, but the main process kept
running every superseded search to completion, so typing a word queued one full scan per letter. Since
the main process also serves IPC for every window, the whole app stalled: the graph, the other tabs,
other repositories. Anyone with a repository of a few thousand files or more hits it as soon as they type
in the search box.

There is a second, quieter bug: opening tens of thousands of files at once can run out of file
descriptors. On the benchmark repository below, 6,529 of 26,509 reads failed with `EMFILE`, and the old
code treats a failed read as "binary or unreadable", so those files were silently missing from the
results (242 matches reported for `useEffect`, against 263 that are really there).

**What changes.** The search moves to a new `src/main/fileSearch.ts`; `gitService.searchFileMatches`
keeps its signature and delegates to it.

- **Waits for a pause in typing.** The Files tab now sends a content search 200 ms after the last
  keystroke (the commit panel already did this).
- **A newer search stops the older one.** Callers pass an optional `searchId` (`'files'` and
  `'commit'`); a new search under the same repository and id cancels the previous one, killing its
  `git grep` process or stopping its file loop, and the superseded call resolves to `[]`.
- **Plain text runs in `git grep`.** Non-regex queries (with the case and whole-word toggles) use
  `git grep -F --untracked -I -z`, so the work happens in a child process off the event loop. Output is
  streamed and the child is killed once the 2,000-hit cap is reached. Pathspecs are passed with
  `--literal-pathspecs`; when the list would exceed 64 KB (argument-length limits) the whole tree is
  grepped and filtered to the requested files instead. `-m` (per-file cap) is used when git supports it
  (2.38+) and the per-file cap is also enforced while parsing, so older gits work too.
- **Regex keeps JavaScript semantics** so results agree with the in-view highlighting, but it reads
  eight files at a time, yields between files, and skips files over 4 MB.

**Benefits.** Typing stays smooth, results are complete on big repositories, and a plain-text search
is roughly 15 to 35 times faster.

**Measured** on a repository of 26,509 text files (235 MB, copied from this project's own
`node_modules`), Linux, 4 cores, git 2.43, calling the old and new implementations side by side from
vitest. "Stall" is the longest the Node event loop (that is, the main process) was blocked:

| Search | Before | After |
|---|---|---|
| `zq_nothing_here` (no match) | ~3,100 ms, stall ~770 ms | ~230 ms, stall ~14 ms |
| `function` (hits the 2,000 cap) | ~3,340 ms, stall ~850 ms | ~100 ms, stall ~15 ms |
| `useEffect` | ~3,060 ms, stall ~750 ms, **242 hits (incomplete)** | ~225 ms, stall ~10 ms, 263 hits |
| regex `use\w+Effect` | 3,151 ms, stall 799 ms, 236 hits (incomplete) | 4,922 ms, stall 41 ms, 257 hits |
| Typing `useEffect`, one key per 100 ms | 19,567 ms until the last result, stall 2,995 ms | 1,613 ms (debounced), stall 27 ms |

Without the renderer's debounce, sending every keystroke but letting each cancel the last, the typing
case still finishes in 1,770 ms with a 193 ms worst stall.

**Limits.**

- A regex search is a little slower end to end than before (it now reads eight files at a time instead
  of all at once), in exchange for never blocking the app; it also skips files over 4 MB.
- Plain-text search follows `git grep` rules: binary files are skipped (`-I`, as before via the NUL
  check) and case-insensitive matching of non-ASCII letters depends on git's build.
- Results are still capped at 2,000 lines (100 per file), as before.

**Tests.** Two git-backed tests in `test/newFeatures.test.ts` (on a `cloneFixture` copy): untracked
files and an unusual file name (`odd:name ü.txt`) are found by both the `git grep` and the regex path,
and a second search with the same `searchId` makes the first resolve to `[]` while the second returns
its hits. The existing `searchFileMatches` tests (case, whole word, regex, per-file cap, only the given
files) pass unchanged against the new implementation.

**How to test by hand.** Open a large repository (a checkout with a few thousand files or more; a
repository that commits its `node_modules` is ideal). In the left sidebar's **Files** tab, switch the
search to content and type a word quickly. Before: the app freezes while typing and for seconds after.
After: typing is smooth and results appear shortly after you stop. Try the regex toggle too, and check
that an untracked file containing the word shows up.

Handbook: a short paragraph in `docs/help/diffs.md` (Files tab) on how content search behaves and its
limits.

## Type of change

- [ ] `feat:` New feature
- [x] `fix:` Bug fix
- [ ] `docs:` Documentation
- [ ] `chore:` Maintenance / tooling
- [ ] `refactor:` Code change (no feature, no bug fix)
- [x] `perf:` Performance improvement
- [ ] `test:` Tests only

## Checklist

- [x] PR title follows `type(scope): description` format
- [x] `npm run typecheck` passes
- [x] `npm run lint:i18n` passes — every new string is in **every** locale file (no new strings)
- [x] `npm run lint:docs` passes — every new surface has a handbook page
- [ ] `npm test` passes — `test/newFeatures.test.ts`, `test/i18n.test.ts` and `test/pureLogic.test.ts`
  were run: all code search tests pass; six tree-sitter semantic diff tests in `newFeatures.test.ts`
  fail in my environment, identically on unmodified `main`
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (no new surface)
- [ ] `README.md` mentions it in one line, linked to its page (not a headline feature)
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` (no)
- [ ] Destructive actions confirm first; reversible ones offer an undo (nothing destructive)
- [ ] Screenshot entry added to `examples/screenshots/shots.config.mjs` (nothing visible changes)

### Show it

n/a — nothing visible changes; see the measurements in the summary.

---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
