{ pkgs, ... }:

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
      guifont = "JetBrainsMono Nerd Font:h12";
      scrolloff = 8;
      updatetime = 50;
      colorcolumn = "";
    };

    globals.mapleader = " ";

    keymaps = [
      { mode = "n"; key = "<leader>e"; action = "<cmd>NvimTreeToggle<cr>"; options.desc = "Toggle file tree"; }
      { mode = "n"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "i"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find files"; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live grep"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope git_files<cr>"; options.desc = "Git files"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>"; options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope find_files hidden=true<cr>"; options.desc = "Find hidden files"; }
      { mode = "n"; key = "<leader>gl"; action = "<cmd>Telescope diagnostics<cr>"; options.desc = "Diagnostics list"; }
      { mode = "n"; key = "<leader>tf"; action = "<cmd>rightbelow vsplit<cr>"; options.desc = "Vertical split"; }
      { mode = "n"; key = "<leader>te"; action = "<cmd>rightbelow vsplit | terminal<cr>"; options.desc = "Vertical split / Terminal"; }
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Focus window left"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Focus window down"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Focus window up"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Focus window right"; }
      { mode = "n"; key = "<C-->"; action = "<C-w><lt>"; options.desc = "Narrower split (no Shift)"; }
      { mode = "n"; key = "<C-=>"; action = "<C-w>>"; options.desc = "Wider split (no Shift)"; }
      { mode = "v"; key = "<C-c>"; action = "\"+y"; options.desc = "Copy selection to system clipboard"; }
      { mode = "n"; key = "<C-c>"; action = "\"+yy"; options.desc = "Copy line to system clipboard"; }
    ];

    extraPlugins = [
      pkgs.vimPlugins.ultimate-autopair-nvim
      pkgs.vimPlugins.smear-cursor-nvim
      pkgs.vimPlugins.toggleterm-nvim
    ];

    extraConfigLua = ''
      require("ultimate-autopair").setup({})
      require("smear_cursor").setup({
        stiffness = 0.8,
        trailing_stiffness = 0.6,
        stiffness_insert_mode = 0.7,
        trailing_stiffness_insert_mode = 0.7,
        damping = 0.95,
        damping_insert_mode = 0.95,
        distance_stop_animating = 0.5,
        time_interval = 7,
        legacy_computing_symbols_support = true,
        hide_target_hack = true,
      })
      require("toggleterm").setup({
        open_mapping = [[<leader>ft]],
        direction = "float",
        float_opts = {
          border = "rounded",
        },
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>k', vim.diagnostic.open_float, opts)
        end,
      })
    '';

    plugins = {
      treesitter = {
        enable = true;
        settings = {
          ensure_installed = [
            "c"
            "cpp"
            "python"
            "zig"
            "rust"
            "haskell"
            "swift"
            "vim"
            "vimdoc"
            "query"
          ];
          highlight.enable = true;
          indent.enable = true;
          auto_install = true;
        };
      };

      lsp = {
        enable = true;
        servers = {
          nixd.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
          zls = {
            enable = true;
            package = pkgs.zls;
            cmd = [ "${pkgs.zls}/bin/zls" ];
          };
          hls = {
            enable = true;
            installGhc = false;
          };
          clangd = {
            enable = true;
            package = pkgs.clang-tools;
          };
          sourcekit = {
            enable = true;
            package = pkgs.sourcekit-lsp;
            cmd = [ "${pkgs.sourcekit-lsp}/bin/sourcekit-lsp" ];
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
    colorschemes.tokyonight = {
      enable = true;
      settings.style = "night";
    };
  };
}
