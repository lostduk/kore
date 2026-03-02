{
  imports = [
    ../features/cli/gpg.nix
    ../features/cli/ssh.nix
    ../features/cli/git.nix
    ../features/cli/nvim.nix
    ../features/cli/bash.nix
    ../features/cli/tmux.nix
    ../features/cli/opencode.nix

    ../features/misc/xdg.nix

    ../features/wayland/dwl.nix
    ../features/wayland/foot.nix
  ];
}
