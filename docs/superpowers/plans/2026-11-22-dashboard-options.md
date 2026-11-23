# Dashboard configurable desde Nix: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** que `settings.dashboard` (Nix) elija y parametrice cualquiera de
las variantes de la galería, con piezas combinables y presets, sin costo
para lo que no se usa, más una guía en `docs/dashboard/`.

**Architecture:** un módulo Nix (`nix/dashboard/`) declara las opciones
tipadas, resuelve presets con `lib.mkDefault`, habilita specs y
`runtimePkgs` solo para las piezas elegidas, y pasa la config resuelta a
Lua por `settings.dashboard`. En Lua, `lua/dashboard/` lee esa config con
`nixInfo` y arma la tabla de `Snacks.dashboard`, una función por pieza.

**Tech Stack:** Nix (nix-wrapper-modules, `lib.types`), Lua (Neovim 0.12,
snacks.nvim dashboard e image, milli.nvim, drop.nvim, mini.starter,
cellular-automaton.nvim), sway headless + ghostty + grim + wf-recorder +
ffmpeg para los medios.

**Spec:** `docs/superpowers/specs/2026-11-22-dashboard-options-design.md`

## Global Constraints

- Sin configuración, kvim se ve exactamente como hoy: splash `blackhole`
  con `loop = true`, título `── krapp.vim ──`, las 5 teclas actuales
  (f, n, g, r, q), recientes, footer `Neovim v<version>`.
- Lo que no se usa no entra al build (ni plugin ni binario).
- Comentarios en español que explican el porqué. Sin em dashes. Sin
  abreviaturas latinas. Parámetros sin uso se llaman `_`.
- Todo plugin lazy-loaded (lze). Plugin nuevo: `module.nix` (o
  `nix/dashboard`), spec en `lua/lze_specs/`, import en `init.lua`, fila en
  `README.md`.
- `nix flake check --print-build-logs` pasa al final de cada tarea.
- Archivos nuevos: `git add -N <file>` antes de `nix build` o
  `nix flake check`.
- Pruebas de UI en el TUI real con
  `script -qfc "timeout --foreground N ./result/bin/kvim -n ..."`, nunca
  kvim sin `--headless` o `script`. Revisar procesos `kvim --embed`
  colgados después.
- Nunca abrir ventanas en la sesión de sway del usuario: medios con sway
  headless (`WLR_BACKENDS=headless`, `WAYLAND_DISPLAY` sin setear).
- `section = "startup"` de snacks está prohibida (rompe en kvim).
- Secciones `terminal` animadas: `ttl = 0` y el comando termina en
  `; sleep 600`. cbonsai siempre con `LC_ALL=C`.
- Grabaciones solo en el host `thinkpad`.

## Review Focus

- Usuario pone `panel = [ ]` con `layout = "two"`: se dibuja en una
  columna, sin error. Test en Task 4.
- Terminal angosta (menos de 130 columnas) con panel: snacks apila; el
  armador elige `one` cuando `layout = "auto"` y `vim.o.columns < 130`.
  Test en Task 4.
- Una pieza tira error en Lua (por ejemplo, `image.path` que no existe):
  el dashboard se dibuja sin esa pieza y hay un `vim.notify` WARN. Test en
  Task 3.
- Usuario cambia `header.kind` sobre un preset: los parámetros del tipo
  anterior no llegan a Lua. Test en Task 1.
- Splash de milli del registro elegido (`aurora`) sin red: se resuelve
  desde el input `milli-splashes`, sin curl. Test en Task 2.

---

### Task 1: Opciones y presets en Nix

**Files:**
- Create: `nix/dashboard/options.nix` (opciones `settings.dashboard`)
- Create: `nix/dashboard/presets.nix` (attrset de presets)
- Create: `nix/dashboard/default.nix` (importa los dos, resuelve preset)
- Modify: `module.nix` (agregar `imports = [ ./nix/dashboard ];`)
- Test: `tests/dashboard-eval.nix` + check `checks.dashboard-eval` en
  `flake.nix`

**Interfaces:**
- Produces: opción `settings.dashboard` con esta forma resuelta (lo que
  ve Lua por `nixInfo(nil, "settings", "dashboard")`):
  `{ preset; title; keys; recent = { enable; limit; cwd; }; projects = { enable; limit; }; layout; header = { kind; <solo el attrset del kind activo>; }; panel = [ { kind; <params del kind>; } ]; overlay.drop = { enable; theme; screensaver; }; footer = { startup; version; text; }; extraSections; }`
  y `settings.dashboardExtras = { screensaver = { enable; shader; splash; after; }; cellularAutomaton = { enable; keymap; }; }`.
