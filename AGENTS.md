# Cherkizovo Design Service — Codex Instructions

## 1. Branch Safety

- `main` = immutable legacy/stable production version.
- NEVER develop directly on main or commit implementation changes to main.
- NEVER merge into main without explicit user instruction saying that the 2026 version is approved for final production replacement.
- NEVER force-push main, delete main, reset user changes, or rewrite user history.
- All 2026 development begins from the current `develop-2026`.
- Feature/fix/refactor/chore branches must be based on current `develop-2026` and merge back only into `develop-2026` through a PR.
- Keep GitHub default branch `main`. Do not confuse default branch with the development PR target.

Before changing code, check current branch, `git status`, `git diff`, staged diff, and branch base. Fetch origin and verify the merge base against `origin/develop-2026`. Do not continue on a stale or unexpected base without resolving the discrepancy safely.

If current branch is `main`, do not edit files. Create an appropriate branch from current `develop-2026`, checking first that switching cannot overwrite user files. Never use force checkout or stash user changes without authorization.

The user explicitly allows these local untracked objects: `0_documents.zip` and `0_documents/`. Preserve them in place: do not delete, move, rename, edit, overwrite, stage, commit, include in PRs, or add to tracked `.gitignore`. If other unexpected user changes appear, stop and report them. Stage only explicitly reviewed task files; never use blanket `git add .` or `git add -A`.

## 2. Development Workflow

For each substantial task:

1. Understand the request and inspect the existing implementation.
2. Identify reusable code; do not rewrite working code without a reason.
3. Write a short implementation plan.
4. Create a dedicated feature/fix/refactor/chore branch from current `develop-2026`.
5. Implement the scoped change.
6. Verify the result and perform self-review.
7. Show the diff or a precise diff summary, noting unexpected changes.
8. Only after verification prepare the commit and PR with explicit base `develop-2026`.

One substantial task = one branch. Prefer one Codex task/thread per substantial task. Never rely on GitHub's default PR base, because it remains `main`.

## 3. Existing Service Is the Foundation

This is not a greenfield project. Inspect existing code before implementing a replacement.

Priority: reuse > improve > refactor > replace.

Replace an existing mechanism only if incompatible with the new requirements, architecturally blocking the new version, or explicitly approved for replacement. Explain the evidence and tradeoff. Never remove working features merely because rewriting is easier. Preserve rendering, API contracts, Figma snapshots, storage paths, photobank, fonts, and existing capabilities unless the task explicitly covers their change.

## 4. Project Stack

Check the real `package.json` and affected code before changes. The baseline uses Next.js App Router, React, TypeScript, Node.js server code, sharp, API routes, the existing image rendering pipeline, and storage/integration logic. See `docs/BASELINE_2026.md` for observed dependency ranges and file paths.

Use pnpm; the repository contains `pnpm-lock.yaml`. Do not introduce another framework, state manager, CSS framework, database, or major dependency without necessity and a separate justification. Do not assume the Node runtime version from `@types/node`.

## 5. UI / Design Workflow

Use available applicable Figma, Product Design, Build Web Apps, Superpowers, and Computer Use/browser testing plugins or skills. Check actual availability; do not claim an unavailable tool was used.

For an approved design:

- Treat the design as the source of truth; do not freely redesign it.
- Do not invent missing elements or change interface structure without requirements.
- Reuse existing UI components and preserve a coherent design system.
- Use Tabler Icons as the primary library for new icons. Do not mix icon libraries without a specific reason; preserve useful existing assets.

After UI changes, run the app, open the affected screen, inspect it visually, test main states/interactions, check console errors, and compare with the source design using design QA when available. Report unavailable checks precisely.

## 6. Superpowers Workflow

For complex tasks, use applicable available Superpowers skills: `writing-plans`, `systematic-debugging`, `using-git-worktrees`, `requesting-code-review`, `verification-before-completion`, and `finishing-a-development-branch`. If unavailable, apply the corresponding planning, diagnosis, isolation, review, and verification practices and report the limitation when relevant. Do not claim completion before actual verification.

## 7. Debugging

Do not apply random fixes. Reproduce the failure, capture the error safely, identify root cause and affected layer, fix the cause, and verify the same scenario again. Do not hide errors behind unnecessary workarounds. Distinguish new regressions from existing baseline defects.

## 8. Verification

Before completion:

- Review `git diff`, staged diff, and unexpected files.
- For code changes run the production build (`pnpm build`).
- Run existing lint/tests when configured and operational. `pnpm lint` is declared; no test script is declared in the baseline. Do not silently treat an unusable script as a passed check.
- Verify the affected user scenario and console/server errors where applicable.
- For rendering, schema, storage, crop, generation, and download changes, cover success and failure paths.

For documentation-only work, verify contents, diff hygiene, branch ancestry, and GitHub target; build/browser checks are not required when runtime code is unchanged. If a relevant check fails or cannot run, state the exact reason and do not claim it passed. Separate baseline failures from changes introduced by the task.

## 9. Security

Never commit `.env.local`, API keys, access tokens, real credentials, or other secrets. Never publish them to GitHub or expose them in documentation/logs. Do not inspect or print secret values unnecessarily.

For upload, admin, auth, external API, storage, file processing, and server route changes, review security implications; use available Codex Security tooling when appropriate. Preserve authorization checks and assess input validation, file limits, URL handling, and data exposure for the affected path.

## 10. Vercel / Production Safety

`main` must remain production/stable. `develop-2026` and feature branches are for Preview/development only. Never switch production to a development branch or deploy the new version to production without a separate explicit user command. Desired configuration is not evidence of actual configuration: verify through read-only Vercel access and report unknowns. Do not alter production environment variables.

## 11. Destructive Operations

Without direct user authorization, never force push, run `reset --hard` on user changes, delete branches with unmerged changes, delete tags, rewrite history, delete production data, change production environment variables, or deploy the new version to production. Recheck Git state before potentially irreversible actions. Preserve existing branches, tags, PRs, and files. Use fast-forward-only updates for existing integration branches; never create a merge commit on main during preparation.

## 12. Final Response Requirements

After each task report the branch used, changed files, checks performed and their results, whether commits and PRs were created, PR target, and remaining work. Cite actual evidence; distinguish completed work, failed checks, unavailable tooling, and manual steps. Never report only “done”.
