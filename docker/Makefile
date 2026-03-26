# Docker makefile
# Builds infrastructure in Docker using compose

# Default target
all:
	docker-compose up -d

# Clean built artifacts
clean:
	docker-compose down -v

# Stop running services
stop:
	docker-compose down

# Show help
help:
	@echo "Available targets:"
	@echo "  all          - Compose docker"
	@echo "  clean        - Remove docker infrastructure"
	@echo "  stop         - Stop running services"
	@echo "  help         - Show this help message"