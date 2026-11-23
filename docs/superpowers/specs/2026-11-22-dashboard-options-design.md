# Dashboard configurable desde Nix

Fecha: 2026-11-22. Estado: borrador para aprobar.

## Intención

El dashboard de kvim (snacks.dashboard + milli) se siente pobre. Se
investigaron unas 50 variantes y se grabaron en ghostty (galería:
https://claude.ai/artifact/9Je7u2T43g2WgPTwEyC8ag). Al usuario le gustan
todas. No quiere elegir una para siempre: quiere que kvim las soporte todas
como **opciones de Nix**, y elegir en su config (por ejemplo, en
`~/nixos-config`) qué dashboard quiere y con qué parámetros, igual que
configura NixOS.

Además, una guía en `docs/` para cualquier usuario del flake: cada opción,
cómo se configura, el snippet de Nix y la captura o el video.

## Objetivos

- Todas las variantes de la galería se pueden elegir y parametrizar desde
  Nix.
- Las piezas se combinan (header + panel + overlay + footer), y los ejemplos
  de la galería existen como presets de una línea.
- Lo que no se usa no entra al build: ni plugins ni binarios.
- Sin configuración, kvim se ve exactamente como hoy (blackhole de milli,
  título, 5 teclas, recientes, versión).
- Guía en `docs/dashboard/` legible en GitHub, con capturas y animaciones.

## No objetivos

- Cambiar de dashboard en caliente (comando o tecla). Se elige en Nix.
- Rotar entre dashboards distintos en cada arranque. Lo aleatorio vive dentro
  de una pieza (`random` de snacks, `splash = "random"` de milli).
- Cambiar de plugin de dashboard (alpha, dashboard-nvim, mini.starter como
  motor). snacks sigue siendo el motor; mini.starter queda como preset
  aparte (ver abajo).

## Anti-objetivos

- Que un preset o pieza rompa el arranque. Si una pieza falla en Lua, el
  dashboard se dibuja igual sin ella y avisa con `vim.notify`.
- Que el tiempo de arranque suba con piezas apagadas.
- Que la guía muestre algo que no corrió de verdad.

## Restricciones

- Convenciones de `CLAUDE.md`: lazy-load, comentarios en español que
  explican el porqué, sin em dashes, `nix flake check` pasa, probar en el TUI
  real con `script`, medir arranque antes y después.
- `section = "startup"` de snacks no sirve en kvim: hace
  `require("lazy.stats")` y kvim usa lze. Hay que reemplazarla.
- Las secciones `terminal` de snacks cachean la salida (`ttl`, por defecto
  3600 s) y muestran `[Process exited 0]` cuando no hay caché. Las piezas
  animadas usan `ttl = 0` y terminan en `sleep` largo.
- cbonsai necesita `LC_ALL=C` (el locale en español rechaza `-t 0.04`).
- Dos paneles (`pane = 2`) necesitan unas 130 columnas; con menos, snacks
  apila los paneles y el panel 2 tapa al 1.
- drop.nvim no está en nixpkgs: va como input `plugins-drop` del flake.
- Los splashes del registro de milli (aurora, flyingdragon, catwoman y otros)
  se bajan con curl en runtime. En Nix van como input `milli-splashes`
  (flake = false) y se copian a una carpeta del runtimepath, sin red.
- La CLI de milli (texto propio, GIF a splash) es npm y no está en nixpkgs.
  No se integra; la guía documenta cómo generar el `.lua` a mano y pasarlo
  como `splashFile`.

## Enfoques considerados

- **A. Un estilo por nombre con sus parámetros.** Simple, calza con la
  galería, pero no combina piezas (wallpaper real + fastfetch + hojas).
- **B. Piezas combinables con presets encima.** Elegido por el usuario.
  Todo combina, cada pieza trae solo sus dependencias, y los ejemplos de la
  galería son presets de una línea.
- **C. Secciones crudas de snacks en Lua.** Máxima libertad, pero deja de ser
  configurable. Queda solo como salida de emergencia (`extraSections`).

## Diseño

### Cómo se usa (desde nixos-config)

`flake.nix` ya expone `packages.<system>.default` con `.wrap`. El
consumidor reevalúa kvim con sus opciones:

```nix
environment.systemPackages = [
  (krappvim.packages.${system}.default.wrap {
    settings.dashboard = {
      preset = "pokemon";
      header = { kind = "milli"; splash = "fire"; };
      overlay.drop.enable = true;
    };
  })
];
```

`nixosModules` y `homeModules` del flake reciben las mismas opciones (ya
salen de `getInstallModule`). La guía muestra las dos formas.

### Opciones (`settings.dashboard`)

Se declaran en un módulo nuevo `nix/dashboard.nix`, importado desde
`module.nix`. Tipos con `lib.types` para que un error de tipeo falle en
build, no al abrir kvim.

```
preset        enum: null | blackhole | doom | pokemon | chafa | startify |
                    advanced | github | compact | image | fastfetch |
                    bonsai | aquarium | calm | ministarter
              Un preset solo pone valores por defecto (lib.mkDefault) en las
              piezas; todo lo que el usuario escribe gana.

title         str, default "── krapp.vim ──" (null lo saca)
keys          bool o lista de { key; desc; action; icon; }, default las 5 de hoy
recent        { enable; limit; cwd; }
projects      { enable; limit; }
layout        enum: auto | one | two  (auto: dos paneles si hay panel)

header.kind   enum: milli | shader | text | figlet | toilet | image | chafa |
                    hour | cmd | none
  milli       { splash: str (bundled, registro o "random"); loop: bool }
  shader      { name: rain | plasma | doomfire | starfield; fps; hue }
  text        { text: str }            (arte fijo, cero costo)
  figlet      { text; font }
  toilet      { text; font; filter }   (filter: gay | metal | border ...)
  image       { path: path; width; height }   (píxeles reales, kitty)
  chafa       { path: path; width; height; symbols }
  hour        { variants: { night; morning; afternoon } }  (texto o cmd)
  cmd         { cmd: str; height; ttl; random }  (cualquier comando)
  splashFile  path opcional: un .lua generado con la CLI de milli

panel.kind    enum: none | pokemon | krabby | fastfetch | github | git |
                    colorscript | fortune | cbonsai | aquarium | cmatrix |
                    lolcat | cmd
  cada uno con sus parámetros (pokemon.random, colorscript.name,
  fortune.cow, cbonsai.live, github.sections ...)
  animated (cbonsai.live, aquarium, cmatrix, lolcat) => ttl = 0 + sleep

overlay.drop  { enable; theme: auto | leaves | snow | xmas | ... ;
                screensaver: false | segundos }
footer        { startup: bool; version: bool; text: str|null }
extraSections lista de tablas Lua crudas (lib.generators.mkLuaInline)

extras.screensaver       { enable; shader | splash; after }   (milli)
extras.cellularAutomaton { enable; keymap }                   (tecla de broma)
```

### Lo que no se usa no cuesta

Cada pieza que trae algo es una spec propia con `enable` atado a la opción:

- Plugins: `specs.drop.enable = cfg.overlay.drop.enable;`,
  `specs.cellular-automaton.enable = cfg.extras.cellularAutomaton.enable;`,
  `specs.milli-registry.enable = <splash del registro elegido>`.
- Binarios: specs sin plugin (`data = null`) con el campo `runtimePkgs` que
  ya existe en `module.nix`. `specCollect` solo junta los de specs
  habilitadas, así que `pkgs.cbonsai` entra solo si se eligió cbonsai.
- milli sigue cargándose eager solo si `header.kind` es `milli` o `shader`,
  o si `extras.screensaver` está activo. Si no, no entra.

### Lado Lua

- `lua/dashboard/init.lua`: lee `nixInfo(nil, "settings", "dashboard")` y
  arma la tabla de `Snacks.dashboard` (preset + sections). Lo llama el
  `after` de snacks en `lua/lze_specs/snacks.lua`, que deja de tener el
  dashboard escrito a mano.
- `lua/dashboard/pieces/<kind>.lua`: una función por pieza que devuelve
  secciones de snacks. Cada una se envuelve en `pcall`; si falla, se omite y
  se avisa.
- `lua/dashboard/startup.lua`: reemplazo de `section = "startup"`, mide con
  la edad del proceso (`/proc/self/stat`) cuando snacks emite
  `SnacksDashboardOpened`, no al cargar el archivo.
- `image`: `Snacks.image.placement.new(buf, path, { pos = { fila, col } })`
  tras `SnacksDashboardOpened`, con la fila del título menos 2. snacks
  dibuja la imagen como líneas virtuales debajo de esa fila.
- El autocmd actual que reabre el dashboard al cerrar el último buffer se
  conserva tal cual.

### Presets

Archivo `nix/dashboard-presets.nix`: un attrset por preset con las piezas
de la galería. Ejemplo:

```nix
pokemon = {
  header = { kind = "figlet"; text = "krapp.vim"; font = "slant"; };
  panel = { kind = "pokemon"; random = 10; };
  layout = "two";
};
```

`ministarter` es especial: en vez de snacks usa `mini.starter` (ya está en
mini.nvim) y apaga el dashboard de snacks.

### Verificación

- `nix flake check` agrega un check por preset:
  `checks.dashboard-<preset>` = kvim con ese preset, corriendo un script
  headless que llama al armador de Lua y verifica que devuelve secciones sin
  error y que los binarios de sus piezas están en PATH.
- Un check que arma kvim sin configuración y compara las secciones con las
  de hoy (no cambia nada por defecto).
- Tiempo de arranque medido antes y después con el preset por defecto y con
  todo apagado (`header.kind = "none"`).
- Prueba en el TUI real con `script` para dos o tres presets, según
  `CLAUDE.md`.

### Guía (`docs/dashboard/`)

- `docs/dashboard/README.md`: cómo elegir un dashboard (`.wrap`, módulo de
  NixOS, módulo de Home Manager), tabla de presets, y una sección por pieza
  con: qué es, captura o animación, snippet de Nix, parámetros, dependencias
  que agrega, costo en arranque.
- `docs/dashboard/media/`: capturas JPG recortadas y animaciones en WebP
  animado (GitHub las muestra en Markdown; MP4 del repo no se reproduce).
  Presupuesto: unos 15 MB en total.
- `scripts/record-dashboards.sh`: la tubería que generó la galería (sway
  headless + ghostty + grim + wf-recorder), ahora leyendo los presets de
  verdad, para regenerar los medios cuando cambie algo. Nunca abre ventanas
  en la sesión del usuario.
- Link desde `README.md` y fila en la tabla de plugins para drop.nvim y
  cellular-automaton.

## Decisiones del builder (mis calls, a revisar)

- Nombres exactos de opciones y presets: los de arriba, ajustables.
- Default sin configuración = preset `blackhole` (lo de hoy).
- Animaciones WebP en vez de GIF: menos peso a la misma calidad.
- `extraSections` como única vía cruda; no hay opción para Lua arbitrario en
  `after`.

- `panel` es una **lista** de piezas, no una sola: advanced (colores,
  recientes, proyectos, git) y github (issues, PRs, commits) apilan varias
  en la columna derecha y tienen que seguir siendo presets de una línea.
  `runtimePkgs` se junta por tipo de pieza presente en la lista.
- Parámetros **anidados por tipo** (`header.figlet.font`,
  `header.toilet.filter`). Cambiar `header.kind` deja de usar los
  parámetros del tipo anterior, así un preset no arrastra valores ajenos.
  Los ejemplos de arriba con forma plana se leen con esta forma.
- `image.path` y `chafa.path` tienen default: el copo de NixOS de
  `pkgs.nixos-icons`. El preset funciona en una línea y los checks tienen
  una imagen; el usuario pasa la suya cuando quiere.

## Decisiones del usuario

- Los medios de `docs/dashboard/media/` pueden mostrar información
  personal: wallpaper y avatar de `nixos-config/assets/`, fastfetch con
  usuario y hostname, git y GitHub de krappvim, rutas de recientes. Se
  reusan las capturas y videos ya grabados para la galería (en
  `/tmp/claude-1000/.../scratchpad/site/k` y `g`) donde coinciden con un
  preset; solo se graba lo que falte o cambie.
- Las grabaciones se hacen en `thinkpad` (máquina personal): nunca en la de
  trabajo, para que no aparezcan identificadores de trabajo (regla global de
  cuentas de git).

## Pendiente para el builder

- Lista final de parámetros por pieza (sale de los flags de cada programa).
- Qué splashes del registro de milli se empaquetan (todos o solo los
  nombrados en la opción).
