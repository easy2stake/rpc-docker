# RPC Docker

This project provides Dockerized environments for running various RPC nodes. Each RPC configuration resides in its own dedicated directory.

## Setup

To set up and run an RPC node:

1.  **Navigate to the RPC directory**: Change into the directory of the desired RPC (e.g., `sonic`, `ftm`).

    ```bash
    cd sonic/
    ```

2.  **Environment Variables**: Copy the `env.template` file to `.env` and configure it according to your needs.

    ```bash
    cp env.template .env
    ```

3.  **Build and Run**: Use Docker Compose to build and run the RPC node. The `--build` flag is important for the initial setup to ensure the Docker image is created.

    ```bash
    docker-compose up --build -d
    ```

    *Example (Sonic node):*

    ```bash
    cd sonic/
    cp env.template .env
    docker-compose up --build -d
    ```

## Configuration

Each RPC directory (e.g., `sonic/`, `ftm/`) contains its own `env.template` file, which lists the available configuration options for that specific RPC node.

## Stopping the Node

To stop a running RPC node, navigate to its respective directory and run:

```bash
docker-compose down
```

    *Example (Sonic node):*

    ```bash
    cd sonic/
    docker-compose down
    ```
