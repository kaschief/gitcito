## Summary

**The problem.** The Repository and Branch pickers at the left of the toolbar
draw their dropdown chevron on top of the value when the name is long. With a
repository called `indicators-by-kash` on branch `indicators-home`, the chevron
covers the last letters of both. You do not need an unusual setup to hit it:
the left side of the toolbar is capped at 320px, so two moderately long names
(around 15 characters each, or a `feature/...` branch) at a normal window width
are enough.

**Why it happens.** In `styles.css`, `.repo-pill-stack strong` is
`display: flex` with `max-width: 130px`, `overflow: hidden` and
`text-overflow: ellipsis`. Ellipsis never applies there, because the bare text
becomes an anonymous flex item. `.repo-pill-stack` is a flex column with
`align-items: flex-start` and `min-width: 0`, but it does not clip. Once the
toolbar reaches its cap, the button shrinks and the stack ends up narrower than
the name (about 92px against 110px in one measured case). `strong` keeps its
max-content width and spills out of the stack, and the `ChevronDown` that
follows in the button is drawn over it.

**What changes.** This is a CSS-only fix in `src/renderer/src/styles.css`. The
two-line label/value design stays as it is.
- `.repo-pill-stack` takes the 130px cap (moved from `strong`) and
  `overflow: hidden`.
- `.repo-pill-stack strong` becomes `display: block` with `max-width: 100%`, so
  it is never wider than the stack and its ellipsis works.
- `.repo-pill-stack strong svg { vertical-align: -2px }` keeps the branch icon
  centred on the text now that it sits inline. The space already in the JSX
  provides the gap that `gap: 4px` used to give.

**Benefits.** The chevron always sits after the text. A long name ends in "…"
before the chevron instead of being cut off underneath it, so both pickers
still read as buttons that open a list. Short names look exactly as before.

**Limits.** Long names are now visibly truncated, and the full name is not
shown in a tooltip on the pill (the pill's `title` is still "Switch
repository" / "Switch branch"). To read a full name, open the picker. The 320px
cap on the toolbar's left side is unchanged, so how much of a name shows still
depends on the window width.

**Tests.** No logic changed, so there is no unit test to add. The new
`toolbar-picker-chevron` shot in `examples/screenshots/shots.config.mjs`
captures the state: the `pr-ready-branch` playground repo on
`feat/awesome-feature`, cropped to `.toolbar-left`. It is referenced from
`docs/help/branching.md`, so the orphan-screenshot check in `test/docs.test.ts`
covers it. Before the fix, that same shot showed the chevron over
"pr-ready-branch" and over "feat/awesome-feature".

**How to test by hand.**
1. `npm run dev` and open a repository with a long folder name, for example
   `examples/playground/pr-ready-branch` or any repo renamed to something like
   `indicators-by-kash`.
2. Check out a long branch, such as `feat/awesome-feature`.
3. Narrow the window, or open the side panels, until the names no longer fit.
   Each value should end in "…" with the chevron clear to its right. Before
   this change, the chevron overlapped the last letters.
4. Switch to a short repository and branch (e.g. `main`). They should look
   unchanged, with the branch icon aligned to the text.

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
- [x] Tested locally

`npm test` was not run as a whole. `test/docs.test.ts`, `test/i18n.test.ts` and
`test/pureLogic.test.ts` were run and pass (806 tests). `npm run build` passes.

### If this changes something a user can see

- [x] `docs/help/` page written or updated
- [ ] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command
- [ ] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs`
- [ ] Destructive actions confirm first; reversible ones offer an undo
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs`

The docs map, README, front page and confirm items do not apply: there is no new
surface, command or action.

### Show it

**Before**: the chevron sits on top of the repository and branch names.

![Before: chevrons covering the end of long names](https://raw.githubusercontent.com/kaschief/gitcito/8003e3748a7bedf6ef1ef06629be4bf2631b9467/toolbar-picker-chevron-before.png)

**After**: long names end in an ellipsis and the chevron stays clear.

![Toolbar pickers with long names ending in an ellipsis before the chevron](https://raw.githubusercontent.com/kaschief/gitcito/00a69e9f77181ad96bb76390bbfd35dddf31c8dd/docs/screenshots/toolbar-picker-chevron.webp)
