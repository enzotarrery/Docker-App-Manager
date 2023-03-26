include .env
export

SHELL = /bin/sh

UID := $(shell id -u)
GID := $(shell id -g)

export UID
export GID

CURRENT_TIME := $(shell date '+%y%m%d%H%M')

COMMANDS := app-create app-delete app-rename database-create database-dump
ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(COMMANDS))

ifneq ("$(ARGS)", "")
  ARG1 := $(word 2, $(MAKECMDGOALS))
  ARG2 := $(word 3, $(MAKECMDGOALS))
  $(eval $(ARG1):;@:)
  $(eval $(ARG2):;@:)
endif

OS := $(shell uname)

DOCKER := UID=$(UID) $(DOCKER_COMPOSE)

.PHONY: build up down app-create app-rename app-delete database-dump bash-connect check prune list help 

.DEFAULT_GOAL := help

up: # Launches the app.s
ifeq ($(OS), Darwin)
	@docker volume create --name=app-sync
	@$(DOCKER) -f docker-compose-macos.yml up -d
	@UID=$(UID) docker-sync start
else
	@$(DOCKER) up -d
endif

	@sleep 5

down: # Shutdowns the app.s
ifeq ($(OS), Darwin)
	@$(DOCKER) down
	@UID=$(UID) docker-sync stop
else
	@$(DOCKER) down
endif

	@sleep 5

build: # Mounts the containers
	@$(DOCKER) build

list: # Lists the app.s
	@echo '------| SYMFONY APPS | ------'
	@grep -rnw --include=\*.conf './docker/httpd/vhosts' -e 'Symfony' | cut -d/ -f2 | cut -d. -f1

	@echo '------| LARAVEL APPS | ------'
	@grep -rnw --include=\*.conf './docker/httpd/vhosts' -e 'Laravel' | cut -d/ -f2 | cut -d. -f1

database-create: # Creates a database
ifdef ARG1
	@make up

	@echo "Creating the database..."
	@$(DOCKER) exec db mysql -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) -e "CREATE DATABASE $(ARG1)"

	@echo "Don't forget to precise the database url in your config file!"
else
	@echo "It seems something's missing! Did you precise the app name?"
endif

database-configure:
ifneq ($(and $(ARG2), $(DATABASE_URL)), "")
	@echo "Configuring database from .env.local..."
	@echo "DATABASE_URL=$(DATABASE_URL)" | sed -e "s/database_name/$(ARG2)/g" > $(APPS_PATH)/$(ARG2)/.env.local
else
	@echo "It seems something's missing! Did you precise both the app name and the database url in the .env.local file?"
endif

vhost-create:
ifdef ARG1
	@make down

	@echo "Creating the virtualhost..."
	@sed -E 's/xxxxxx/$(ARG2)/' ./docker/httpd/vhosts/symfony.conf.sample > ./docker/httpd/vhosts/$(ARG2).conf

	@make up
else
	@echo "It seems something's missing! Did you precise the app name?"
endif

app-create: # Creates an app
ifneq ($(and $(ARG1), $(ARG2)), "")
	@make up

	@echo "Creating a $(ARG1) app '$(ARG2)'!"

ifeq ($(ARG1), Symfony)
	@make database-create $(ARG2)

	@$(DOCKER) exec php composer create-project symfony/skeleton $(ARG2)

	@make database-configure

	@make vhost-create

	@printf "All done!\nTry checking:\t\t\033[1m\e[92mhttp://%b.localhost:8000\033[m\e[0m\n" $(ARG2)
else ifeq ($(ARG1), Laravel)
	@make database-create $(ARG2)

	@$(DOCKER) exec php composer create-project laravel/laravel $(ARG2)

	@make database-configure

	@make vhost-create

	@printf "All done!\nTry checking:\t\t\033[1m\e[92mhttp://%b.localhost:8000\033[m\e[0m\n" $(ARG2)
else ifeq ($(ARG1), React)
	@$(DOCKER) exec php npx create-react-app $(ARG2)
else ifeq ($(ARG1), Angular)
	@$(DOCKER) exec php ng new $(ARG2)
else
	@echo "Unknown app type: $(ARG1)."
endif

else 
	@echo "It seems something's missing! Did you precise both the app name and its type?"
endif

app-rename: # Renames an app
ifneq ($(and $(ARG1), $(ARG2)), "")
	@make up
	
	@echo "Renaming the database..."
	@$(DOCKER) exec db mysqldump -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) -R $(ARG1) > /tmp/$(ARG1)-dump.sql
	@$(DOCKER) exec db mysqladmin -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) create $(ARG2)
	@$(DOCKER) exec db mysqladmin -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) -R$(ARG1) < /tmp/$(ARG1)-dump.sql
	@$(DOCKER) exec db mysqladmin -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) drop $(ARG1)
	@$(DOCKER) exec db rm /tmp/$(ARG1)-dump.sql

	@echo "Renaming the app directory..."
	@mv $(APPS_PATH)/$(ARG1) $(APPS_PATH)/$(ARG2)

	@echo "Renaming the virtualhost"
	@mv ./docker/httpd/vhosts/$(ARG1).conf ./docker/httpd/vhosts/$(ARG2).conf

	@sed -i 's/$(ARG1)/$(ARG2)/' ./docker/httpd/vhosts/$(ARG2).conf
	@echo "Don't forget to change your config files for $(ARG2)!"
else 
	@echo "It seems something's missing! Did you precise both the current and new names?"
endif

app-delete: # Deltes an app
ifdef ARG1
	@make check

	@make up

	@echo "Deleting database for app $(ARG1)..."
	@$(DOCKER) exec db mysql -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) -e "DROP DATABASE IF EXISTS $(ARG1)"

	@make down
	
	@echo "Deleting directory $(ARG1)..."
	@rm -rf $(APPS_PATH)/$(ARG1)

	@echo "Deleting virtualhost..."
	@rm -f ./docker/httpd/vhosts/$(ARG1).conf

	@make up
else 
	@echo "It seems something's missing! Did you forget to add the app name?" 
endif

database-dump: # Dumps a database
ifdef ARG1
	@make up

	@echo "Dumping database for app $(ARG1)..."
	@$(DOCKER) exec db mysqldump -p$(MARIADB_PASSWORD) $(ARG1) > $(ARG1)-$(CURRENT_TIME).sql
	
	@echo "Dumping done!"
else
	@echo "It seems something's missing! Did you forget to add the app name?"
endif

bash-connect: # Opens PHP container bash
	@$(DOCKER) exec php bash

check:
	@(read -p "Are you sure? There's no recovery possible! [O/n]: " sure && case "$$sure" in [oO]) true;; *) false;; esac)

prune: check # Deletes all containers
	@$(DCOKER) system prune -a --volumes

help: # Displays all commands
	@grep --no-filename -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
