# Ollama Server Infrastructure

A comprehensive infrastructure setup combining Cloudflare Zero Trust tunneling with Docker containerization to securely expose an OpenWebUI and Ollama API.

## Project Overview

This project provides:
- **Cloudflare Zero Trust Tunnel**: Secure, managed tunnel for accessing internal services without exposing public IP addresses
- **Docker Services**: OpenWebUI chat interface, Nginx reverse proxy, and Ollama access proxy
- **Network Security**: DMZ network isolation and controlled routing through Cloudflare

## Directory Structure

```
.
├── README.md                 # This file
├── Makefile                  # Root orchestration makefile
├── LICENSE                   # Project license
├── cloudflare/              # Cloudflare Zero Trust infrastructure (OpenTofu)
│   ├── Makefile
│   ├── main.tf              # Tunnel and route definitions
│   ├── variables.tf         # Cloudflare configuration variables
│   ├── terraform.tfvars     # Cloudflare account ID
│   ├── outputs.tf           # Outputs (e.g., tunnel token)
│   └── terraform.tfstate    # State file
├── docker/                  # Docker Compose services
│   ├── Makefile
│   ├── docker-compose.yml   # Service definitions
│   ├── inbound.conf         # Nginx reverse proxy config
│   └── ollama-access.conf   # Ollama proxy config
└── secrets/                 # Generated secrets and environment files
```

## Prerequisites

- Docker and Docker Compose
- OpenTofu (or Terraform)
- Cloudflare account with API token
- Access to Ollama running on the host machine (port 11434)

## Cloudflare Zero Trust Infrastructure

The `cloudflare/` directory contains OpenTofu configuration for setting up a secure tunnel:

### What It Does

- **Creates a Cloudflare Tunnel** named "ai-net" using Cloudflare Tunnel (Cloudflared)
- **Routes the DMZ network** (`10.0.0.0/24`) through the tunnel
- **Creates a hostname route** (`chat.internal`) for accessing the OpenWebUI

### Configuration Files

- `main.tf`: Defines the tunnel, route, and hostname mapping
- `variables.tf`: Cloudflare configuration variables
- `terraform.tfvars`: Cloudflare account ID (API token comes from environment variable)
- `outputs.tf`: Exports the tunnel token for use by other services

### Setup Instructions

1. Export your Cloudflare API token as an environment variable:
   ```sh
   export CLOUDFLARE_API_TOKEN="your_api_token"
   ```

2. Configure your Cloudflare account ID in `cloudflare/terraform.tfvars`:
   ```hcl
   cf_account_id = "your_account_id"
   ```

3. Deploy the infrastructure:
   ```sh
   make -C cloudflare all
   ```
   This will:
   - Initialize OpenTofu
   - Create the tunnel and routes in Cloudflare
   - Save the tunnel token to `secrets/.env`

### Cloudflare WARP Configuration

To ensure proper access through the tunnel, configure your Cloudflare WARP profiles:

1. **Remove Split Tunnel IP Ranges**: In your WARP profile settings, if you have split tunneling set to **exclude** mode, remove the following IP ranges:
   - `100.64.0.0/10` (Unique Local Addresses)
   - `10.0.0.0/8` (Private network range used by your tunnel)

2. **Remove Local Domain Fallback**: In the **Local Domain Fallback** settings, remove `.internal` from the list of local domains. For more details on hostname routing and domain configuration, see [Cloudflare's tunnel hostname routing guide](https://blog.cloudflare.com/tunnel-hostname-routing/).

These settings ensure traffic to your tunnel routes properly through Cloudflare's infrastructure rather than being split locally.

## Docker Compose Services

The `docker/` directory contains the containerized components that work together with the Cloudflare tunnel.

### Services Architecture

**Three services work together:**

- **nginx** (reverse proxy): Routes HTTP requests to OpenWebUI and handles WebSocket connections
- **ollama-access-proxy** (Ollama proxy): Forwards API requests from OpenWebUI to the Ollama server on the host (port 11434)
- **openwebui**: The chat interface application

### Networks

The Docker Compose setup uses three bridge networks:

- **level0** (`10.0.254.0/24`): Provides access to the host machine.
- **services** (`10.0.1.0/24`): Internal communication between services
- **dmz** (`10.0.0.0/24`): Exposed network routed through Cloudflare tunnel

## Nginx Configuration Files

Located in the `docker/` directory:

### inbound.conf
Reverse proxy that routes HTTP traffic to OpenWebUI on port 80. Handles WebSocket upgrades for real-time communication.

### ollama-access.conf
Proxy that forwards Ollama API requests from OpenWebUI to the host machine's Ollama server (port 11434). Includes special handling for streaming and WebSocket connections.

## Getting Started

### Quick Start (Docker only)

If you already have Cloudflare tunnel configured:

```sh
make -C docker all
```

### Full Setup (Cloudflare + Docker)

1. **Set up Cloudflare infrastructure:**
   ```sh
   make -C cloudflare all
   ```
   This creates the tunnel and saves the tunnel token to `secrets/.env`.

2. **Start Docker services:**
   ```sh
   make -C docker all
   ```
   This brings up all four services (nginx, ollama-access-proxy, openwebui, cloudflared).

### Using the Root Makefile

For convenience, use the root-level `Makefile` to orchestrate both components:

```sh
# Set up everything
make all

# Stop all services
make stop

# Remove all infrastructure and containers
make clean

# Show available commands
make help
```

## Accessing the Services

- **OpenWebUI**: Access through Cloudflare tunnel at `https://chat.internal` or locally at `http://localhost:80`
- **Ollama API**: Accessible to OpenWebUI through the proxy at `10.0.0.0/24:11434`
- **Local Testing**: Not available all connections happen through WARP

## Secrets Management

The `secrets/` directory stores generated environment variables and tokens:
- `secrets/.env`: Contains the Cloudflare tunnel token (generated by `make -C cloudflare all`)

Keep this directory secure and do not commit to version control.

## Architecture Overview

```
Internet (User)
    ↓
Cloudflare Zero Trust Tunnel (chat.internal)
    ↓
Cloudflare Tunnel Agent (Cloudflared)
    ↓
DMZ Network (10.0.0.0/24)
    ↓
Nginx Reverse Proxy (localhost:80)
    ├─→ OpenWebUI Service (internal)
    │
    └─→ Ollama Access Proxy (port 11434)
         ↓
    Host Machine Ollama Server (port 11434)
```

## Component Communication Flow

1. **User** connects through Cloudflare tunnel to `chat.internal`
2. **Cloudflare Tunnel** routes traffic to the DMZ network (`10.0.0.0/24`)
3. **Nginx Reverse Proxy** receives traffic and forwards to:
   - OpenWebUI for web interface requests
   - Ollama Access Proxy for API requests
4. **Ollama Access Proxy** forwards requests to the host machine's Ollama server
5. **OpenWebUI** interacts bidirectionally with Ollama through the proxy

## Troubleshooting

### Services won't start
- Ensure Docker and Docker Compose are properly installed
- Review Docker logs: `docker-compose logs` (from the `docker/` directory)

### Can't reach Ollama
- Verify Ollama is running on the host: `curl http://localhost:11434/api/tags`
- Check that OpenWebUI can resolve the host: `lsof -i :11434`
- Ensure the Docker daemon can reach the host (on macOS, may need `host.docker.internal`)

### Cloudflare tunnel not connecting
- Verify credentials in `cloudflare/terraform.tfvars`
- Check that the tunnel was created: `tofu show` (in `cloudflare/` directory)
- Review Cloudflare dashboard for tunnel status

## License

See [LICENSE](LICENSE) for licensing information.