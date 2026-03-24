

AGE_KEY_DIR  := $(HOME)/.config/sops/age
AGE_KEY_FILE := $(AGE_KEY_DIR)/keys.txt
SOPS_YAML    := .sops.yaml
SECRETS_FILE := secrets/default.yaml

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

# ---- SOPS / age (uses nix shell so it works before rebuild) ----
NIX_SOPS := nix shell nixpkgs\#sops nixpkgs\#age -c
.PHONY: sops-init sops-edit

sops-init:
	@mkdir -p $(AGE_KEY_DIR)
	@if [ -f $(AGE_KEY_FILE) ]; then \
		echo "Age key already exists at $(AGE_KEY_FILE)"; \
	else \
		$(NIX_SOPS) age-keygen -o $(AGE_KEY_FILE); \
		chmod 600 $(AGE_KEY_FILE); \
		echo "Created age key at $(AGE_KEY_FILE)"; \
	fi
	@PUB=$$($(NIX_SOPS) age-keygen -y $(AGE_KEY_FILE)); \
	echo ""; \
	echo "Public key: $$PUB"; \
	echo ""; \
	echo "Paste it into .sops.yaml replacing the placeholder:"; \
	echo "  age1XXXX... -> $$PUB"; \
	echo ""; \
	if [ ! -f $(SECRETS_FILE) ]; then \
		echo "Creating initial secrets file..."; \
		mkdir -p secrets; \
		echo "tavily-api-key: tvly-REPLACE_ME" > $(SECRETS_FILE); \
		SOPS_AGE_KEY_FILE=$(AGE_KEY_FILE) $(NIX_SOPS) sops --encrypt --in-place $(SECRETS_FILE); \
		echo "Created $(SECRETS_FILE) (encrypted). Run 'make sops-edit' to set real values."; \
	fi

sops-edit:
	SOPS_AGE_KEY_FILE=$(AGE_KEY_FILE) $(NIX_SOPS) sops $(SECRETS_FILE)
