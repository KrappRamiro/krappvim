# Tests de evaluación de `settings.dashboard`: arman la config de kvim con
# distintas opciones (sin construir nada) y revisan lo que le llega a Lua.
# Si algo falla, el `throw` lista los nombres de los tests rotos. Si pasa,
# devuelve archivos que el check tiene que encontrar en el build.
{
  krappvim,
  lib,
  pkgs,
}:
let
  # `apply` reevalúa el módulo de kvim con un módulo extra y devuelve config
  eval =
    extra:
    krappvim.apply [
      { inherit pkgs; }
      extra
    ];
  dash = extra: (eval extra).settings.dashboard;

  base = dash { };
  pokemon = dash { settings.dashboard.preset = "pokemon"; };
  pokemonToilet = dash {
    settings.dashboard = {
      preset = "pokemon";
      header.kind = "toilet";
    };
  };
  image = dash {
    settings.dashboard.header = {
      kind = "image";
      image = { };
    };
  };
  # Config completa (specs, runtimePkgs), para ver qué entra al build
  noConfig = eval { };
  figletCfg = eval { settings.dashboard.header.kind = "figlet"; };
  bonsaiCfg = eval { settings.dashboard.panel = [ { kind = "cbonsai"; } ]; };
  auroraCfg = eval { settings.dashboard.header.milli.splash = "aurora"; };
  screensaverCfg = eval {
    settings.dashboard = {
      header.kind = "text";
      extras.screensaver.enable = true;
    };
  };
  # runtimePkgs guarda entradas DAG ({ data; name; ... }), no paquetes
  hasPkg = cfg: p: builtins.elem "${p}" (map (e: toString e.data) cfg.runtimePkgs);

  bad = builtins.tryEval (builtins.deepSeq (dash { settings.dashboard.header.kind = "nope"; }) true);

  tests = {
    default_header_milli = base.header.kind == "milli";
    default_splash_blackhole = base.header.milli.splash == "blackhole";
    default_loop = base.header.milli.loop;
    default_panel_empty = base.panel == [ ];
    default_title = base.title == "── krapp.vim ──";
    default_five_keys = builtins.length base.keys == 5;
    default_footer_version = base.footer.version;

    pokemon_header_figlet = pokemon.header.kind == "figlet";
    pokemon_figlet_text = pokemon.header.figlet.text == "krapp.vim";
    pokemon_panel =
      builtins.length pokemon.panel == 1
      && (builtins.head pokemon.panel).kind == "pokemon"
      && (builtins.head pokemon.panel).random == 10;
    pokemon_layout_two = pokemon.layout == "two";

    kind_change_drops_old_params = !(pokemonToilet.header ? figlet);
    kind_change_toilet_text = pokemonToilet.header.toilet.text == "krapp.vim";

    image_default_path = lib.hasPrefix "${pkgs.nixos-icons}/" image.header.image.path;

    bad_kind_fails = !bad.success;

    deps_default_no_cbonsai = !(hasPkg noConfig pkgs.cbonsai);
    deps_default_no_chafa = !(hasPkg noConfig pkgs.chafa);
    deps_default_no_drop = !noConfig.specs.dashboard-drop.enable;
    deps_default_milli = noConfig.specs.dashboard-milli.enable;
    deps_default_no_registry = !noConfig.specs.dashboard-milli-registry.enable;
    deps_figlet_no_milli = !figletCfg.specs.dashboard-milli.enable;
    deps_figlet_has_figlet = hasPkg figletCfg pkgs.figlet;
    deps_cbonsai = hasPkg bonsaiCfg pkgs.cbonsai;
    deps_aurora_registry = auroraCfg.specs.dashboard-milli-registry.enable;
    deps_screensaver_milli = screensaverCfg.specs.dashboard-milli.enable;
  };
  failed = builtins.attrNames (lib.filterAttrs (_: ok: !ok) tests);
in
if failed == [ ] then
  [ "${auroraCfg.specs.dashboard-milli-registry.data}/lua/milli/splashes/aurora.lua" ]
else
  throw "dashboard-eval: fallaron ${builtins.concatStringsSep ", " failed}"
