{
  programs = {
    eza.enable = true;

    bash = {
      enable = true;
      shellAliases = {
        l = "eza --git -s type";
        ls = "l -l";
        la = "l -la";
        tree = "l --tree";
        grep = "grep --color";

        dev = "cd $HOME/documents/dev";
      };
    };
  };
}
