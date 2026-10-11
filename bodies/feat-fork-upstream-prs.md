## Summary

**The problem.** Anyone who contributes through a fork (the usual GitHub flow for
an open-source project) opens their pull requests on the *parent* repository, not
on the fork. The sidebar's **Pull Requests** section only asks `origin`, which in
a fork checkout is the fork itself, so the section reads "No open PRs loaded"
while the user's actual pull requests wait on the parent. To see them, the user
has to leave the app for the browser.

**What changes.** When a repository has an `upstream` remote that points at a
*different* GitHub repository than `origin`, the PR refresh also asks `upstream`
for its open pull requests and keeps only those whose head repository
(GitHub's `head.repo.full_name`) is the fork. They appear in the same section,
below the fork's own, under a quiet caption **On owner/repo** (tooltip: "Your
open pull requests on the repository this fork comes from"). The rows are the
ordinary PR rows: CI glyph, preview, detail view, context menu. Click, preview
and the context menu are keyed to the `upstream` remote, so the detail view,
checks and review open against the parent. The section count includes them,
and the empty state only shows when both lists are empty.

How it is built:

- `src/main/hosting.ts`: the GitHub PR listing now also returns `headRepo`
  (from `head.repo.full_name`, which is already in the response; no extra request).
- `src/shared/types.ts`: `PullRequest.headRepo?: string`.
- `src/renderer/src/lib/hosting.ts`: two pure helpers. `forkUpstream(remotes)`
  returns the `upstream` remote plus the `owner/repo` slugs of fork and parent,
  or `null` for an ordinary clone, a non-GitHub upstream, or an upstream equal
  to origin (compared case-insensitively). `prsFromFork(prs, fork)` keeps the
  parent's PRs whose head repo is the fork.
- `src/renderer/src/stores/repo.ts`: a separate `upstreamPrs` slice on
  `RepoData`, filled by `refreshPRs` after origin's list. It is kept apart from
  `prs` on purpose: stacks, branch badges and every lookup that reads `prs` keep
  acting on origin alone, so nothing else changes behaviour.
- `src/renderer/src/components/Sidebar.tsx`: `prRow` and `prMenu` take an
  optional remote; the caption and the upstream rows render after the existing
  list. One CSS rule for the caption.
- i18n: `sidebar.upstreamPRs` (`On {repo}`) and `sidebar.upstreamPRsTitle`,
  translated in all 16 locales with the same placeholder.

**Benefits.** A fork contributor sees their own open work, with its CI state,
without leaving the app, and can open review/detail on the parent directly.
Ordinary clones see no difference at all: `forkUpstream` returns `null` and the
only cost is a cheap remote check.

**Limits.**

- GitHub only, and only a remote literally named `upstream` (the convention
  GitHub's own docs and `gh repo fork` use).
- The parent's other pull requests are deliberately left out: that is the
  parent's queue, not the user's work.
- Stacks and branch lookups still act on origin's list only; a stack opened on
  the parent is shown as plain rows.
- One more GitHub request per PR refresh in a fork checkout (plus the existing
  per-PR checks lookup for the rows it returns). An error on that request is
  toasted like origin's, and stays silent on background refreshes.

**Tests.** `test/pureLogic.test.ts` gains a `fork upstream pull requests` block:
`forkUpstream` finds the parent across HTTPS and SSH URLs, and returns `null`
for no upstream, an upstream equal to origin in different case, and a non-GitHub
upstream; `prsFromFork` keeps only PRs headed in the fork, case-insensitively,
and drops PRs with no head repo. `test/i18n.test.ts` covers the new keys across
every locale.

**How to test by hand.**

1. Clone your fork of any GitHub project that has an open PR from you on the
   parent: `git clone https://github.com/<you>/<project>.git`.
2. `git remote add upstream https://github.com/<parent-owner>/<project>.git`.
3. Open it in Gitcito with a GitHub token set (public repos also work without one,
   within the anonymous rate limit), expand **Pull Requests** and refresh.
4. Your PRs on the parent appear under **On parent-owner/project**; other
   people's PRs on the parent do not. Click one: the detail view opens on the
   parent. Right-click: Preview and the links target the parent.
5. Remove the `upstream` remote (or point it at the same repo as origin) and
   refresh: the caption and rows disappear.

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
- [ ] `npm test` passes (ran `test/pureLogic.test.ts` and `test/i18n.test.ts`: 797 passed; full suite not run)
- [x] Tested locally

### If this changes something a user can see

- [x] `docs/help/` page written or updated (`hosting.md`, new section "Your pull requests on the parent of a fork")
- [x] `scripts/docs-map.json` maps the new modal / page tab / right panel tab / command (n/a: no new modal, tab or command)
- [ ] `README.md` mentions it in one line, linked to its page
- [ ] Front-page feature? Add it to `FEATURES` in `scripts/build-site.mjs`
- [x] Destructive actions confirm first; reversible ones offer an undo (n/a: read-only)
- [x] Screenshot entry added to `examples/screenshots/shots.config.mjs` (`fork-upstream-prs`)

### Show it

![Pull Requests in a fork, with the parent's PRs under On owner/repo](https://raw.githubusercontent.com/kaschief/gitcito/6dfcaaab562dd01a650f9c0feb99564585fd2241/docs/screenshots/fork-upstream-prs.webp)
