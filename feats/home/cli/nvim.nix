{
  # TMP: neovim suck tbh but it work
  programs.neovim = {
    enable = true;

    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;

    # wtf
    withNodeJs = false;
    withRuby = false;
    withPython3 = false;

    extraConfig = ''
      "" Variables
      let mapleader="\<space>"

      "" Options
      " General
      set mouse=
      set notimeout
      set clipboard=unnamedplus

      " File
      set noswapfile
      set undofile

      " Ui
      set number
      set relativenumber
      set nowrap
      set notermguicolors
      set lazyredraw
      set cc=80

      "" Mapping
      " useless features tbh why have tab in (n)vim just use tmux or smth
      nnoremap <Esc> :noh<cr>
      nnoremap <Tab> :bnext<cr>
      nnoremap <S-Tab> :bprev<cr>
    '';
  };
}
