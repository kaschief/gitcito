## Summary

**The problem.** Anyone who keeps many repositories open in one workspace (ten,
fifteen, a couple of groups) has no quick way to get to a particular one. The
tab strip has to be scrolled, <kbd>⌘1</kbd>–<kbd>⌘9</kbd> stop at the ninth tab
(and on a group tab select the group, not a member), and the command palette
lists open repositories alongside every branch, commit, file and action. The
most common move, going back to the repository you were in a moment ago, takes
a hunt every time.

**What changes.** <kbd>⌘J</kbd> / <kbd>Ctrl+J</kbd> opens a small switcher that
hangs under the tab bar:

- It lists **only open repositories**, group members included, **most recently
  used first**. The one you just left is the first row, so <kbd>⌘J</kbd>
  <kbd>Enter</kbd> goes straight back to it.
- Each row shows what its tab shows: the **current branch**, the tab's
  **uncommitted-work / conflict dot** (the same `tab-status` dot and tooltip
  the tab strip uses), the **group** it lives in, and its
  <kbd>⌘1</kbd>–<kbd>⌘9</kbd> key when it has one.
- **Typing filters** by name, folder path or branch, with fuzzy matching. Hits
  on the name rank above hits that needed the path or branch, and the matched
  letters are highlighted.
- The repository already on screen sits dimmed at the bottom under "Showing
  now", so the list never looks as if one is missing.
- The last row, **Browse all repositories** / **Find "…" in all
  repositories**, opens the existing Repositories page with the search
  already typed in, for when the repository is not open at all.
- <kbd>↑</kbd> <kbd>↓</kbd> to move, <kbd>Enter</kbd> to switch,
  <kbd>Esc</kbd> or a click outside to close. There is no backdrop: it is a
  light sheet, not a modal. A press outside only dismisses; it does not also
  click whatever is underneath.
- It is **rebindable** in Settings → Shortcuts (a new `repo-switcher` entry in
  the shortcut registry, default `mod+j`), and is also in **View → Go to
  repository…** and the command palette ("Go to repository…").

I checked that <kbd>⌘J</kbd> / <kbd>Ctrl+J</kbd> is not bound anywhere in the
app (renderer shortcuts, menu accelerators or main process) before taking it.

**Benefits.** Getting to any open repository is three keystrokes regardless of
how many tabs are open or where it sits, group members are reachable directly,
and the back-and-forth between two repositories is <kbd>⌘J</kbd>
<kbd>Enter</kbd>.

**Limits.**

- The recency order lives for the session only (a list in the UI store, capped
  at 50). After a relaunch it starts from tab order.
- A repository open in two tabs is listed once, at its first tab.
- Only the current workspace's tabs are listed; repositories in other
  workspaces are reached through the Repositories page row.
- Hints show <kbd>⌘N</kbd> only for single-repository tabs within the first
  nine, because on a group tab that key selects the group, not the member.

**Implementation notes.**

- `lib/repoSwitcher.ts` (pure): `switcherEntries` builds the ordered list from
  the tabs, active tab and recency list; `filterSwitcher` narrows and ranks it;
  `touchMru` maintains the recency list.
- `lib/fuzzy.ts`: the command palette's existing fuzzy scorer moved out of
  `CommandPalette.tsx` unchanged, plus a `fuzzyMatch` variant that also
  returns matched positions for highlighting. The palette now imports it.
- `stores/ui.ts`: `repoSwitcherOpen`, `repoMru`, and `repositoriesQuery` (a
  one-shot hand-off the Repositories page consumes).
- `App.tsx` touches the recency list whenever the active repository changes
  and mounts `<RepoSwitcher />` next to the palette. `appCommands.ts` toggles
  it (and closes the palette; opening the palette closes the switcher).
- 12 new keys, translated in all 16 locale files, sentence case to match the
  surrounding `sc.*` / `cmd.*` copy, same placeholders everywhere.
- Handbook: new "Going to a repository" section in `docs/help/workspaces.md`
  with the screenshot, a row in `docs/help/keyboard.md`, the command mapped in
  `scripts/docs-map.json`, one README line, and a `repo-switcher` entry in
  `examples/screenshots/shots.config.mjs`.

**Tests.**

- `test/repoSwitcher.test.ts` (new): recency first then tab order with the
  current repository last; group naming and when the <kbd>⌘N</kbd> hint
  applies; only the shown member of a group counts as current; filtering by
  name, then path or branch, dropping the current repository, with highlight
  positions; `touchMru` moves to the front and keeps identity when unchanged.
- `test/pureLogic.test.ts`: `matchShortcut` resolves <kbd>⌘J</kbd> and
  <kbd>Ctrl+J</kbd> to `repo-switcher` with default bindings.

Ran: `npm run typecheck`, `npm run lint:i18n`, `npm run lint:docs`,
`npx vitest run test/repoSwitcher.test.ts test/i18n.test.ts test/pureLogic.test.ts`
(800 passed), and `npm run build`, all green. The full `npm test` suite was not
run.

**How to test by hand.**

1. `npm run dev`, then open six or more repositories as tabs, and put two or
   three into a group.
2. Click through a few tabs, then press <kbd>⌘J</kbd> / <kbd>Ctrl+J</kbd>. The
   repository you came from is the first row; <kbd>Enter</kbd> takes you back.
3. Press <kbd>⌘J</kbd> again and type part of a group member's name. Enter
   switches to the group tab with that member selected.
4. Type part of a branch name that only one repository has checked out; it is
   found. Make a repository dirty and check its row shows the tab's dot.
5. Type something no open repository matches, then pick **Find "…" in all
   repositories**. The Repositories page opens with that search filled in.
6. Click outside the switcher: it closes and nothing underneath is clicked.
7. Rebind it in Settings → Shortcuts and check View → Go to repository… shows
   the new key. Open it from the command palette too.

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
- [ ] `npm test` passes (the touched test files plus `i18n` and `pureLogic` pass; the full suite was not run)
- [x] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [x] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command
- [x] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` (not a front-page feature)
- [x] Destructive actions confirm first; reversible ones offer an undo (nothing destructive: it only switches tabs)
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

### Show it

![The repository switcher, most recently used first](https://raw.githubusercontent.com/kaschief/gitcito/08e6e5ddc822bc7cb0990752e14ec6f3a7e58fb5/docs/screenshots/repo-switcher.webp)
