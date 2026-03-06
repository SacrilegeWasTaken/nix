{ lib, pkgs, ... }:

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
      { mode = "n"; key = "<leader>ft"; action = "<cmd>Ex<cr>"; options.desc = "Open file explorer"; }
      { mode = "n"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "i"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find files"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live grep"; }
    ];
    extraPlugins = [
      pkgs.vimPlugins.toggleterm-nvim
    ];
    extraConfigLua = ''
      require("toggleterm").setup{
        open_mapping = [[<leader>t]],
        direction = "float",
        float_opts = {
          border = "rounded",
        },
      }
    '';
    plugins = {
      treesitter.enable = true;
      lsp = {
        enable = true;
        servers = {
          nixd.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
          clangd = {
            enable = true;
            package = pkgs.clang-tools;
          };
        };
      };
      telescope.enable = true;
      cmp = {
        enable = true;
        settings = {
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>"     = "cmp.mapping.close()";
            "<CR>"      = "cmp.mapping.confirm({ select = true })";
            "<Tab>"     = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>"   = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
        };
      };
      gitsigns.enable = true;
      lualine.enable = true;
      nvim-tree.enable = true;
      web-devicons.enable = true;
    };
    colorschemes.catppuccin.enable = true;
  };
}