- Produces: `config.dashboard.usesKind = kind: bool` (función interna,
  `options.dashboard.internal`, readOnly) que las Tasks 2 usa para gatear.
- Kinds de header: `milli shader text figlet toilet image chafa hour cmd none`.
- Kinds de panel: `pokemon krabby fastfetch github git colorscript fortune cbonsai aquarium cmatrix lolcat recent projects cmd`.
- Presets: `blackhole doom pokemon chafa startify advanced github compact image fastfetch bonsai aquarium calm ministarter`.

- [ ] **Step 1: Escribir el test de evaluación** `tests/dashboard-eval.nix`:
  una función `{ krappvim, lib }` que evalúa `wrappers.neovim` con
  `.wrap`/`.eval` para cinco configs y hace `assert`:
  1. sin config: `header.kind == "milli"`, `header.milli.splash == "blackhole"`, `header.milli.loop == true`, `panel == [ ]`, `title == "── krapp.vim ──"`, `builtins.length keys == 5`, `footer.version == true`.
  2. `preset = "pokemon"`: `header.kind == "figlet"`, `header.figlet.text == "krapp.vim"`, `panel` tiene un elemento `kind = "pokemon"` con `random = 10`, `layout == "two"`.
  3. `preset = "pokemon"; header.kind = "toilet";`: `header ? figlet == false`, `header.toilet.text == "krapp.vim"`.
  4. `header.image = { }` con `kind = "image"`: `header.image.path` apunta a un archivo dentro de `pkgs.nixos-icons`.
  5. `header.kind = "nope"`: la evaluación falla (`builtins.tryEval` da `success = false`).
- [ ] **Step 2: Agregar `checks.dashboard-eval`** en `flake.nix` que
  importa el test y hace `touch $out`. Correr
  `nix build .#checks.x86_64-linux.dashboard-eval` y ver que falla porque
  `settings.dashboard` no existe.
- [ ] **Step 3: Implementar** `nix/dashboard/options.nix` con
  `lib.types.submodule`, enums de arriba, parámetros anidados por kind
  (la lista de cada kind está en el spec, sección Opciones).
  `nix/dashboard/default.nix` aplica `presets.${preset}` con
  `lib.mkDefault` y publica en `settings.dashboard` solo
  `header.<kind activo>` y, por cada panel, solo sus params.
- [ ] **Step 4:** el check pasa; `nix flake check --print-build-logs` pasa.
- [ ] **Step 5: Commit** `dashboard: Nix options and presets`.

### Task 2: Dependencias solo para lo elegido

**Files:**
- Modify: `flake.nix` (inputs `plugins-drop` = `github:folke/drop.nvim`,
  `milli-splashes` = `github:amansingh-afk/milli-splashes`, ambos
  `flake = false`)
- Modify: `module.nix` (sacar `milli` de la lista de `general`)
- Create: `nix/dashboard/deps.nix` (specs gateadas)
- Test: ampliar `tests/dashboard-eval.nix`

**Interfaces:**
- Consumes: `config.dashboard.usesKind` (Task 1).
- Produces: specs `dashboard-milli`, `dashboard-drop`,
  `dashboard-cellular`, `dashboard-milli-registry`, y una spec
  `dashboard-tools` con `data = null` y `runtimePkgs` calculado por kind:
  figlet->figlet, toilet->toilet, chafa->chafa, pokemon->pokemon-colorscripts,
  krabby->krabby, fastfetch->fastfetch, github->gh, colorscript->dwt1-shell-color-scripts,
  fortune->fortune+cowsay, cbonsai->cbonsai, aquarium->asciiquarium,
  cmatrix->cmatrix, lolcat->figlet+lolcat, hour->toilet.
- Produces: splashes del registro en `pack/.../dashboard-milli-registry/lua/milli/splashes/<name>.lua`
  (solo los nombrados en `header.milli.splash`, o todos si es `random`).

- [ ] **Step 1: Tests nuevos** en `tests/dashboard-eval.nix`:
  - sin config: `config.runtimePkgs` no contiene `cbonsai` ni `chafa`;
    `specs.dashboard-drop.enable == false`; `specs.dashboard-milli.enable == true`.
  - `header.kind = "figlet"`: `specs.dashboard-milli.enable == false`.
  - `panel = [ { kind = "cbonsai"; } ]`: `runtimePkgs` contiene `pkgs.cbonsai`.
  - `header.milli.splash = "aurora"`: `specs.dashboard-milli-registry.enable == true` y el derivado contiene `lua/milli/splashes/aurora.lua`.
  - `extras.screensaver.enable = true` con `header.kind = "text"`: milli habilitado.
