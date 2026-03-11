

ifeq ($(shell uname), Darwin)
.PHONY: rebuild
rebuild:
	sudo darwin-rebuild switch --flake .#laptop --impure

update-taps:
	nix flake update sacrilegewastaken-tap
	nix flake update nikitabobko-tap

remove-undeclarative-taps:
	rm -rf /usr/local/Homebrew/Library/Taps
	rm -rf /opt/homebrew/Library/Taps

else
.PHONY: rebuild rebuild-vm
rebuild:
	sudo nixos-rebuild switch --flake .#nixos --impure

rebuild-vm:
	sudo nixos-rebuild switch --flake .#nix-vm --impure
endif
