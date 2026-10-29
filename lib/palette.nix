let
  colors = {
    bg = "#181b1c";
    bgAlt = "#1f2627";
    surface = "#2f3d3e";
    dim = "#6c8a8a";
    fg = "#d5dcd2";

    red = "#c08a86";
    orange = "#b8b08e";
    yellow = "#cdbf8a";
    green = "#8fae92";
    teal = "#86aaa4";
    blue = "#86a2ac";
    magenta = "#abc3b4";
  };
in {
  inherit colors;
  hex = builtins.mapAttrs (_: c: builtins.substring 1 6 c) colors;

  ramp = {
    hedge = "#162920";
    slate = "#263e41";
    teal = "#3d575d";
    moss = "#4b684e";
    sage = "#7e9a81";
    lichen = "#98b19e";
    blossom = "#abc3b4";
    cream = "#d5dcd2";
  };
}
