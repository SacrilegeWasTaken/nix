{ lib, ... }:

{
  config = {
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      wrap = false;
      swapfile = false;
      backup = false;
      undofile = true;
      hlsearch = true;
      incsearch = true;
      termguicolors = true;
      scrolloff = 8;
      updatetime = 50;
      colorcolumn = "80";
    };
    globals.mapleader = " ";
    keymaps = [
      { mode = "n"; key = "<leader>pv"; action = "<cmd>Ex<cr>"; options.desc = "Open file explorer"; }
      { mode = "n"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "i"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find files"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live grep"; }
    ];
    plugins = {
      treesitter.enable = true;
      lsp = {
        enable = true;
        servers = {
          nixd.enable = true;
          rust_analyzer = { enable = true; installCargo = false; installRustc = false; };
        };
      };
      telescope.enable = true;
      cmp = {
        enable = true;
        settings.sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
      gitsigns.enable = true;
      lualine.enable = true;
      nvim-tree.enable = true;
      web-devicons.enable = true;
    };
    colorschemes.catppuccin.enable = true;
  };
}