- [ ] **Step 2:** correr el check, ver que falla.
- [ ] **Step 3: Implementar** `nix/dashboard/deps.nix`. La spec `lze`
  `milli` en `lua/lze_specs/snacks.lua` pasa a `auto_enable = true` sin
  `lazy = false` cuando no hay milli (ya lo hace lze si el plugin falta);
  agregar `lua/lze_specs/drop.lua` y `lua/lze_specs/cellular_automaton.lua`
  con `auto_enable = true`, importados en `init.lua`.
- [ ] **Step 4:** check y `nix flake check` pasan. Medir arranque de base
  ahora (antes de tocar Lua):
  `./result/bin/kvim --headless --startuptime /tmp/claude-1000/st-before.txt +q`
  tres veces; anotar el total en el mensaje de commit.
- [ ] **Step 5: Commit** `dashboard: gate plugins and tools by chosen pieces`.

### Task 3: Armador Lua y headers

**Files:**
- Create: `lua/dashboard/init.lua` (`M.build(cfg, ctx) -> snacks_opts`, `M.setup()`)
- Create: `lua/dashboard/startup.lua` (`M.section() -> snacks_section`)
- Create: `lua/dashboard/header/<kind>.lua` (uno por kind de header)
- Test: `scripts/dashboard-test.lua` (headless, sale 1 si falla)

**Interfaces:**
- Consumes: forma de `settings.dashboard` (Task 1).
- Produces: `require("dashboard").build(cfg: table, ctx: { columns: integer }) -> { preset = { header?, keys }, sections = table[], formats? }`;
  cada `lua/dashboard/header/<kind>.lua` exporta `function(p: table, cfg: table) -> table[]` (lista de secciones snacks);
  `require("dashboard").setup()` lee `nixInfo(nil, "settings", "dashboard")`, llama `build`, devuelve el `dashboard = { ... }` para `require("snacks").setup`, y registra los autocmds `SnacksDashboardOpened` (milli, imagen, startup).
  `require("dashboard.startup").section() -> { text = { ... }, align = "center", padding = 1 }` con `"kvim listo en N ms"`, N medido en `SnacksDashboardOpened` con `/proc/self/stat` (campo 22) y `/proc/uptime`.

- [ ] **Step 1: Tests** en `scripts/dashboard-test.lua` (funciones
  `test_<nombre>` que corren con `pcall`, juntan fallas, `os.exit(1)`):
  - `test_default_matches_today`: `build(<config por defecto>)` da
    `sections[1].section == "header"`, `preset.header` igual al frame 1
    de `require("milli").load({ splash = "blackhole" })`, una sección con
    texto `── krapp.vim ──`, `section == "keys"` con `gap = 1`,
    `section == "recent_files"`, y footer con `"Neovim v"`.
  - `test_figlet_header`: `kind = "figlet"` da una sección `terminal`
    con `cmd` que empieza con `figlet -f slant`.
  - `test_cmd_animated_never_cached`: header `cmd` con `animated = true`
    da `ttl = 0` y `cmd` que termina en `; sleep 600`.
  - `test_bad_piece_is_skipped`: un kind de header cuyo módulo tira error
    (stub en `package.loaded["dashboard.header.text"]`) devuelve
    secciones sin header y registra un `vim.notify` nivel WARN.
  - `test_no_startup_section`: ninguna sección tiene `section = "startup"`.
  - `test_extra_sections_appended`: `extraSections = { { text = "x" } }`
    aparece como última sección antes del footer.
  - `test_milli_splash_file`: `header.milli.splashFile = "<ruta a un .lua de prueba en scripts/fixtures/splash.lua>"`
    usa ese archivo: `preset.header` es su frame 1.
- [ ] **Step 2:** correr
  `nix build && ./result/bin/kvim --headless -c "luafile scripts/dashboard-test.lua"`;
  falla porque `dashboard` no existe.
- [ ] **Step 3: Implementar** `init.lua`, `startup.lua` y los 10 headers.
  `image`: no devuelve secciones de imagen; devuelve un hueco y registra
  `Snacks.image.placement.new(buf, path, { pos = { fila_titulo - 2, col }, width, height, max_width, max_height })`
  en `SnacksDashboardOpened` (ver spec). `hour`: elige `night` (<6),
  `morning` (<13) o `afternoon`.
