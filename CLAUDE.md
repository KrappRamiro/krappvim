# krappvim

Personal Neovim config, packaged with Nix (nix-wrapper-modules) and lazy-loaded
with lze. The binary is `kvim`.

## Who does the work

Claude manages this code: make the edits, run the checks, verify the result.
The user is still learning Neovim and Nix, so explain what changed and why in
plain language, but do not hand the work back to them.

## Layout

- `flake.nix`: flake outputs (package, checks, formatter, modules).
- `module.nix`: the wrapper module. Plugins and every external binary (LSP
  servers, formatters, linters) are declared here.
- `init.lua`: options, lze handlers, and the list of spec imports.
- `lua/keymaps.lua`: global keymaps.
- `lua/lze_specs/<plugin>.lua`: one file per plugin (or plugin group).
- `scripts/smoke.lua`: headless startup test, run by `nix flake check`.
- `scripts/probe-completion.lua`: dumps blink.cmp ranking with scores.

## Required checks

Run before saying a change is done:

```sh
nix flake check --print-build-logs   # lint (stylua, selene, nixfmt) + smoke test
```

Auto-fix formatting:

```sh
nix shell --inputs-from . nixpkgs#stylua nixpkgs#nixfmt -c sh -c 'stylua init.lua lua scripts; nixfmt flake.nix module.nix'
```

The flake only sees files known to git. Run `git add -N <file>` on new files
before `nix build` or `nix flake check`, or they are silently ignored.

## Verifying behavior

A passing build does not prove a config change works. Test it in the real editor:

```sh
nix build && ./result/bin/kvim --headless -c "luafile scripts/smoke.lua"
```

For anything about completion ranking, measure with
`scripts/probe-completion.lua` before and after the change (usage is in the
file header). Do not tune scores by guessing.

To read a plugin's source or docs for the pinned version, look under
`result/kvim-packdir/pack/myNeovimPackages/{start,opt}/<plugin>/`. Prefer that
over memory: plugin APIs change often.

## Conventions

- Adding a plugin: add it to `module.nix`, create `lua/lze_specs/<name>.lua`,
  import it in `init.lua`, and add a row to `README.md`.
- Adding an LSP server: follow the header comment in `lua/lze_specs/lsp.lua`,
  and add the binary to `runtimePkgs` in `module.nix`.
- Lazy-load every plugin (`event`, `ft`, `keys`, `cmd`, `on_require`). If code
  calls `require("x")` on a lazy plugin from outside its spec, give that spec
  `on_require = "x"`.
- One tool per job per filetype: do not run the same linter from both an LSP
  and nvim-lint, and route all formatting through conform.
- Comments are in Spanish and explain the why (the user reads them to learn).
  Keep that style. No em dashes anywhere.
- Unused callback parameters are named `_` (selene fails on warnings).
- Keymap groups: `<leader>t*` are toggles, declared in `which_key.lua`.

## Release flow

1. Commit and push here (personal repo, see the global git rules).
2. In `~/nixos-config`: `nix flake update krappvim`, then the user runs the
   deploy (it needs sudo with a password, so Claude cannot run it).

## Reference

nix-wrapper-modules (module.nix options, specs, wlib, specMods):
https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/neovim.html
