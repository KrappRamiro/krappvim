# Opciones de `settings.dashboard`: qué dashboard muestra kvim al arrancar.
# Todo está tipado con lib.types para que un error de tipeo (un kind que no
# existe, un número donde va texto) falle al evaluar Nix, no al abrir kvim.
#
# Los parámetros van anidados por kind (`header.figlet.font`): así, si un
# preset elige figlet y el usuario cambia a toilet, los parámetros de figlet
# no se arrastran. `default.nix` publica en Lua solo los del kind activo.
{ lib, pkgs }:
let
  inherit (lib) mkOption types;

  opt =
    type: default: description:
    mkOption { inherit type default description; };
  str = opt types.str;
  int = opt types.int;
  bool = opt types.bool;
  nullStr = opt (types.nullOr types.str);
  nullInt = opt (types.nullOr types.int);
  pathOpt = opt types.path;
  sub =
    options:
    mkOption {
      type = types.submodule { inherit options; };
      default = { };
    };

  # Imagen por defecto de las piezas image y chafa: el copo de NixOS. Así un
  # preset funciona en una línea y los checks tienen una imagen real.
  snowflake = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake.png";

  # Paquetes extra que necesita un `cmd` propio (por ejemplo, cowsay). Se
  # suman al PATH de kvim y no llegan a Lua.
  packagesOpt = opt (types.listOf types.package) [ ] "Paquetes que el comando necesita en el PATH.";

  # Piezas que corren un comando en una sección `terminal` de snacks.
  cmdOptions = {
    cmd = str "" "Comando de shell. Su salida se dibuja en el dashboard.";
    height = int 10 "Alto de la sección, en líneas.";
    width = nullInt null "Ancho de la sección (null: el ancho del dashboard).";
    ttl = int 3600 "Segundos que snacks guarda la salida en caché. Se ignora si animated es true.";
    random = nullInt null "Si se pone N, snacks elige una de N salidas cacheadas en cada arranque.";
    animated = bool false "Programa que se anima: no se cachea y queda vivo.";
    title = nullStr null "Título encima de la sección.";
    packages = packagesOpt;
  };

  headerKinds = {
    milli = {
      splash = str "blackhole" "Splash de milli: uno incluido, uno del registro o \"random\".";
      loop = bool true "Repetir la animación.";
      splashFile =
        opt (types.nullOr types.path) null
          "Archivo .lua de splash propio (generado con la CLI de milli).";
    };
    shader = {
      name = opt (types.enum [
        "rain"
        "plasma"
        "doomfire"
        "starfield"
      ]) "doomfire" "Shader de milli.";
      fps = int 30 "Cuadros por segundo.";
      height = int 14 "Alto del shader, en líneas.";
    };
    text = {
      text = str "krapp.vim" "Arte fijo (ASCII). Cero costo: no corre nada.";
    };
    figlet = {
      text = str "krapp.vim" "Texto a dibujar.";
      font = str "slant" "Fuente de figlet.";
    };
    toilet = {
      text = str "krapp.vim" "Texto a dibujar.";
      font = str "future" "Fuente de toilet.";
      filter = nullStr "gay" "Filtro de color de toilet (gay, metal, border y otros).";
    };
    image = {
      path = pathOpt snowflake "Imagen (píxeles reales, protocolo kitty).";
      width = int 30 "Ancho en columnas.";
      height = int 15 "Alto en líneas.";
    };
    chafa = {
      path = pathOpt snowflake "Imagen a convertir en caracteres.";
      width = int 60 "Ancho en columnas.";
      height = int 17 "Alto en líneas.";
      symbols = str "vhalf" "Conjunto de símbolos de chafa (vhalf, block, braille y otros).";
    };
    hour = {
      night = str "toilet -f smblock --gay 'buenas noches'" "Comando antes de las 6.";
      morning = str "toilet -f smblock --metal 'buen dia'" "Comando de 6 a 13.";
      afternoon = str "toilet -f smblock -F border 'buenas tardes'" "Comando desde las 13.";
      height = int 4 "Alto de la sección, en líneas.";
    };
    cmd = cmdOptions;
    none = { };
  };

  panelKinds = {
    pokemon = {
      random = nullInt 10 "Cantidad de pokémon distintos que rotan entre arranques.";
      height = int 30 "Alto, en líneas.";
    };
    krabby = {
      random = nullInt 10 "Cantidad de pokémon distintos que rotan entre arranques.";
      height = int 30 "Alto, en líneas.";
    };
    fastfetch = {
      modules = str "Title:OS:Kernel:Uptime:Packages:Terminal:Memory" "Módulos de fastfetch (flag -s).";
      logo = str "nixos_small" "Logo de fastfetch.";
      height = int 10 "Alto, en líneas.";
    };
    github = {
      sections =
        opt
          (types.listOf (
            types.enum [
              "commits"
              "issues"
              "prs"
              "diff"
            ]
          ))
          [
            "commits"
            "issues"
            "prs"
            "diff"
          ]
          "Qué mostrar del repo. Solo aparece dentro de un repo de git.";
      limit = int 3 "Cantidad de issues y PRs.";
    };
    git = {
      height = int 5 "Alto, en líneas.";
    };
    colorscript = {
      name = str "square" "Script de dwt1-shell-color-scripts.";
      height = int 5 "Alto, en líneas.";
    };
    fortune = {
      cow = bool true "Pasar la frase por cowsay.";
      short = bool true "Solo frases cortas.";
      height = int 10 "Alto, en líneas.";
    };
    cbonsai = {
      live = bool true "Ver crecer el árbol (animado).";
      height = int 22 "Alto, en líneas.";
    };
    aquarium = {
      height = int 20 "Alto, en líneas.";
      width = int 100 "Ancho, en columnas.";
    };
    cmatrix = {
      height = int 14 "Alto, en líneas.";
      width = int 70 "Ancho, en columnas.";
      color = str "cyan" "Color de cmatrix.";
    };
    lolcat = {
      text = str "krapp.vim" "Texto a dibujar con figlet.";
      font = str "slant" "Fuente de figlet.";
      height = int 7 "Alto, en líneas.";
    };
    recent = {
      limit = nullInt 8 "Cantidad de archivos.";
    };
    projects = {
      limit = nullInt 5 "Cantidad de proyectos.";
    };
    cmd = cmdOptions;
  };

  # Un kind más un attrset de parámetros por cada kind posible.
  pieceType =
    kinds: default:
    types.submodule {
      options = {
        kind = mkOption {
          type = types.enum (builtins.attrNames kinds);
          inherit default;
          description = "Tipo de pieza.";
        };
      }
      // builtins.mapAttrs (_: sub) kinds;
    };

  panelType = types.coercedTo types.str (kind: { inherit kind; }) (pieceType panelKinds "cmd");

  keyType = types.submodule {
    options = {
      key = str "" "Tecla.";
      desc = str "" "Texto que se muestra.";
      action = str "" "Comando de Vim (empieza con `:`).";
      icon = str " " "Ícono a la izquierda.";
    };
  };
