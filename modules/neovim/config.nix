{ pkgs, lib, ... }:

let
  ruLangmap = lib.concatStringsSep "," [
    "йq" "цw" "уe" "кr" "еt" "нy" "гu" "шi" "щo" "зp" "х[" "ъ]"
    "фa" "ыs" "вd" "аf" "пg" "рh" "оj" "лk" "дl" "ж\\;" "э\\'"
    "яч" "xc" "сc" "мv" "иb" "тn" "ьm" "б\\," "ю."
    "ЙQ" "ЦW" "УE" "КR" "ЕT" "НY" "ГU" "ШI" "ЩO" "ЗP" "Х[" "Ъ]"
    "ФA" "ЫS" "ВD" "АF" "ПG" "РH" "ОJ" "ЛK" "ДL" "Ж\\:" "Э\\\""
    "ЯZ" "ЧX" "СC" "МV" "ИB" "ТN" "ЬM" "Б\\," "Ю."
  ];
in

{
  config = {
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 4;
      tabstop = 4;
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

    extraConfigLuaPre = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
      vim.opt.langmap = [=[${ruLangmap}]=]
      require("langmapper").setup({
        hack_keymap = true,
        map_all_ctrl = true,
        ctrl_map_modes = { "n", "o", "v", "x", "s", "i", "c", "t" },
        disable_hack_modes = { "i" },
        automapping_modes = { "n", "v", "x", "s", "o" },
      })
    '';

    extraConfigLuaPost = ''
      pcall(function()
        require("langmapper").automapping({ global = true, buffer = true })
      end)
    '';

    autoCmd = [
      {
        event = "FileType";
        pattern = [ "c" "nix" "yaml" "json" "html" "css" "javascript" "typescript" "lua" "vim" "vimdoc" "query" ];
        command = "setlocal tabstop=2 shiftwidth=2 expandtab";
      }
      {
        event = "FileType";
        pattern = [ "python" "cpp" "rust" "haskell" "swift" "zig" "julia"];
        command = "setlocal tabstop=4 shiftwidth=4 expandtab";
      }
      {
        event = "FileType";
        pattern = [ "go" "make" ];
        command = "setlocal tabstop=4 shiftwidth=4 noexpandtab";
      }
    ];

    keymaps = [
      { mode = "n"; key = "<leader>e"; action = "<cmd>NvimTreeToggle<cr>"; options.desc = "Toggle file tree"; }
      { mode = "n"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "i"; key = "<C-s>"; action = "<cmd>w<cr>"; options.desc = "Save file"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find files"; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope live_grep<cr>"; options.desc = "Live grep"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope git_files<cr>"; options.desc = "Git files"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>"; options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope find_files hidden=true<cr>"; options.desc = "Find hidden files"; }
      { mode = "n"; key = "<leader>td"; action = "<cmd>Telescope diagnostics<cr>"; options.desc = "Diagnostics list"; }
      { mode = "n"; key = "<leader>tf"; action = "<cmd>rightbelow vsplit<cr>"; options.desc = "Vertical split"; }
      { mode = "n"; key = "<leader>tF"; action = "<cmd>leftabove vsplit<cr>"; options.desc = "Vertical split left"; }
      { mode = "n"; key = "<leader>te"; action = "<cmd>rightbelow vsplit | terminal<cr>"; options.desc = "Vertical split / Terminal"; }
      { mode = "n"; key = "<leader>tE"; action = "<cmd>leftabove split | terminal<cr>"; options.desc = "Horizontal split / Terminal"; }
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
      pkgs.vimPlugins.langmapper-nvim
      pkgs.vimPlugins.plenary-nvim
      pkgs.vimPlugins.claude-code-nvim
      pkgs.vimPlugins.ultimate-autopair-nvim
      pkgs.vimPlugins.smear-cursor-nvim
      pkgs.vimPlugins.toggleterm-nvim
    ];

    extraConfigLua = ''
      require("claude-code").setup({
        command = "claude",
        window = {
          split_ratio = 0.3,
          position = "botright vsplit",
          enter_insert = true,
          hide_numbers = true,
          hide_signcolumn = true,
          float = {
            width = "80%",
            height = "80%",
            row = "center",
            col = "center",
            relative = "editor",
            border = "rounded",
          },
        },
        refresh = {
          enable = true,
          updatetime = 100,
          timer_interval = 1000,
          show_notifications = true,
        },
        git = {
          use_git_root = true,
        },
        shell = {
          separator = "&&",
          pushd_cmd = "pushd",
          popd_cmd = "popd",
        },
        command_variants = {
          continue = "--continue",
          resume = "--resume",
          verbose = "--verbose",
        },
        keymaps = {
          toggle = {
            normal = "<leader>cc",
            terminal = "<leader>cc",
            variants = {
              continue = "<leader>cC",
              verbose = "<leader>cV",
            },
          },
          window_navigation = true,
          scrolling = true,
        },
      })

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
