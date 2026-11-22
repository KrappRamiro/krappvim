# Presets: los ejemplos de la galería como valores por defecto de una línea.
# `default.nix` los aplica con lib.mkDefault hoja por hoja, así lo que el
# usuario escribe siempre gana y puede cambiar una sola pieza de un preset.
{ lib, pkgs }:
let
  figlet = {
    kind = "figlet";
  };
  # Header grande, sin título ni versión, con el tiempo de arranque al pie.
  bare = {
    title = null;
    recent.enable = false;
    footer = {
      startup = true;
      version = false;
    };
  };
  # `//` reemplazaría el attrset `footer` entero; recursiveUpdate mezcla.
  over = lib.recursiveUpdate bare;
in
{
  # Lo de siempre: blackhole de milli, título, teclas, recientes, versión.
  blackhole = { };

  doom = over {
    header = figlet;
  };

  pokemon = over {
    header = figlet;
    panel = [
      {
        kind = "pokemon";
        pokemon.random = 10;
      }
    ];
    layout = "two";
  };

  chafa = over {
    header.kind = "chafa";
  };

  startify = over {
    style = "startify";
    header = {
      kind = "cmd";
      cmd = {
        cmd = "fortune -s | cowsay";
        height = 12;
        packages = [
          pkgs.fortune
          pkgs.cowsay
        ];
      };
    };
    recent = {
      enable = true;
      limit = 8;
    };
    projects.enable = true;
    footer.startup = false;
  };

  advanced = over {
    header = figlet;
    layout = "two";
    panel = [
      "colorscript"
      "recent"
      "projects"
      "git"
    ];
  };

  github = over {
    header = figlet;
    layout = "two";
    panel = [
      "colorscript"
      "github"
    ];
  };

  compact = over {
    style = "compact";
    header = figlet;
    recent.enable = true;
    projects.enable = true;
  };

  image = over {
    header.kind = "image";
    title = "── krapp.vim ──";
  };

  fastfetch = over {
    header = figlet;
    layout = "one";
    panel = [ "fastfetch" ];
  };

  bonsai = over {
    header.kind = "none";
    title = " krapp.vim";
    layout = "two";
    panel = [ "cbonsai" ];
  };

  aquarium = over {
    header.kind = "none";
    layout = "one";
    panel = [ "aquarium" ];
    footer.startup = false;
  };

  # Una sola línea, en calma: la fecha, una frase corta y las teclas.
  calm = over {
    style = "calm";
    header.kind = "none";
    layout = "one";
    panel = [
      {
        kind = "fortune";
        fortune = {
          cow = false;
          height = 2;
        };
      }
    ];
    footer.startup = false;
  };

  # mini.starter en vez de snacks: Lua lo detecta por el nombre del preset.
  ministarter = over {
    header.kind = "none";
  };
}
