# Lo que no se usa no entra al build: cada plugin o programa que una pieza
# del dashboard necesita vive en una spec cuyo `enable` depende de las
# piezas elegidas. `specCollect` (module.nix) junta los runtimePkgs solo de
# las specs habilitadas, así que pkgs.cbonsai entra solo si se eligió cbonsai.
inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  dash = config.settings.dashboard;
  inherit (config.dashboard.internal) usesKind packages;
  plugins = config.nvim-lib.neovimPlugins;

  # milli se carga si dibuja el header (splash o shader) o el protector de
  # pantalla.
  usesMilli = usesKind "milli" || usesKind "shader" || dash.extras.screensaver.enable;

  # Splashes que trae milli adentro (lua/milli/splashes/*.lua) y los del
  # registro. Se leen de los inputs, así un nombre mal escrito falla al
  # evaluar y la lista se actualiza sola con `nix flake update`.
  luaNames =
    dir:
    lib.pipe (builtins.readDir dir) [
      builtins.attrNames
      (builtins.filter (lib.hasSuffix ".lua"))
      (map (lib.removeSuffix ".lua"))
    ];
  bundled = luaNames "${inputs.plugins-milli}/lua/milli/splashes";
  registry = luaNames "${inputs.milli-splashes}/splashes";

  # Splashes del registro a copiar: el elegido, o todos con "random" (milli
  # elige entre los que encuentra en el runtimepath). Pesan unos 50 MB
  # juntos, por eso solo con random.
  wantedSplashes =
    let
      names = lib.filter (n: n != null) [
        (dash.header.milli.splash or null)
        dash.extras.screensaver.splash
      ];
      check =
        n:
        if builtins.elem n bundled || builtins.elem n registry || n == "random" then
          n
        else
          throw "settings.dashboard: el splash de milli \"${n}\" no existe. Hay: ${toString (bundled ++ registry)}";
      checked = map check names;
    in
    if builtins.elem "random" checked then
      registry
    else
      builtins.filter (n: builtins.elem n registry) checked;

  # Carpeta con forma de plugin: lua/milli/splashes/<name>.lua. Al estar en
  # el runtimepath, `require("milli.splashes.<name>")` la encuentra sin red.
  registryPlugin = pkgs.runCommand "milli-registry" { } ''
    mkdir -p $out/lua/milli/splashes
    ${lib.concatMapStrings (
      n: "cp ${inputs.milli-splashes}/splashes/${n}.lua $out/lua/milli/splashes/\n"
    ) wantedSplashes}
  '';

  # Programas por kind de pieza (header o panel).
  toolsByKind = with pkgs; {
    figlet = [ figlet ];
    toilet = [ toilet ];
    hour = [ toilet ];
    chafa = [ chafa ];
    pokemon = [ pokemon-colorscripts ];
    krabby = [ krabby ];
    fastfetch = [ fastfetch ];
    # git va al final del PATH: si el sistema tiene uno, gana ese
    github = [
      gh
      git
    ];
    git = [ git ];
    colorscript = [ dwt1-shell-color-scripts ];
    fortune = [
      fortune
      cowsay
    ];
    cbonsai = [ cbonsai ];
    aquarium = [ asciiquarium ];
    cmatrix = [ cmatrix ];
    lolcat = [
      figlet
      lolcat
    ];
  };
in
{
  config.specs = {
    dashboard-milli = {
      data = plugins.milli;
      lazy = true;
      enable = usesMilli;
    };
    dashboard-milli-registry = {
      data = registryPlugin;
      pname = "milli-registry";
      # Solo archivos en el runtimepath: no hay código que cargar tarde.
      lazy = false;
      enable = usesMilli && wantedSplashes != [ ];
    };
    dashboard-drop = {
      data = plugins.drop;
      lazy = true;
      enable = dash.overlay.drop.enable;
    };
    dashboard-cellular = {
      data = pkgs.vimPlugins.cellular-automaton-nvim;
      lazy = true;
      enable = dash.extras.cellularAutomaton.enable;
    };
    # Sin plugin: solo suma programas al PATH de kvim.
    dashboard-tools = {
      data = null;
      runtimePkgs =
        lib.concatLists (lib.mapAttrsToList (kind: ps: lib.optionals (usesKind kind) ps) toolsByKind)
        ++ packages;
    };
  };
}
