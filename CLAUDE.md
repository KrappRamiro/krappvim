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
nix flake check --print-build-logs   # lint (stylua, selene, nixfmt, statix, deadnix) + smoke test
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

### Testing UI and redraw behavior (folds, extmarks, statuscolumn)

`--headless` never redraws, so plugins that work from the decoration
provider (nvim-ufo records closed folds there, snacks statuscolumn) give
false results headless. Run the real TUI in a pseudo-terminal, with a Lua
driver that does one step per `vim.defer_fn` so Neovim redraws in between,
and writes results to a file:

```sh
OUT=$PWD/out.txt script -qfc "stty rows 40 cols 120; timeout --foreground 60 ./result/bin/kvim -n file.rs -c 'luafile driver.lua'" /dev/null
```

`--foreground` is required: without it `timeout` moves kvim out of the
terminal's foreground group and the TUI never reads input. `-n` skips the
swap file: a killed test run leaves one, and its prompt blocks the next run.

- Never run `kvim` without `--headless` or `script` from a tool: it waits
  for a terminal and hangs the shell.
- `timeout ... script -qfc "kvim ..."` only kills `script`: the real editor
  (`kvim --embed`) and its rust-analyzer survive as orphans and eat CPU and
  gigabytes of RAM. Put `timeout --foreground` inside the command (as
  above), give every driver a hard exit
  (`vim.defer_fn(function() vim.cmd("qa!") end, 20000)`) that runs even if a
  step fails, and after testing run
  `ps -eo pid,ppid,args | grep '[k]vim --embed'` and kill leftovers by PID.
- `nvim_feedkeys(keys, "n")` ignores mappings, so it tests the native
  command, not the config's keymap. Use `"m"` (or `"mt"`) when the test is
  about a mapping, and `"n"` only for typing text (it skips mini.pairs).
- which-key waits on prefixes such as `z`, so give mapped keys at least
  1.5 s per step before reading the result.
- Driving the TUI over RPC (`--listen` plus `--remote-send`) hung; prefer
  the in-process driver above.
- Do not monkeypatch `vim.api` functions to trace a bug: it changed plugin
  behavior here. Wrap the plugin's own Lua module functions instead.
- To isolate a bug, compare against a minimal config: `kvim --clean -u
  min.lua` that adds only the plugin with `packadd` from
  `result/kvim-packdir` and loads the real spec with `dofile`. Test with the
  real spec options, not the plugin defaults.
- To prove a bug fix, run the same driver against the installed
  `/run/current-system/sw/bin/kvim` (the old config) and show the
  difference.

### Lazy-loading events and glyphs

- A plugin that attaches to buffers and tracks their lines (nvim-ufo) must
  load on `BufReadPost`, not `BufReadPre`: in `BufReadPre` the file is not
  read yet, and the plugin keeps a line count of 1.
- Nerd Font icons from the Private Use Area can vanish when written through
  a tool. Write them as Lua byte escapes (`"\239\145\160"`) with the code
  point in a comment, and check the bytes with `cat -A` or a hex dump.

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
  Rust is the exception: rustaceanvim starts rust-analyzer
  (`lua/lze_specs/rustaceanvim.lua`). Never add a `rust_analyzer` spec to
  `lsp.lua`, that gives two clients on the same buffer.
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
2. In `~/nixos-config`: `nix flake update krappvim`, build the host without
   switching, commit and push the lock, then apply it yourself to test the
   new `kvim`: `just home-switch` on `ubuntu-gocloud`, `just deploy` on NixOS
   hosts. On `thinkpad`, `sudo nixos-rebuild` needs no password; on
   `desktop` it does, so ask the user to run `! just deploy`.

The `personal-setup` skill in `~/nixos-config`
(`modules/home/cli/claude_code_skills/personal-setup.md`) summarizes this
repo for sessions started elsewhere. When you change the layout, the
conventions for adding plugins or LSP servers, the checks, or this release
flow, update that skill too.

## Reference

nix-wrapper-modules (module.nix options, specs, wlib, specMods):
https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/neovim.html
