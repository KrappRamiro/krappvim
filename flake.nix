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
                nixfmt --check flake.nix module.nix
                # statix lee statix.toml (ahí está la regla que apagamos y por qué)
                statix check .
                deadnix --fail flake.nix module.nix
                touch $out
              '';
          # arranca kvim headless y carga los plugins lazy (scripts/smoke.lua)
          smoke =
            pkgs.runCommand "krappvim-smoke"
              {
                nativeBuildInputs = [
                  kvim
                  pkgs.git
                ];
              }
              ''
                export HOME=$TMPDIR
                kvim --headless -c "luafile ${self}/scripts/smoke.lua"
                touch $out
              '';
        }
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
