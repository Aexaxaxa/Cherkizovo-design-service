# Codex plugins for this project

Recommended plugin set for `cherkizovo-design-service`:

- `figma@openai-curated`
- `github@openai-curated`
- `product-design@openai-curated`
- `build-web-apps@openai-curated`
- `superpowers@openai-curated`
- `vercel@openai-curated`
- `codex-security@openai-curated`

These plugins are installed into the local Codex environment, not into `node_modules`. The repository contains this list and project instructions so the same setup can be reproduced on another machine.

## Windows / Codex App

### Option A — Codex App UI

Open **Plugins** in the Codex sidebar and install:

1. Figma
2. GitHub
3. Product Design
4. Build Web Apps
5. Superpowers
6. Vercel
7. Codex Security

Complete authentication where requested.

Start a **new Codex thread** after installing plugins so newly installed skills and tools are discovered.

### Option B — project setup script

From the repository root in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-codex-plugins.ps1
```

The script uses the official Codex plugin CLI form:

```text
codex plugin add <plugin>@<marketplace>
```

and installs the plugins from the `openai-curated` marketplace.

After installation, start a new Codex thread for this repository.

## What each plugin is for

### Figma

Use when implementing approved Figma screens, connecting design components to code, or deriving design-system rules.

Key workflows:
- faithful Figma-to-code implementation;
- Code Connect/component mapping;
- design-system rule generation.

### Product Design

Use when the source of truth is a screenshot/mockup or when visual QA is needed.

Key workflows:
- image/screenshot to code;
- design QA against a rendered implementation;
- explicit UX/accessibility audits.

### Build Web Apps

Use for normal frontend implementation and rendered frontend debugging.

Key workflows:
- frontend app building;
- React best practices;
- UI regression and interaction debugging.

### Superpowers

Use for disciplined engineering workflows rather than one-shot edits.

Key workflows:
- implementation planning;
- isolated Git worktrees;
- systematic debugging;
- verification before completion;
- code review;
- finishing a development branch.

### GitHub

Use for repository operations, pull requests, CI checks, review comments, branches, and code-review workflows.

### Vercel

Use for preview/production deployments and deployment diagnostics.

### Codex Security

Use for security-sensitive changes and explicit security reviews, especially around uploads, secrets, admin routes, external APIs, storage, and server-side file processing.

## Project binding

`AGENTS.md` in the repository root provides project-specific instructions for how Codex should use these plugins and skills while working on this codebase.

Plugin installation is user/Codex-environment level. `AGENTS.md` is repository level. Together they provide the intended setup:

```text
Codex plugins + skills
        +
repository AGENTS.md
        +
Git branch/worktree workflow
        =
project-specific Codex development environment
```
