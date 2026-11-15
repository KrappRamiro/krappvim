# Handoff (2026-11-15)

Delete this file once the work below is finished. Do not commit it.

## Goal

Migrate krappvim to a setup where Claude manages the code: fix what the review
found, and add tooling so later sessions produce stable, verified changes.

## State

Committed and pushed to `main` (850e345..da0f6f8, four commits). `nix flake check`
passed right before the commit. Not yet deployed: `~/nixos-config` still pins the
old krappvim commit.

Done and verified:

- `lua/lze_specs/completion.lua`: replaced the binary +100 boost with a graded
  bonus from rust-analyzer's `sortText` (clamped -20..+40). Added
  `should_show_items` to hide snippets after a trigger character.
  Measured with the probe on the rebuilt kvim: `Ok`/`Err` still first in match
  arms; `mo` and `per` now prefer in-scope items over unimported ones.
- `lua/lze_specs/lint.lua`, `lsp.lua`: removed duplicate shellcheck (bashls
  already runs it). `:Format` now goes through conform.
- `lua/lze_specs/conform.lua`: `on_require = "conform"` so `:Format` can load it.
- `flake.nix`: added `checks` (lint + smoke) and `formatter`. Fixed a
  pre-existing break: `wrappers.lib.mkInstallModule` no longer exists upstream,
  renamed to `getInstallModule` (the `nixosModules`/`homeModules` outputs failed
  to evaluate before).
- `scripts/smoke.lua`, `scripts/probe-completion.lua`: new.
- `.github/workflows/check.yml`: runs `nix flake check` on push and PR.
- selene now passes with 0 warnings (unused `plugin` params renamed to `_`,
  `global_usage` allowed in `selene.toml`).
- `CLAUDE.md`: rewritten (Claude does the edits, required checks, conventions).

## Next steps

1. Check the first GitHub Actions run of `check.yml` (`gh run list`). Then
   `nix flake update krappvim` in `~/nixos-config` and ask the user to deploy.
2. Not verified: the snippet filter after `.`. The probe opens the menu with
   `show()`, which counts as a manual trigger, so snippets still appear in its
   output (`moisture_sensor.re` shows `repr`). Needs a check by really typing
   `.` in kvim, or by making the probe type with `nvim_feedkeys`.
3. `display.in` still ranks `into()` above `init()` (94 vs 86, was 168 vs 70).
   rust-analyzer itself prefers `into`. Decide whether to lower the multiplier.
4. Add a row for the new scripts/checks to `README.md` if wanted.
5. Ask the user before committing further changes.

## Open decisions for the user (not changed)

- Insert-mode `<C-p>` is "paste from clipboard" in `keymaps.lua` but blink uses
  `<C-p>` for "previous item" while the menu is open.
- hop.nvim and flash.nvim overlap; one could go.
- Template leftovers in `module.nix` (`info.testvalue`,
  `settings.anothertestvalue`).
- Rust extras (expand macro, docs.rs, runnables) via rustaceanvim.
- statix and deadnix report style warnings in `flake.nix`/`module.nix`; they are
  not part of the gate.

## Probe notes

Test project: `/home/krapp/dev/fak/pruebas/lector-humedad` (needs
`direnv exec .`). The user is actively editing `src/main.rs` there, so line
numbers in probe case files shift: reread the file before choosing `line`.
The probe never saves the buffer.
