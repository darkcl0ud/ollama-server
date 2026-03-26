# Cloudflare makefile
# Builds infrastructure in Cloudflare using OpenTofu

# Default target
all: build export

build:
	tofu init
	tofu apply

export:
	@echo "TUNNEL_TOKEN=$(shell tofu output -raw cf_tunnel_token)" > ../secrets/.env

# Clean built artifacts
clean:
	tofu init
	tofu destroy

# Show help
help:
	@echo "Available targets:"
	@echo "  all          - Build infrastructure in cloudflare"
	@echo "  clean        - Remove cloudflare infrastructure"
	@echo "  help         - Show this help message"