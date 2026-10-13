## Summary

**The problem.** Anyone who keeps more than a handful of repositories open hits this. Right-clicking a repository tab gives the repository menu, which ends in a red **Remove…**. On a tab, Remove only closes the tab (nothing is removed from disk), but the red label and the word make it read like a destructive action, and it is the only close-like row there. And once the strip has grown to eight, ten, a dozen tabs, the only way back to a tidy strip is clicking **×** on each one. There is no "close the others", which most tabbed apps (browsers, editors) offer on a tab's context menu.

**What changes.** On a standalone repository tab, the menu's last section is now:

| Row | What it does |
|-----|--------------|
| **Close this repo** | Replaces Remove. Exactly the tab's **×**: same uncommitted-work / merge-conflict warning, same behaviour. |
| **Close others** | Closes every other tab in the strip (repository tabs, groups and page tabs) and makes this one active. Disabled, with a tooltip saying why, when no other tab is open. |

Close others respects the existing **Warn when closing** setting, asking once for the whole batch rather than once per tab:

- *Always*: one confirm, "Close the {count} other tabs? Nothing on disk is affected."
- *When changes*: asks only if one of the other tabs holds uncommitted changes or merge conflicts, and names which kind. The confirm button is then not autofocused, matching the single-tab dirty prompt.
- *Never*: closes straight away.
- With exactly one other tab, that tab's ordinary close prompt is used, so it names the repository or group.
- If the other tabs are only page tabs, there is nothing to lose and it just closes them.

Nothing leaves the disk. **⌘⇧T / Ctrl+Shift+T** reopens the closed tabs one press at a time, each back at its old index. The reopen stack normally holds ten, so it stretches to hold the whole batch and closing fifteen tabs does not lose the oldest five.

**Benefits.** The tab menu uses the strip's own vocabulary (close, not remove), a crowded strip can be cleared in one step, and the existing safety net (warn-on-close, ⌘⇧T) covers the new bulk action too.

**Limits.**
- Only the tab menu changes. A chip inside a group, the toolbar repository dropdown and the other repository lists still offer **Remove…**, because there it really does remove an entry from a list or group.
- Close others closes page tabs and groups too, as "others" does in a browser. Pinned or protected tabs don't exist in Gitcito, so there is nothing to skip.
- There is no single "undo the whole batch" action. ⌘⇧T restores the tabs one press at a time.

**Implementation.**
- `lib/repositoryMenu.ts`: `repoMenuEntries(caps, removable = true)` can leave out Remove and its separator. Other callers are unchanged.
- `lib/repositoryMenuItems.ts`: `repositoryMenuItems` accepts a `null` `onRemove` to drop Remove. The new `requestCloseOtherTabs(tabId)` applies the warn-on-close rules and opens the confirm.
- `lib/tabClose.ts`: the new pure `closeOthersPrompt(others, status, warnOnClose)` decides whether a prompt is needed and which one.
- `stores/settings.ts`: the new `closeOtherTabs(keepTabId)` pushes the closed tabs right to left (as `closeAllRepoTabs` does), so ⌘⇧T restores strip order, and grows the reopen stack to fit the batch.
- `components/TitleBar.tsx`: builds the two rows for a repository tab.
- Six new `titlebar.*` keys, translated in all 16 locales with identical placeholders.

**Tests.**
- `test/pureLogic.test.ts`: `closeOthersPrompt` across always / wip / never / undefined, dirty versus conflict, and page-only batches.
- `test/repositoryMenu.test.ts`: Remove and its separator are left out when asked.
- `test/closeOtherTabs.test.ts` (new): the store keeps only the chosen tab and activates it, ⌘⇧T restores the others in their original order, a 13-tab batch survives the ten-deep stack, and nothing happens for an unknown or lone tab.

**How to test by hand.**
1. Open three or more repositories as tabs, and add a page tab such as Settings or Repositories.
2. Right-click a repository tab. The menu ends in **Close this repo** and **Close others**, and Remove is gone.
3. **Close this repo** behaves like the tab's ×. Dirty a repo first to see its warning.
4. With **Warn when closing** set to *Always*, choose **Close others** and confirm the single prompt. Only the right-clicked tab remains, and it is active.
5. Press ⌘⇧T / Ctrl+Shift+T repeatedly. Each tab returns to its old position.
6. Set **Warn when closing** to *When changes*. With all the other repos clean, Close others closes without asking. With uncommitted changes in one of them, it asks and names uncommitted changes.
7. With a single tab open, **Close others** is disabled and its tooltip says no other tabs are open.
8. Right-click a chip inside a group. It still shows **Remove…**.

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
- [ ] `npm test` passes (full suite not run; these pass: `test/closeOtherTabs.test.ts`, `test/repositoryMenu.test.ts`, `test/pureLogic.test.ts`, `test/i18n.test.ts`)
- [ ] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated (`repo-menu.md` gains the two rows and a "Closing the other tabs" section; `workspaces.md` updated)
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (n/a: no new modal, page tab or command)
- [ ] `README.md` mentions it in one line, linked to its page (n/a: small menu change)
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs` (n/a)
- [x] Destructive actions confirm first; reversible ones offer an undo (follows Warn when closing; ⌘⇧T reopens)
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs` (`repo-tab-close-others`)

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/f3fbaccc34e7f73bf537a1b83957277861f21fd6/repo-tab-close-others-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/0dd54a17af24ad77048cf57b2adab936b50a9078/docs/screenshots/repo-tab-close-others.webp)


---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
