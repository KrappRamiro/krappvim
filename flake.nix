{
  description = "Flake exporting a configured neovim package";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.wrappers.url = "github:BirdeeHub/nix-wrapper-modules";
  inputs.wrappers.inputs.nixpkgs.follows = "nixpkgs";
  # Demo on fetching plugins from outside nixpkgs
  inputs.plugins-lze = {
    url = "github:BirdeeHub/lze";
    flake = false;
  };
  # These 2 are already in nixpkgs, however this ensures you always fetch the most up to date version!
  inputs.plugins-lzextras = {
    url = "github:BirdeeHub/lzextras";
    flake = false;
  };

  # this one is not on nixpkgs
  inputs.plugins-tiny-inline-diagnostic = {
    url = "github:rachartier/tiny-inline-diagnostic.nvim";
    flake = false;
  };

  # milli.nvim — animated ASCII splash para el dashboard de snacks
  inputs.plugins-milli = {
    url = "github:Amansingh-afk/milli.nvim";
    flake = false;
  };

  # tiny-code-action.nvim — picker bonito + diff preview para LSP code actions
  inputs.plugins-tiny-code-action = {
    url = "github:rachartier/tiny-code-action.nvim";
    flake = false;
  };

  # mind.nvim — organizador de notas en árbol jerárquico
  inputs.plugins-mind = {
    url = "github:Selyss/mind.nvim";
    flake = false;
  };

  # drop.nvim: hojas, nieve y otras cosas que caen sobre el dashboard. No
  # está en nixpkgs. Solo entra al build si settings.dashboard lo pide.
  inputs.plugins-drop = {
    url = "github:folke/drop.nvim";
    flake = false;
  };

  # Registro de splashes de milli (aurora, flyingdragon y otros). milli los
  # baja con curl en runtime; acá los traemos en el build, sin red. No lleva
  # el prefijo plugins- porque no es un plugin: nix/dashboard/deps.nix copia
  # solo los splashes elegidos.
  inputs.milli-splashes = {
    url = "github:amansingh-afk/milli-splashes";
    flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      wrappers,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
      module = nixpkgs.lib.modules.importApply ./module.nix inputs;
      wrapper = wrappers.lib.evalModule module;
    in
    {
      overlays = {
        neovim = final: _prev: { neovim = wrapper.config.wrap { pkgs = final; }; };
        default = self.overlays.neovim;
      };
      wrapperModules = {
        neovim = module;
        default = self.wrapperModules.neovim;
      };
      wrappers = {
        neovim = wrapper.config;
        default = self.wrappers.neovim;
      };
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          neovim = wrapper.config.wrap { inherit pkgs; };
          default = self.packages.${system}.neovim;
        }
      );
      # `nix fmt` formatea los archivos nix
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
      # `nix flake check`: lo que tiene que pasar antes de cada commit.
      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          kvim = self.packages.${system}.neovim;
        in
        {
          # formato y lint de Lua y Nix
          lint =
            pkgs.runCommand "krappvim-lint"
              {
                nativeBuildInputs = [
                  pkgs.stylua
                  pkgs.selene
                  pkgs.nixfmt
                  pkgs.statix
                  pkgs.deadnix
                ];
              }
              ''
                cd ${self}
                stylua --check .
                selene init.lua lua scripts
                nixfmt --check flake.nix module.nix $(find nix tests -name "*.nix")
                # statix lee statix.toml (ahí está la regla que apagamos y por qué)
                statix check .
                deadnix --fail flake.nix module.nix nix tests
                touch $out
              '';
          # opciones de settings.dashboard: presets, kinds y lo que llega a Lua
          # (el test devuelve archivos que tienen que existir en el build)
          dashboard-eval =
            let
              files = import ./tests/dashboard-eval.nix {
                krappvim = self.wrappers.neovim;
                inherit (pkgs) lib;
                inherit pkgs;
              };
            in
            pkgs.runCommand "krappvim-dashboard-eval" { } ''
              for f in ${toString files}; do test -f "$f"; done
              touch $out
            '';
          # arranca kvim headless y carga los plugins lazy (scripts/smoke.lua)
          smoke =
            pkgs.runCommand "krappvim-smoke"
              {
                nativeBuildInputs = [
                  kvim
                  pkgs.git
                  # el test del dashboard arma un header figlet sobre el
                  # kvim por defecto, que no trae figlet
                  pkgs.figlet
                ];
              }
              ''
                export HOME=$TMPDIR
                kvim --headless -c "luafile ${self}/scripts/smoke.lua"
                kvim --headless -c "luafile ${self}/scripts/dashboard-test.lua"
                touch $out
              '';
        }
        # checks.dashboard-<preset>: kvim armado con cada preset arma su
        # dashboard sin error y tiene en el PATH cada programa que corre
        # (scripts/dashboard-check.lua). dashboard-extras prueba drop,
        # cellular-automaton, el protector de pantalla y un splash del
        # registro de milli, que ningún preset prende.
        // (
          let
            dashboardCheck =
              name: dashboard:
              let
                kvimWith = self.wrappers.neovim.wrap [
                  { inherit pkgs; }
                  { settings = { inherit dashboard; }; }
                ];
              in
              pkgs.runCommand "krappvim-dashboard-${name}" { nativeBuildInputs = [ kvimWith ]; } ''
                export HOME=$TMPDIR
                kvim --headless -c "luafile ${self}/scripts/dashboard-check.lua"
                touch $out
              '';
            presets = builtins.attrNames (
              import ./nix/dashboard/presets.nix {
                inherit (pkgs) lib;
                inherit pkgs;
              }
            );
          in
          builtins.listToAttrs (
            map (p: {
              name = "dashboard-${p}";
              value = dashboardCheck p { preset = p; };
            }) presets
          )
          // {
            # Cada bloque `nix` de docs/dashboard/README.md que empieza con
            # `settings.dashboard` tiene que evaluar: así la guía no queda
            # vieja cuando cambian las opciones. Solo se evalúa (drvPath),
            # no se arma un kvim por ejemplo. Las rutas de ejemplo de la
            # guía (./avatar.png) se cambian por archivos del repo.
            dashboard-docs =
              let
                inherit (pkgs) lib;
                guide = builtins.readFile ./docs/dashboard/README.md;
                blocks = map (b: builtins.head (lib.splitString "```" b)) (
                  builtins.tail (lib.splitString "```nix\n" guide)
                );
                snippets = builtins.filter (b: lib.hasPrefix "settings.dashboard" (lib.trim b)) (
                  map lib.trim blocks
                );
                fixtures =
                  builtins.replaceStrings
                    [ "./avatar.png" "./mi-splash.lua" ]
                    [ "${self}/docs/dashboard/media/doom.jpg" "${self}/scripts/fixtures/splash.lua" ];
                evalSnippet =
                  i: text:
                  let
                    snippet = import (builtins.toFile "dashboard-doc-${toString i}.nix" "pkgs: { ${fixtures text} }");
                  in
                  (kvim.wrap (snippet pkgs)).drvPath;
                drvs = lib.imap1 evalSnippet snippets;
              in
              assert lib.assertMsg (
                builtins.length snippets >= 15
              ) "dashboard-docs: se esperaban 15 ejemplos o más, hay ${toString (builtins.length snippets)}";
              pkgs.runCommand "krappvim-dashboard-docs" { } ''
                echo ${toString (map builtins.unsafeDiscardStringContext drvs)} > $out
              '';
            dashboard-extras = dashboardCheck "extras" {
              header.milli.splash = "aurora";
              overlay.drop = {
                enable = true;
                theme = "snow";
              };
              extras = {
                screensaver.enable = true;
                cellularAutomaton.enable = true;
              };
            };
          }
        )
      );
      # `wrappers.neovim.enable = true`
      nixosModules = {
        default = self.nixosModules.neovim;
        neovim = wrappers.lib.getInstallModule {
          name = "neovim";
          value = module;
        };
      };
      # `wrappers.neovim.enable = true`
      # You can set any of the options.
      # But that is how you enable it.
      homeModules = {
        default = self.homeModules.neovim;
        # el mismo módulo sirve para NixOS y para home-manager
        neovim = self.nixosModules.neovim;
      };
    };
}