in
{
  inherit headerKinds panelKinds;
  options = {
    preset = mkOption {
      type = types.enum [
        "blackhole"
        "doom"
        "pokemon"
        "chafa"
        "startify"
        "advanced"
        "github"
        "compact"
        "image"
        "fastfetch"
        "bonsai"
        "aquarium"
        "calm"
        "ministarter"
      ];
      default = "blackhole";
      description = "Punto de partida. Solo pone valores por defecto: lo que escribas gana.";
    };
    style = mkOption {
      type = types.enum [
        "default"
        "startify"
        "compact"
        "calm"
      ];
      default = "default";
      description = "Cómo se dibujan las teclas y las listas (títulos, formato de teclas).";
    };
    title = nullStr "── krapp.vim ──" "Título debajo del header (null lo saca).";
    keys = mkOption {
      type = types.listOf keyType;
      description = "Teclas del dashboard ([ ] las saca).";
      default = [
        {
          key = "f";
          desc = "Find File";
          action = ":lua Snacks.picker.smart()";
        }
        {
          key = "n";
          desc = "New File";
          action = ":ene | startinsert";
        }
        {
          key = "g";
          desc = "Grep";
          action = ":lua Snacks.picker.grep()";
        }
        {
          key = "r";
          desc = "Recent Files";
          action = ":lua Snacks.picker.recent()";
        }
        {
          key = "q";
          desc = "Quit";
          action = ":qa";
        }
      ];
    };
    recent = sub {
      enable = bool true "Archivos recientes debajo de las teclas.";
      limit = nullInt null "Cantidad (null: el default de snacks).";
      cwd = bool false "Solo los del directorio actual.";
    };
    projects = sub {
      enable = bool false "Proyectos recientes debajo de las teclas.";
      limit = nullInt null "Cantidad (null: el default de snacks).";
    };
    layout = mkOption {
      type = types.enum [
        "auto"
        "one"
        "two"
      ];
      default = "auto";
      description = "auto: dos columnas si hay panel y la terminal tiene 130 columnas o más.";
    };
    header = mkOption {
      type = pieceType headerKinds "milli";
      default = { };
      description = "La pieza de arriba.";
    };
    panel = mkOption {
      type = types.listOf panelType;
      default = [ ];
      description = "Piezas del costado (o debajo, en una columna). En orden.";
    };
    overlay.drop = sub {
      enable = bool false "Cosas que caen sobre el dashboard (drop.nvim).";
      theme = str "auto" "Tema de drop.nvim (auto, leaves, snow, xmas y otros).";
      screensaver =
        opt (types.either types.bool types.int) false
          "Segundos sin tocar nada para que drop tape la pantalla (false: nunca).";
    };
    footer = sub {
      startup = bool false "Línea \"kvim listo en N ms\".";
      version = bool true "Versión de Neovim.";
      text = nullStr null "Texto propio al pie.";
    };
    extraSections = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = "Secciones crudas de snacks (tablas Lua), antes del pie. Salida de emergencia.";
    };
    extras = {
      screensaver = sub {
        enable = bool false "Protector de pantalla de milli.";
        shader = nullStr "doomfire" "Shader a mostrar (o null para usar splash).";
        splash = nullStr null "Splash a mostrar en vez de un shader.";
        after = int 300 "Segundos de inactividad.";
      };
      cellularAutomaton = sub {
        enable = bool false "Tecla de broma que derrite el buffer (cellular-automaton.nvim).";
        keymap = str "<leader>ur" "Tecla.";
      };
    };
  };
}
