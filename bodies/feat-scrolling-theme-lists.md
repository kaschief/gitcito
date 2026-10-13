## Summary

**The problem.** Settings → Themes lays out every app theme, every code theme and every graph palette
as a full grid. Anyone who adds a few custom or AI-generated themes sees each grid grow row by row,
and the controls below it (the code theme's font size and live preview, the rest of the page) get
pushed further and further down. With a handful of custom themes, comparing an app theme with a code
theme means scrolling back and forth past dozens of cards.

**What changes.**

- The App Theme list, the Code Theme list and the graph palette list each scroll inside their own
  box, showing two rows and a peek of the third.
- While there is more below, the peeking row fades out, so the box reads as "scroll for more". The
  fade lifts once the list is scrolled to its end, and a list short enough to fit shows in full with
  no fade.
- Each list opens scrolled to the current choice, centred, so the selected card is always in view
  without moving the page around it (`scrollTop` is set on the box, not `scrollIntoView`).
- The fade follows the content: adding or deleting a custom theme re-measures the box.

**Benefits.** The Themes page stays the same short height however many themes someone has, the two
theme lists can be seen together, and the live code preview stays close to the list it previews.

**Limits.** The box height is fixed (two rows and a peek); it does not grow with a tall window. The
wheel scrolls the box while the pointer is over it, and `overscroll-behavior: contain` keeps it from
scrolling the page at the ends, so moving past a list means moving the pointer off it. No new strings,
so no locale changes.

**How it is built.** A small hook, `components/useScrollList.ts`, sets the opening scroll position and
toggles a `data-more-below` attribute (via scroll, `ResizeObserver` and `MutationObserver`); a
`.settings-scroll-list` class in `styles.css` gives the box its height and the fade mask. The
arithmetic (whether content remains below, with 1px slack for fractional HiDPI scroll offsets, and
the centred scroll position) lives in `lib/scrollList.ts`.

**Tests.** `test/pureLogic.test.ts` covers `hasMoreBelow` (fades only while content remains, ignores
a sub-pixel remainder, no fade when the list fits) and `centeredScrollTop` (centres the chosen card,
never scrolls above the top). `docs/help/themes.md` describes the behaviour, with a new
`settings-theme-lists` screenshot generated from `shots.config.mjs`.

**How to test by hand.**

1. `npm run dev`, open Settings → Themes.
2. The App Theme and Code Theme lists show two rows and a faded third; scroll inside one and the fade
   lifts at the bottom.
3. Pick a theme in the third row, close and reopen Settings: the list opens with that theme centred.
4. Add a custom theme with **+**: the list grows inside its box and the page height stays the same.
5. Switch to the Graph tab: the palette list behaves the same way.

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
- [ ] `npm test` passes
- [ ] Tested locally

`npm test` was run for `test/pureLogic.test.ts` and `test/i18n.test.ts` (807 passing); the full
suite was not run. `npm run build` succeeds.

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command
- [ ] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs`
- [ ] Destructive actions confirm first; reversible ones offer an undo
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

No new modal, tab or command, so `docs-map.json` is unchanged; nothing destructive or undoable.

### Show it

**Before**

![Before](https://raw.githubusercontent.com/kaschief/gitcito/10aeda9efb3b32c6b4b19e841a158aa2ac640564/settings-theme-lists-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/67fe9e6543dc35e4027761707e771add06b926c0/docs/screenshots/settings-theme-lists.webp)

---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
