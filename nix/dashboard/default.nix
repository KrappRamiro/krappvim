# Dashboard de kvim configurable desde Nix. Se usa así:
#
#   krappvim.packages.${system}.default.wrap {
#     settings.dashboard.preset = "pokemon";
#   }
#
# La guía con cada opción está en docs/dashboard/README.md.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  defs = import ./options.nix { inherit lib pkgs; };
  presets = import ./presets.nix { inherit lib pkgs; };

  # Pone lib.mkDefault en cada hoja del preset (no en el attrset entero):
  # si el preset dice header = { kind = "figlet"; } y el usuario solo cambia
  # header.figlet.font, el kind del preset se mantiene. Las listas (panel,
  # keys, packages) se reemplazan enteras.
  mkDefaults =
    v:
    if builtins.isAttrs v && !lib.isDerivation v then
      builtins.mapAttrs (_: mkDefaults) v
    else
      lib.mkDefault v;

  # Parámetros de una pieza tal como los ve Lua: las rutas pasan a texto
  # (quedan copiadas al store) y los paquetes no viajan.
  clean =
    params:
    lib.mapAttrs (_: v: if builtins.isPath v then "${v}" else v) (removeAttrs params [ "packages" ]);

  # Lo que llega a Lua: solo los parámetros del kind activo de cada pieza.
  resolve =
    d:
    let
      hk = d.header.kind;
      headerParams = d.header.${hk};
    in
    removeAttrs d [
      "header"
      "panel"
    ]
    // {
      header = {
        kind = hk;
      }
      // lib.optionalAttrs (headerParams != { }) { ${hk} = clean headerParams; };
      panel = map (p: clean p.${p.kind} // { inherit (p) kind; }) d.panel;
      # Las funciones no llegan a Lua (nix-wrapper-modules las filtra al
      # escribir settings), así que sirven para pasarle datos solo a Nix.
      nixOnly = _: {
        packages = (headerParams.packages or [ ]) ++ lib.concatMap (p: p.${p.kind}.packages or [ ]) d.panel;
      };
    };

  dash = config.settings.dashboard;
in
{
  options.settings.dashboard = lib.mkOption {
    description = "Qué dashboard muestra kvim al arrancar.";
    default = { };
    apply = resolve;
    type = lib.types.submodule (
      { config, ... }:
      {
        inherit (defs) options;
        # Cada preset es un mkIf: sus valores aplican solo si está elegido.
        config = lib.mkMerge (
          lib.mapAttrsToList (name: p: lib.mkIf (config.preset == name) (mkDefaults p)) presets
        );
      }
    );
  };

  options.dashboard.internal = lib.mkOption {
    readOnly = true;
    internal = true;
    type = lib.types.raw;
    description = "Datos derivados de settings.dashboard para gatear dependencias.";
    default = rec {
      kinds = [ dash.header.kind ] ++ map (p: p.kind) dash.panel;
      usesKind = kind: builtins.elem kind kinds;
      inherit (dash.nixOnly null) packages;
    };
  };
}
