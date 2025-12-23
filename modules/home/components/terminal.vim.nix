{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.vim;
in
{
  options.modules.home.terminal.vim = {
    enable = lib.mkEnableOption "vim packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        # Theme
        vim-monokai
        lightline-vim

        # General
        vim-multiple-cursors
        tabular
        vim-markdown
        # markdown-preview-nvim

        # Language
        vim-nix

        # Navigation
        nerdtree

        # Integration
        vim-gitgutter
        vim-fugitive
      ];
      settings = {
        expandtab = true;
        number = true;
        shiftwidth = 2;
        tabstop = 2;
      };
      extraConfig = ''
        " NerdTree Toggle
        map <C-o> :NERDTreeToggle<CR>

        " Status Bar Color Scheme
        let g:lightline = {
              \ 'colorscheme': 'seoul256',
              \ }

        " General Settings
        colorscheme monokai
        syntax on
        set laststatus=2
        set numberwidth=4
        set backspace=indent,eol,start
        set nofoldenable " Disable folding in the editor, may re-enable later

        " Enable spell checking by file type
        autocmd BufRead,BufNewFile *.md setlocal spell spelllang=en_us

        " Force proper colors (Disable Background Color Erase).
        set t_ut=
      '';
    };
  };
}
