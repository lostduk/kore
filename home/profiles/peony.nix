{
  imports = [
    ../features/cli/gpg.nix
    ../features/cli/ssh.nix
    ../features/cli/git.nix
    ../features/cli/nvim.nix
    ../features/cli/bash.nix
    ../features/cli/tmux.nix

    ../features/misc/xdg.nix
    ../features/misc/firefox.nix

    ../features/wayland/dwl.nix
    ../features/wayland/foot.nix
    ../features/wayland/wbg.nix

    ../features/secrets.nix
  ];
}
