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
    baseIndex = 1;
    escapeTime = 0;
    focusEvents = true;

    extraConfig = ''
      set -as terminal-features ",foot*:RGB"
      set -g renumber-windows on
      setw -g automatic-rename on
      set -g set-titles on
      set -g set-titles-string "#{pane_title}"

      set -g status-position bottom
      set -g status-justify left
      set -g status-style "bg=${c.bg},fg=${c.fg}"
      set -g status-left-length 30
      set -g status-left "#[fg=${c.green}]#{session_name}  "
      set -g status-right "#{?client_prefix,#[fg=${c.yellow}]prefix ,}#{?#{SSH_CONNECTION},#[fg=${c.dim}]#{host_short} ,}"
      setw -g window-status-format "#[fg=${c.dim}]#{window_index} #{window_name}"
      setw -g window-status-current-format "#[fg=${c.fg}]#{window_index} #{window_name}"
      setw -g window-status-separator "  "

      set -g pane-border-lines single
      set -g pane-border-style "fg=${c.surface}"
      set -g pane-active-border-style "fg=${c.green}"
      set -g message-style "bg=${c.bgAlt},fg=${c.fg}"
      set -g message-command-style "bg=${c.bgAlt},fg=${c.fg}"
      set -g mode-style "bg=${c.surface},fg=${c.fg}"
      setw -g clock-mode-colour "${c.green}"
    '';
  };
}
