# Codex instructions for Cherkizovo Design Service

## Project baseline

This repository is a production-oriented Next.js 15 / React 19 / TypeScript application. It combines frontend pages, API routes, Figma-derived template data, image generation with `sharp`, image cropping, a photobank integration, and administrative tooling.

Before changing code, read `README.md`, `package.json`, and the files directly involved in the requested feature. Do not infer a new architecture when the repository already contains an implementation.

Use `pnpm` for project commands.

Core verification commands:

```bash
pnpm build
pnpm lint
```

Use `pnpm dev` when browser/UI verification is required.

## Preferred Codex plugins and skills

When available, use the following installed plugins/skills instead of improvising equivalent workflows.

### Figma

Use Figma skills when a task is based on an approved Figma design or design-system source.

Preferred skills include:
- `figma-implement-design` for implementing an approved Figma screen faithfully.
- `figma-create-design-system-rules` for deriving durable design-system rules.
- `figma-code-connect` / Code Connect workflows when mapping Figma components to existing code components.

Do not redesign an approved screen unless the user explicitly asks for redesign exploration.

### Product Design

Use Product Design for visual implementation and visual QA.

Preferred skills include:
- `image-to-code` when the source of truth is an approved screenshot/mockup.
- `design-qa` after implementation when both a source visual and rendered implementation exist.
- `audit` for requested UX/accessibility/design audits.

For approved screenshots, preserve the source composition rather than inventing a new concept.

### Build Web Apps

Use Build Web Apps skills for normal frontend implementation and debugging.

Preferred skills include:
- `frontend-app-builder` for frontend work.
- `frontend-testing-debugging` for rendered UI bugs, console errors, responsive problems, interaction bugs, and visual regressions.
- `react-best-practices` for React/Next.js implementation quality.

### Superpowers

Use Superpowers for non-trivial engineering work. Prefer its structured workflow over immediately editing files.

Relevant skills include:
- `writing-plans`
- `using-git-worktrees`
- `systematic-debugging`
- `verification-before-completion`
- `requesting-code-review`
- `finishing-a-development-branch`

For bug fixes, establish the root cause before applying a workaround.

### GitHub

Use GitHub integration for branches, pull requests, review comments, CI status, and review workflows.

Do not commit directly to `main` for substantive features or risky fixes. Work on a dedicated branch/worktree and review the diff before merge.

### Vercel

Use the Vercel plugin only for deployment-related tasks, preview deployments, deployment diagnostics, and production checks.

### Codex Security

Use security skills for explicit security reviews and before changes that materially affect authentication, secrets, uploads, server-side file processing, external API access, or admin functionality.

## UI implementation rules

The service uses a single coherent visual system. Reuse existing layout primitives and components before creating new equivalents.

When implementing from an approved visual reference:
1. Treat the approved reference as the visual source of truth.
2. Reuse existing components and styles when they can reproduce the reference faithfully.
3. Preserve existing navigation and shared layout behavior unless the task explicitly changes them.
4. Match spacing, dimensions, typography, states, borders, radii, and alignment rather than approximating them.
5. Verify the rendered result in a browser after implementation.
6. When possible, compare the rendered screen against the source with Product Design/Figma visual QA workflows.

Use Tabler Icons consistently for new interface icons unless the task explicitly requires an existing project asset or another source.

## Change safety

- Do not expose `.env.local`, API tokens, secrets, signed URLs, or credentials in commits or logs.
- Do not replace existing storage, Figma, photobank, or rendering architecture unless the requested task explicitly calls for that migration.
- Avoid unrelated refactors during focused feature work.
- Preserve API contracts unless changing them is part of the task.
- Treat image generation and template rendering as regression-sensitive code.
- For changes to rendering, generation, template schema, crop logic, storage, or downloads, verify both success and failure paths.

## Completion standard

Before claiming a development task is complete:
1. Review the final diff for unrelated changes.
2. Run the relevant verification commands.
3. For UI work, inspect the rendered result and interactions.
4. For bug fixes, reproduce the original failure when possible and verify it no longer occurs.
5. Report any verification that could not be executed instead of assuming it passed.
