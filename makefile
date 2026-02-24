.PHONY: rebuild

ifeq ($(shell uname), Darwin)
rebuild:
	sudo darwin-rebuild switch --flake .#laptop --impure
else
rebuild:
	sudo nixos-rebuild switch --flake .#nixos --impure
endif
