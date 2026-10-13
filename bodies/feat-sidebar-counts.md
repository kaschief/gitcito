## Summary

**The problem.** Anyone with a GitHub, GitLab, Bitbucket or Azure DevOps remote and nothing open on
it sees *No open PRs loaded*, *No open issues loaded*, *No milestones loaded* and *No releases
loaded* in the sidebar. "Loaded" makes a perfectly normal state (a quiet repository, a fresh fork, a
project that does not use releases) read like something went wrong: as if the app tried to fetch
the list and gave up. It also suggests pressing Refresh will change the answer, which it will not.
The same wording carries into every locale ("…geladen", "…cargados", "読み込まれた…", and so on).

**What changes.**

- The four empty-list messages in the sidebar's hosting sections now state the fact plainly:

  | Section | Before | After |
  |---|---|---|
  | Pull Requests | No open PRs loaded | No open pull requests |
  | Issues | No open issues loaded | No open issues |
  | Milestones | No milestones loaded | No milestones |
  | Releases | No releases loaded | No releases |

- "PRs" is spelled out as "pull requests", matching the section title and the rest of the sidebar.
- All 16 locales are updated with a real translation of the new wording (ar, de, en, es, fr, he, it,
  ja, ko, nl, pl, pt-BR, ru, tr, uk, zh-CN). Only the values change; no key is added, removed or
  renamed, and none of these strings has a placeholder.
- `docs/help/hosting.md` says what the empty message means and what it does not.

**Benefits.** An empty list no longer looks like a failure, so nobody goes hunting for a token
problem that is not there. The copy matches the sidebar's other empty states, which already read
plainly ("No tags", "No stashes", "No linked worktrees").

**Limits.** This is a wording change only. The sidebar still cannot tell an empty list from one it
could not fetch: the background refresh is silent, so when it fails (offline, an expired token, a
GitLab remote without a token, a private repository the token cannot see) the list stays empty and
shows the same message. Pressing the section's Refresh button runs the same request non-silently
and shows the error as a toast; the handbook now says so. Surfacing background errors inline would
be a separate, larger change.

A note on the fork this comes from: there, section counts had been hidden until hover and this
change also brought them back for top-level sections. Gitcito already shows the counts all the
time, so that half does not apply and is not part of this PR.

**Tests.** `test/i18n.test.ts` (key parity, placeholders, duplicates across all locales) and
`test/pureLogic.test.ts` pass. No logic changed, so no new test. A `sidebar-counts` screenshot is
generated from `shots.config.mjs` and referenced from `docs/help/hosting.md`.

**How to test by hand.**

1. `npm run dev` and open a repository whose `origin` is on GitHub but has no open pull requests,
   issues or releases (any personal repository will do; no token is needed for a public one).
2. Expand Pull Requests, Issues, Milestones and Releases in the sidebar: each says *No open pull
   requests*, *No open issues*, *No milestones*, *No releases*.
3. Switch the language in Settings (e.g. to Deutsch or 日本語) and check the same four messages.
4. Disconnect from the network and press a section's Refresh button: an error toast appears, and
   the list still reads the same.

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

`npm test` was run for `test/i18n.test.ts` and `test/pureLogic.test.ts` (805 passing); the full
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

![Before](https://raw.githubusercontent.com/kaschief/gitcito/48c0e966f0dcad9b82acd6b50eb502db85d93b08/sidebar-counts-before.png)

**After**

![After](https://raw.githubusercontent.com/kaschief/gitcito/2532fc59e2d3ff32412e6e6f850d1a2bd559a1f3/docs/screenshots/sidebar-counts.webp)


---

This is offered as a suggestion. If it doesn't fit Gitcito's direction, feel free to close it; I'm happy to adjust, split or rework it.
