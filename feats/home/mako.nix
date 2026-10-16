{ outputs, ... }:

let
  c = outputs.palette.colors;
in {
  services.mako = {
    enable = true;

    settings = {
      font = "Fantasque Sans Mono 11";
      anchor = "top-right";
      margin = "10";
      padding = "8,10";
      width = 360;
      border-size = 1;
      border-radius = 0;
      default-timeout = 5000;

      background-color = c.bg;
      text-color = c.fg;
      border-color = c.surface;
      progress-color = "over ${c.surface}";

      "urgency=low" = {
        text-color = c.dim;
      };

      "category=volume" = {
        default-timeout = 1500;
        progress-color = "over ${c.green}40";
      };

      "urgency=critical" = {
        border-color = c.red;
        default-timeout = 0;
      };
    };
  };
}
