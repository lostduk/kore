{
  imports = [
    ../features/cli/gpg.nix
    ../features/cli/ssh.nix
    ../features/cli/git.nix
    ../features/cli/nvim.nix
    ../features/cli/bash.nix
    ../features/cli/tmux.nix
    ../features/cli/aerc.nix

    ../features/misc/xdg.nix
    ../features/misc/firefox.nix
    ../features/misc/vesktop.nix
    ../features/misc/gtk.nix

    ../features/wayland/dwl.nix
    ../features/wayland/foot.nix
    ../features/wayland/wbg.nix
    ../features/wayland/mako.nix
    ../features/wayland/swaylock.nix
    ../features/wayland/swayidle.nix

    ../features/secrets.nix
  ];
}
