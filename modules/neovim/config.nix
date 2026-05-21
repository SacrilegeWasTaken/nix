{ pkgs, lib, ... }:

let
  ruLangmap = lib.concatStringsSep "," [
    "йq" "цw" "уe" "кr" "еt" "нy" "гu" "шi" "щo" "зp" "х[" "ъ]"
    "фa" "ыs" "вd" "аf" "пg" "рh" "оj" "лk" "дl" "ж\\;" "э\\'"
    "яч" "xc" "сc" "мv" "иb" "тn" "ьm" "б\\," "ю."
    "ЙQ" "ЦW" "УE" "КR" "ЕT" "НY" "ГU" "ШI" "ЩO" "ЗP" "Х[" "Ъ]"
    "ФA" "ЫS" "ВD" "АF" "ПG" "РH" "ОJ" "ЛK" "ДL" "Ж\\:" "Э\\\""
    "ЯZ" "ЧX" "СC" "МV" "ИB" "ТN" "ЬM" "Б\\," "Ю."
    "%$" "\\,^" "\\;*"
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
      updatetime = 250;
      colorcolumn = "";
      # Иначе Esc и CSI (Ctrl+стрелки) разъезжаются — в буфер попадает [1;5D…
      timeout = true;
      ttimeout = true;
      ttimeoutlen = 300;
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

      -- Ctrl+стрелки → переключение окон. Через original_set, минуя langmapper.
      do
        local okm = require("langmapper").original_set
        local keys = { "<C-Left>", "<C-Right>", "<C-Up>", "<C-Down>" }
        local dirs = { "h", "l", "k", "j" }
        for i = 1, 4 do
          local d = dirs[i]
          local rhs = function()
            vim.cmd("wincmd " .. d)
          end
          okm({ "n", "v", "x" }, keys[i], rhs, { noremap = true })
          okm("i", keys[i], rhs, { noremap = true })
          okm("t", keys[i], rhs, { noremap = true })
        end
      end

      -- vim-surround: кириллические дубликаты <Plug>-маппингов.
      -- langmapper.automapping не всегда корректно дублирует <Plug>
      -- в visual mode (особенно xmap-only), поэтому ставим вручную.
      do
        local okm = require("langmapper").original_set
        -- Visual: Ы → S (обернуть выделение)
        okm("x", "Ы", "<Plug>VSurround",  { remap = true, silent = true })
        okm("x", "ПЫ", "<Plug>VgSurround", { remap = true, silent = true })
        -- Normal: вы → ds, сы → cs, ны → ys, нн → yss
        okm("n", "вы",  "<Plug>Dsurround",     { remap = true, silent = true })
        okm("n", "сы",  "<Plug>Csurround",     { remap = true, silent = true })
        okm("n", "ны",  "<Plug>Ysurround",     { remap = true, silent = true })
        okm("n", "нН",  "<Plug>YSurround",     { remap = true, silent = true })
        okm("n", "нн",  "<Plug>Yssurround",    { remap = true, silent = true })
        okm("n", "ННН", "<Plug>YSsurround",    { remap = true, silent = true })
      end
    '';

    autoCmd = [
      {
        event = "FileType";
        pattern = [ "c" "nix" "yaml" "json" "toml" "html" "css" "javascript" "typescript" "lua" "vim" "vimdoc" "query" ];
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
      { mode = "n"; key = "<leader>gb"; action = "<cmd>Gitsigns toggle_current_line_blame<cr>"; options.desc = "Toggle inline git blame (current line)"; }
      { mode = "n"; key = "<leader>td"; action = "<cmd>Telescope diagnostics<cr>"; options.desc = "Diagnostics list"; }
      { mode = "n"; key = "<leader>tf"; action = "<cmd>rightbelow vsplit<cr>"; options.desc = "Vertical split"; }
      { mode = "n"; key = "<leader>tF"; action = "<cmd>leftabove vsplit<cr>"; options.desc = "Vertical split left"; }
      { mode = "n"; key = "<leader>te"; action = "<cmd>rightbelow vsplit | terminal<cr>"; options.desc = "Vertical split / Terminal"; }
      { mode = "n"; key = "<leader>tE"; action = "<cmd>rightbelow split | terminal<cr>"; options.desc = "Horizontal split / Terminal"; }
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
      pkgs.vimPlugins.vim-surround
      pkgs.vimPlugins.ultimate-autopair-nvim
      pkgs.vimPlugins.smear-cursor-nvim
      pkgs.vimPlugins.toggleterm-nvim
      # vim.ui.select → Telescope (замена удалённого builtin.lsp_code_actions)
      pkgs.vimPlugins.telescope-ui-select-nvim
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

      vim.schedule(function()
        pcall(function()
          require("telescope").setup({
            extensions = {
              ["ui-select"] = {
                require("telescope.themes").get_dropdown({
                  previewer = false,
                  winblend = 10,
                }),
              },
            },
          })
          require("telescope").load_extension("ui-select")
        end)
      end)

      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        signs = true,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "if_many",
          focusable = false,
        },
      })

      vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
          vim.diagnostic.open_float(nil, { scope = "cursor" })
        end,
      })

      if vim.fn.has("nvim-0.11") == 1 then
        vim.o.winborder = "rounded"
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          end
          local opts = { buffer = event.buf }
          vim.keymap.set('n', 'gh', function()
            vim.lsp.buf.hover({ border = "rounded" })
          end, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'gs', function()
            vim.lsp.buf.signature_help({ border = "rounded" })
          end, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          -- Code actions через vim.ui.select → telescope-ui-select (см. telescope.schedule выше)
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', function()
            vim.lsp.buf.code_action({ border = "rounded" })
          end, vim.tbl_extend('force', opts, { desc = 'LSP code actions (quick fixes)' }))
          vim.keymap.set('n', '<leader>k', vim.diagnostic.open_float, opts)
          vim.keymap.set('n', '<leader>th', function()
            local filter = { bufnr = event.buf }
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
          end, vim.tbl_extend('force', opts, { desc = 'Toggle inlay hints' }))
        end,
      })

      -- Rust: специальные :RustLsp экшены через rustaceanvim.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "<leader>Rr", function() vim.cmd.RustLsp("runnables") end,
            vim.tbl_extend("force", opts, { desc = "Rust: runnables" }))
          vim.keymap.set("n", "<leader>Rd", function() vim.cmd.RustLsp("debuggables") end,
            vim.tbl_extend("force", opts, { desc = "Rust: debuggables" }))
          vim.keymap.set("n", "<leader>Rm", function() vim.cmd.RustLsp("expandMacro") end,
            vim.tbl_extend("force", opts, { desc = "Rust: expand macro" }))
          vim.keymap.set("n", "<leader>Re", function() vim.cmd.RustLsp("explainError") end,
            vim.tbl_extend("force", opts, { desc = "Rust: explain error" }))
          vim.keymap.set("n", "<leader>Ro", function() vim.cmd.RustLsp("openCargo") end,
            vim.tbl_extend("force", opts, { desc = "Rust: open Cargo.toml" }))
          vim.keymap.set("n", "<leader>Rp", function() vim.cmd.RustLsp("parentModule") end,
            vim.tbl_extend("force", opts, { desc = "Rust: parent module" }))
          vim.keymap.set("n", "<leader>Rh", function() vim.cmd.RustLsp({ "hover", "actions" }) end,
            vim.tbl_extend("force", opts, { desc = "Rust: hover actions" }))
          vim.keymap.set("n", "<leader>RR", function() vim.cmd.RustLsp("renderDiagnostic") end,
            vim.tbl_extend("force", opts, { desc = "Rust: render diagnostic" }))
        end,
      })

      -- Format-on-save для Rust через rust-analyzer/rustfmt.
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.rs",
        callback = function()
          vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
        end,
      })

      -- crates.nvim: подсказки и экшены в Cargo.toml.
      vim.api.nvim_create_autocmd("BufRead", {
        pattern = "Cargo.toml",
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "<leader>Ct", function() require("crates").toggle() end,
            vim.tbl_extend("force", opts, { desc = "Crates: toggle UI" }))
          vim.keymap.set("n", "<leader>Cu", function() require("crates").update_crate() end,
            vim.tbl_extend("force", opts, { desc = "Crates: update crate" }))
          vim.keymap.set("n", "<leader>CU", function() require("crates").upgrade_all_crates() end,
            vim.tbl_extend("force", opts, { desc = "Crates: upgrade all" }))
          vim.keymap.set("n", "<leader>Cv", function() require("crates").show_versions_popup() end,
            vim.tbl_extend("force", opts, { desc = "Crates: versions popup" }))
          vim.keymap.set("n", "<leader>Cf", function() require("crates").show_features_popup() end,
            vim.tbl_extend("force", opts, { desc = "Crates: features popup" }))
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
            "ron"
            "toml"
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
          taplo.enable = true;
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

      rustaceanvim = {
        enable = true;
        settings = {
          server = {
            default_settings = {
              rust-analyzer = {
                cargo = {
                  allFeatures = true;
                  loadOutDirsFromCheck = true;
                  buildScripts.enable = true;
                };
                check.command = "clippy";
                checkOnSave = true;
                procMacro = {
                  enable = true;
                  ignored.leptos_macro = [ "server" ];
                };
                diagnostics.experimental.enable = true;
                imports = {
                  granularity.group = "module";
                  prefix = "self";
                };
                inlayHints = {
                  bindingModeHints.enable = false;
                  chainingHints.enable = true;
                  closingBraceHints = {
                    enable = true;
                    minLines = 25;
                  };
                  closureReturnTypeHints.enable = "never";
                  lifetimeElisionHints = {
                    enable = "skip_trivial";
                    useParameterNames = false;
                  };
                  maxLength = 25;
                  parameterHints.enable = true;
                  reborrowHints.enable = "never";
                  renderColons = true;
                  typeHints = {
                    enable = true;
                    hideClosureInitialization = false;
                    hideNamedConstructor = false;
                  };
                };
                lens = {
                  enable = true;
                  references = {
                    adt.enable = true;
                    enumVariant.enable = true;
                    method.enable = true;
                    trait.enable = true;
                  };
                };
                completion = {
                  callable.snippets = "fill_arguments";
                  postfix.enable = true;
                };
                hover.actions = {
                  enable = true;
                  references.enable = true;
                };
              };
            };
          };
          tools = {
            float_win_config = {
              border = "rounded";
            };
            hover_actions = {
              replace_builtin_hover = false;
            };
          };
        };
      };

      crates = {
        enable = true;
        settings = {
          autoload = true;
          autoupdate = true;
          autoupdate_throttle = 250;
          loading_indicator = true;
          search_indicator = true;
          smart_insert = true;
          enable_update_available_warning = true;
          completion = {
            cmp.enabled = true;
            crates = {
              enabled = true;
              max_results = 8;
              min_chars = 3;
            };
          };
          lsp = {
            enabled = true;
            actions = true;
            completion = true;
            hover = true;
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
            { name = "crates"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
        };
      };
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 300;
          };
        };
      };
      lualine.enable = true;
      nvim-tree.enable = true;
      web-devicons.enable = true;
    };
    colorschemes.tokyonight = {
      enable = true;
      settings = {
        style = "night";
        transparent = true;
        styles = {
          sidebars = "transparent";
          floats = "transparent";
        };
      };
    };
  };
}
