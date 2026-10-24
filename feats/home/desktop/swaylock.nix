{ lib, outputs, ... }:

let
  c = lib.mapAttrs (_: lib.removePrefix "#") outputs.palette.colors;
in {
  programs.swaylock = {
    enable = true;

    settings = {
      daemonize = true;
      ignore-empty-password = true;
      show-failed-attempts = true;

      font = "Fantasque Sans Mono";
      font-size = 18;
      indicator-radius = 80;
      indicator-thickness = 6;

      color = c.bg;

      inside-color = c.bg;
      inside-clear-color = c.bg;
      inside-ver-color = c.bg;
      inside-wrong-color = c.bg;

      ring-color = c.surface;
      ring-clear-color = c.dim;
      ring-ver-color = c.yellow;
      ring-wrong-color = c.red;

      key-hl-color = c.green;
      bs-hl-color = c.red;

      line-color = "00000000";
      line-clear-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";
      separator-color = "00000000";

      text-color = c.fg;
      text-clear-color = c.dim;
      text-ver-color = c.yellow;
      text-wrong-color = c.red;
    };
  };
}
