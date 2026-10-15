{ outputs, ... }:

let
  c = outputs.palette.colors;
in {
  programs.tmux = {
    enable = true;

    prefix = "C-x";
    terminal = "tmux-256color";
    keyMode = "vi";
    mouse = true;

    extraConfig = ''
      set -g status-style "bg=${c.bg},fg=${c.fg}"
      set -g window-status-style "fg=${c.dim}"
      set -g window-status-current-style "fg=${c.green}"
      set -g pane-border-style "fg=${c.surface}"
      set -g pane-active-border-style "fg=${c.green}"
      set -g message-style "bg=${c.bgAlt},fg=${c.fg}"
      set -g mode-style "bg=${c.surface},fg=${c.fg}"
    '';
  };
}
