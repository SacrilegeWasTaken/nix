{ pkgs, ... }:

{
  programs.helix = {
    enable = true;

    # patches/helix-layout-remap.patch: adds a top-level `layout-remap`
    # config table translating national-layout characters to the keys
    # keybindings are defined with, at keymap-lookup time only. Both
    # layouts work, hints stay English, insert mode is unaffected.
    # (Upstream rejected this in helix-editor/helix#5046 in favor of a
    # future scriptable config, hence a local patch.)
    package = pkgs.helix.override {
      helix-unwrapped = pkgs.helix-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../../patches/helix-layout-remap.patch ];
      });
    };

    themes.base16_custom = {
      inherits = "base16_default";
      "ui.statusline" = { fg = "#d8d8d8"; bg = "#282828"; };
      "ui.statusline.inactive" = { fg = "#585858"; bg = "#282828"; };
      "ui.popup.info" = { fg = "#d8d8d8"; bg = "#282828"; };
      "ui.text.info" = { fg = "#d8d8d8"; bg = "#282828"; };
      "ui.menu" = { fg = "#d8d8d8"; bg = "#282828"; };
      "ui.menu.selected" = { fg = "#181818"; bg = "#7cafc2"; };
    };

    settings = {
      theme = "modus_vivendi";

      "layout-remap" = [
        {
          from = "йцукенгшщзхъфывапролджэячсмитьбюё";
          into = "qwertyuiop[]asdfghjkl;'zxcvbnm,.`";
        }
        {
          from = "ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ";
          into = "QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>~";
        }
      ];

      editor = {
        line-number = "relative";
        bufferline = "multiple";
        color-modes = true;
        rulers = [ 100 ];
        completion-replace = true;
        cursorline = true;
        popup-border = "all";
        trim-trailing-whitespace = true;
        insert-final-newline = true;
        soft-wrap.enable = true;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides.render = true;

        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "warning";

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        statusline = {
          left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
          right = [ "diagnostics" "selections" "position" "file-encoding" "file-type" ];
        };
      };

      keys.normal = {
        "X" = "extend_line_above";
        "C-h" = "jump_view_left";
        "C-j" = "jump_view_down";
        "C-k" = "jump_view_up";
        "C-l" = "jump_view_right";
      };
    };

    languages = {
      language-server.rust-analyzer.config = {
        check.command = "clippy";
        cargo.allFeatures = true;
        procMacro.enable = true;
        inlayHints = {
          bindingModeHints.enable = true;
          closingBraceHints.minLines = 10;
          closureReturnTypeHints.enable = "with_block";
          discriminantHints.enable = "fieldless";
          lifetimeElisionHints.enable = "skip_trivial";
          typeHints.hideClosureInitialization = false;
        };
      };

      language-server.clangd = {
        command = "clangd";
        args = [
          "--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--fallback-style=LLVM"
        ];
      };

      language = [
        {
          name = "rust";
          auto-format = true;
        }
        {
          name = "c";
          auto-format = true;
          language-servers = [ "clangd" ];
        }
        {
          name = "cpp";
          auto-format = true;
          language-servers = [ "clangd" ];
        }
        {
          name = "zig";
          auto-format = true;
        }
      ];
    };
  };
}