- [ ] **Step 4:** el test pasa; agregarlo a `checks.smoke` en `flake.nix`
  (`kvim --headless -c "luafile ${self}/scripts/dashboard-test.lua"`).
- [ ] **Step 5: Commit** `dashboard: Lua builder and header pieces`.

### Task 4: Paneles y layout

**Files:**
- Create: `lua/dashboard/panel/<kind>.lua` (uno por kind de panel)
- Modify: `lua/dashboard/init.lua` (layout y panes)
- Test: `scripts/dashboard-test.lua`

**Interfaces:**
- Produces: cada `lua/dashboard/panel/<kind>.lua` exporta
  `function(p: table, cfg: table) -> table[]`; `build` les pone `pane = 2`
  cuando el layout resuelto es `two`.

- [ ] **Step 1: Tests:**
  - `test_two_panes`: `panel = { { kind = "pokemon", random = 10 } }`,
    `layout = "two"`, `ctx.columns = 200`: la sección pokemon tiene
    `pane = 2`, `random = 10`, `cmd` con `pokemon-colorscripts -r --no-title`.
  - `test_auto_narrow_is_one_column`: igual con `layout = "auto"` y
    `ctx.columns = 100`: ninguna sección tiene `pane = 2`.
  - `test_empty_panel_two_layout`: `panel = {}` y `layout = "two"`: no
    hay `pane = 2` y no hay error.
  - `test_cbonsai_live`: `{ kind = "cbonsai", live = true }`: `cmd`
    empieza con `LC_ALL=C cbonsai -l`, `ttl = 0`, termina en `; sleep 600`.
  - `test_github_needs_git_root`: las secciones github tienen
    `enabled` función o booleano que depende de `Snacks.git.get_root()`.
- [ ] **Step 2:** correr, ver que falla.
- [ ] **Step 3: Implementar** los 14 paneles y el layout. `ctx.columns`
  viene de `vim.o.columns` en `setup()`.
- [ ] **Step 4:** el test pasa; `nix flake check` pasa.
- [ ] **Step 5: Commit** `dashboard: panel pieces and layout`.

### Task 5: Overlay, extras y mini.starter

**Files:**
- Create: `lua/dashboard/extras.lua` (`M.apply(extras, dashboard_cfg)`)
- Modify: `lua/lze_specs/drop.lua`, `lua/lze_specs/cellular_automaton.lua`
- Modify: `lua/lze_specs/mini.lua` (rama `ministarter`)
- Test: `scripts/dashboard-test.lua`

**Interfaces:**
- Consumes: `settings.dashboard.overlay.drop`, `settings.dashboardExtras`.
- Produces: drop con `filetypes = { "snacks_dashboard" }` y `theme`;
  milli `screensaver({ shader, splash, after })`; keymap de
  cellular-automaton (`extras.cellularAutomaton.keymap`, default
  `<leader>ur`) que corre `make_it_rain`.

- [ ] **Step 1: Tests:** `test_drop_config` (la tabla que se le pasa a
  `require("drop").setup` tiene `filetypes = { "snacks_dashboard" }` y el
  theme pedido); `test_ministarter_disables_snacks` (`preset = "ministarter"`
  hace que `setup()` devuelva `enabled = false` para snacks dashboard y
  configure `MiniStarter`).
- [ ] **Step 2:** correr, ver que falla.
- [ ] **Step 3: Implementar.** Fila de `<leader>u*` en `which_key.lua` si
  se agrega el grupo.
- [ ] **Step 4:** test y `nix flake check` pasan.
- [ ] **Step 5: Commit** `dashboard: drop overlay, screensaver, cellular-automaton, mini.starter`.

### Task 6: Conectar con snacks y checks por preset

**Files:**
- Modify: `lua/lze_specs/snacks.lua` (el bloque `dashboard = { ... }` pasa a
  `dashboard = require("dashboard").setup()`; conservar el autocmd
  `BufDelete` que reabre el dashboard)
- Modify: `flake.nix` (`checks.dashboard-<preset>` para los 14 presets)
- Create: `scripts/dashboard-check.lua` (verifica que el preset arma sin
  error y que cada `cmd` de sus secciones tiene su binario en PATH con
  `vim.fn.executable`)

- [ ] **Step 1:** escribir `scripts/dashboard-check.lua` y los checks;
  correr `nix flake check`, ver que fallan los presets cuyo cableado falta.
