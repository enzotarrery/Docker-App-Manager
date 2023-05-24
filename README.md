# DOCUMENTATION

This manager uses **3 docker images**:

1. [PHP (FPM) 8.2.4](https://hub.docker.com/_/php)
2. [MariaDB 10.9.5](https://hub.docker.com/_/mariadb)
3. [Apache2](https://hub.docker.com/_/httpd)

## Usage guides

- [Linux](./docs/LINUX.md)
- [MacOS](./docs/MACOS.md)
- [Windows](./docs/WINDOWS.md)

## Commands

These commands are provided by a **Makefile**.

### First time? Build the containers

```sh
make build
```

### Launch the manager

```sh
make up
```

### Stop the manager

```sh
make down
```

### Create an app

```sh
make app-create type=[Symfony, Laravel] app_name
```

**Warning:** respect the format for the app name.

For other commands, type

```sh
make help
```
