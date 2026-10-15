{ lib, outputs, ... }:

let
  c = lib.mapAttrs (_: lib.removePrefix "#") outputs.palette.colors;
in {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "Fantasque Sans Mono:size=11";
        line-height = "16px";
      };

      colors-dark = {
        foreground = c.fg;
        background = c.bg;
        cursor = "${c.bg} ${c.fg}";

        selection-foreground = c.fg;
        selection-background = c.surface;

        regular0 = c.bgAlt;
        regular1 = c.red;
        regular2 = c.green;
        regular3 = c.yellow;
        regular4 = c.blue;
        regular5 = c.magenta;
        regular6 = c.teal;
        regular7 = c.dim;

        bright0 = c.surface;
        bright1 = c.red;
        bright2 = c.green;
        bright3 = c.yellow;
        bright4 = c.blue;
        bright5 = c.magenta;
        bright6 = c.teal;
        bright7 = c.fg;
      };
    };
  };
}
