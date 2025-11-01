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
      set mouse="!"
      set magic
      set hidden
      set notimeout
      set autoindent
      set encoding=utf-8
      set clipboard=unnamedplus

      " File
      set autoread
      set noswapfile
      set undofile

      " Ui
      set number
      set relativenumber
      set nowrap
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