- [ ] **Step 2:** conectar `snacks.lua`.
- [ ] **Step 3:** `nix flake check --print-build-logs` pasa con los 14.
- [ ] **Step 4: Prueba TUI** con
  `script -qfc "stty rows 50 cols 200; timeout --foreground 20 ./result/bin/kvim -n -c 'luafile <driver>'"`
  para: default, `pokemon`, `image`, `bonsai`. El driver escribe en un
  archivo las líneas del buffer del dashboard tras 3 s; comparar el
  default con `/run/current-system/sw/bin/kvim` (las mismas líneas).
  Revisar `ps -eo pid,args | grep '[k]vim --embed'`.
- [ ] **Step 5: Medir arranque** igual que en Task 2 con default y con
  `header.kind = "none"`; el default no sube más de 5 ms.
- [ ] **Step 6: Commit** `dashboard: wire builder into snacks, per-preset checks`.

### Task 7: Medios

**Files:**
- Create: `scripts/record-dashboards.sh` (desde
  `docs/dashboard/{shot.sh,all.sh,sway.conf}`, que hoy usan
  `proto.lua`; pasan a usar `kvim` armado con cada preset vía
  `nix build --impure --expr` + `.wrap`)
- Create: `docs/dashboard/media/<preset-o-pieza>.{jpg,webp}`
- Delete: `docs/dashboard/{proto.lua,all.sh,shot.sh,sway.conf}` y
  `docs/dashboard/media/src/` al terminar (lo útil ya está convertido)

- [ ] **Step 1:** convertir lo existente: JPG de
  `media/src/ghostty/d_*.jpg` tal cual; MP4 a WebP animado con
  `ffmpeg -i in.mp4 -vf "fps=12,scale=720:-2" -loop 0 -c:v libwebp_anim -q:v 60 out.webp`.
  Presupuesto total de `docs/dashboard/media/` <= 15 MB
  (`du -sh`); bajar fps o ancho si se pasa.
- [ ] **Step 2:** grabar con el script lo que no existe todavía: header
  `hour` con preset real, `milli` registro (`aurora` dentro del
  dashboard), `screensaver`. Solo en `thinkpad`; nunca en la sesión de
  sway del usuario.
- [ ] **Step 3:** mirar cada medio nuevo (hoja de contacto con
  `magick montage`) antes de commitear.
- [ ] **Step 4: Commit** `docs: dashboard media and recording script`.

### Task 8: Guía

**Files:**
- Create: `docs/dashboard/README.md`
- Modify: `README.md` (link a la guía; filas de drop.nvim y
  cellular-automaton.nvim en la tabla de plugins)
- Modify: `~/nixos-config/modules/home/cli/claude_code_skills/personal-setup.md`
  (una línea: dashboard se configura con `settings.dashboard`, guía en
  `docs/dashboard/`)

- [ ] **Step 1: Escribir la guía.** Orden: cómo elegir (con `.wrap` en
  `environment.systemPackages`, con `nixosModules`, con `homeModules`);
  tabla de presets con miniatura; una sección por kind de header, de panel,
  overlay y extras con: qué es, medio, snippet Nix mínimo, parámetros
  (tabla nombre / tipo / default), dependencias que agrega, costo; cómo
  generar un splash propio con la CLI de milli a mano y pasarlo con
  `header.milli.splashFile`; hallazgos (`startup`, `[Process exited 0]`,
  ancho para dos paneles, `LC_ALL=C`). Estilo: skill `google-dev-style`,
  español rioplatense, sin em dashes.
- [ ] **Step 2: Verificar** que cada snippet de la guía evalúa: extraer
  los bloques `nix` con un script y evaluarlos contra
  `wrappers.neovim` (agregarlo a `checks.dashboard-docs`).
- [ ] **Step 3:** `nix flake check` pasa; borrar `HANDOFF.md`.
- [ ] **Step 4: Commit** `docs: dashboard guide`.

### Task 9: Release (con OK del usuario)

- [ ] **Step 1:** preguntar al usuario qué dashboard quiere en
  `~/nixos-config` y escribirlo con `.wrap` en `flake.nix` de nixos-config.
- [ ] **Step 2:** flujo de `CLAUDE.md`: push en krappvim,
  `nix flake update krappvim`, `just check`, commit y push, `just deploy`.
- [ ] **Step 3:** abrir el kvim nuevo en el TUI (driver con `script`) y
  confirmar el dashboard elegido.
