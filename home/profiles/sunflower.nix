{
  imports = [
    ../features/cli/gpg.nix
    ../features/cli/git.nix
    ../features/cli/nvim.nix
    ../features/cli/bash.nix
    ../features/cli/tmux.nix

    ../features/misc/xdg.nix
  ];

  # TMP: neovim suck tbh but it work
  programs.neovim.extraConfig = ''
    let g:clipboard = {
      \   'name': 'WslClipboard',
      \   'copy': {
      \      '+': 'clip.exe',
      \      '*': 'clip.exe',
      \    },
      \   'paste': {
      \      '+': 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      \      '*': 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      \   },
      \   'cache_enabled': 0,
      \ }
  '';
}
