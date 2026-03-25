# Docker Compose Configuration for OpenWebUI and Ollama Access Proxy

This repository contains the configuration files for deploying an OpenWebUI application along with an Ollama access proxy using Docker Compose. The setup includes three services: `nginx`, `ollama-access-proxy`, and `openwebui`. Below is a detailed description of each component and how to set up and run the project.

## Directory Structure

```
.
├── docker-compose.yml
├── ollama-access.conf
└── inbound.conf
```

## Docker Compose Configuration (`docker-compose.yml`)

The `docker-compose.yml` file defines the services, networks, and volumes required for the application to run. The services include:

- **nginx**: Acts as a reverse proxy for routing requests to `openwebui` and handling WebSocket connections.
- **ollama-access-proxy**: Another Nginx service that forwards requests from openwebui to the host running the Ollama server on port 11434.
- **openwebui**: The main application served by Nginx, accessible via `http://localhost:80`.

### Networks

The configuration uses two networks:

- **services**: A bridge network with a subnet of `10.0.1.0/24` for internal communication between services.
- **dmz**: Another bridge network with a subnet of `10.0.0.0/24` for accessing services from the DMZ.

### Services

- **nginx**:
  - Ports: Exposes port 80 to the host, allowing access via `http://localhost:80`.
  - Networks: Assigned IP addresses in both the `services` and `dmz` networks.
  - Volumes: Mounts `inbound.conf` for Nginx configuration.

- **ollama-access-proxy**:
  - Networks: Assigned IP addresses in both the `services` and `dmz` networks.
  - Volumes: Mounts `ollama-access.conf` for Nginx configuration.

- **openwebui**:
  - Ports: No external ports exposed; accessible via Nginx reverse proxy.
  - Network: Assigned an IP address in the `services` network.
  - Volumes: Binds a persistent volume for backend data and sets environment variables for OpenWebUI configuration.

## Nginx Configuration Files

### ollama-access.conf

This file configures Nginx to act as an access proxy for Ollama. It listens on port 11434 and forwards requests to the host running the Ollama server.

```nginx
server {
    listen       11434;

    location / {
        proxy_pass http://host.docker.internal:11434;
    }

    location /api {
        proxy_pass http://host.docker.internal:11434;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 24h;
        proxy_send_timeout 24h;
        proxy_connect_timeout 10s;
        proxy_buffering off;
        proxy_buffer_size 4k;
        proxy_socket_keepalive on;
    }
}
```

### inbound.conf

This file configures Nginx to reverse proxy requests to the `openwebui` service. It listens on port 80 and handles WebSocket connections.

```nginx
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    
        proxy_pass http://openwebui:8080;
    }

    location /ws {
        proxy_pass http://openwebui:8080;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 24h;
        proxy_send_timeout 24h;
        proxy_connect_timeout 10s;
        proxy_buffering off;
        proxy_buffer_size 4k;
        proxy_socket_keepalive on;
    }
}
```

## Running the Project

To start the project, navigate to the root directory of this repository and run:

```sh
docker-compose up -d
```

This command will download the necessary images, build the services if needed, and start them in detached mode.

To access OpenWebUI, open a web browser and go to `http://localhost:80`. To interact with Ollama, you can use the proxy running on port 11434.

## Stopping the Project

To stop the project, run:

```sh
docker-compose down
```

This command will shut down all services and remove the associated containers.