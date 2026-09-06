$ErrorActionPreference = "Stop"

$plugins = @(
  "figma@openai-curated",
  "github@openai-curated",
  "product-design@openai-curated",
  "build-web-apps@openai-curated",
  "superpowers@openai-curated",
  "vercel@openai-curated",
  "codex-security@openai-curated"
)

Write-Host "Checking Codex CLI..."
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
  throw "Codex CLI was not found in PATH. Open this repository in Codex App and use Plugins in the sidebar, or make the Codex CLI available first."
}

Write-Host "Installing recommended Codex plugins for cherkizovo-design-service..."
foreach ($plugin in $plugins) {
  Write-Host "`nInstalling $plugin"
  codex plugin add $plugin
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to install $plugin"
  }
}

Write-Host "`nInstalled plugins:"
codex plugin list

Write-Host "`nDone. Start a NEW Codex thread for this repository so the new plugin skills are discovered."
Write-Host "If a plugin requires authentication, complete it in Codex App -> Plugins."
