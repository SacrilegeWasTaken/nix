{ pkgs, ... }:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "gruvbox";

      editor = {
        line-number = "relative";
        bufferline = "multiple";
        color-modes = true;
        rulers = [ 100 ];
        completion-replace = true;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides.render = true;

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
