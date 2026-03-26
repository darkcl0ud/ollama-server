# Root makefile that delegates
# This allows building from the project root

# Default target
all:
	$(MAKE) -C cloudflare all
	$(MAKE) -C docker all

# Clean built artifacts
clean:
	$(MAKE) -C docker clean
	$(MAKE) -C cloudflare clean

# Stop running services
stop:
	$(MAKE) -C docker stop

# Show help
help:
	@echo "Available targets:"
	@echo "  all          - Build all infrastructure and services"
	@echo "  clean        - Remove build artifacts"
	@echo "  stop         - Stop running services"
	@echo "  help         - Show this help message"