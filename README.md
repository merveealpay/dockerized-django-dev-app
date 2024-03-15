# PyEditorial Project Setup

This repository contains the PyEditorial project, which uses Python, pip, and JavaScript.

## Setup Development Environment

We have a bash script `setup_dev_env.sh` that sets up the development environment for you. It does the following:

1. Clones the PyEditorial project from GitHub.
2. Updates the requirements in the `Dockerfile` and `requirements.txt`.
3. Adds `gunicorn` to `requirements.txt`.
4. Creates directories for `certbot` configuration and validation.
5. Sets the necessary permissions for `certbot` directories.
6. Creates a `docker-compose.yml` file with services for the web application, PostgreSQL database, `certbot`, and `nginx`.
7. Creates an `nginx` configuration file.
8. Starts the services using Docker Compose.

### Prerequisites

- Docker
- Docker Compose
- Git
- Bash

### Usage

To use the script, navigate to the directory containing the script and run:

```bash
./setup_dev_env.sh
