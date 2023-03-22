include .env
export

SHELL = /bin/sh

UID := $(shell id -u)
USERNAME := $(shell whoami)
export UID
export USERNAME

APPS_PATH := ./apps
CURRENT_TIME := $(shell date '+%y%m%d%H%M')

ifneq "$(MAKECMDGOALS)" ""
  ARG1 := $(word 2, $(MAKECMDGOALS))
  ARG2 := $(word 3, $(MAKECMDGOALS))
endif

OS := $(shell uname)

DOCKER := UID=$(UID) USERNAME=$(USERNAME) $(DOCKER_COMPOSE)

.PHONY: up down app-create app-rename app-delete build database-dump bash-connect check clean list help 

.DEFAULT_GOAL := help

up: # Launches the app.s
ifeq ($(OS), Darwin)
	@docker volume create --name=app-sync
	@$(DOCKER) -f docker-compose-macos.yml up -d
	@UID=$(UID) docker-sync start
else
	@$(DOCKER) up -d
endif

down: # Shutdowns the app.s
ifeq ($(OS), Darwin)
	@$(DOCKER) down
	@UID=$(UID) docker-sync stop
else
	@$(DOCKER) down
endif

build: # Mounts the containers
	@$(DOCKER) build

list: # Lists the app.s
	@echo '------| SYMFONY APPS | ------'
	@grep -rnw --include='\*.conf' './docker/httpd/vhosts' -e 'Symfony' | cut -d/ -f2 | cut -d. -f1

	@echo '------| LARAVEL APPS | ------'
	@grep -rnw --include='\*.conf' './docker/httpd/vhosts' -e 'Laravel' | cut -d/ -f2 | cut -d. -f1

rename: # Renames an app
ifneq ($(ARG1), $(ARG2))
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

pre-creation:
	@make up
	@sleep 5
	@echo "Creating the database..."
	@$(DOCKER) exec db mysql -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) -e "CREATE DATABASE $(ARG1)"

post-creation:
	@make up
	@printf "All done!\nTry checking:\t\t\033[1m\e[92mhttp://%b.localhost:8000\033[m\e[0m\n" $(ARG1)

app-create: # Creates an app
ifneq ($(ARG1), $(ARG2))
	@make pre-creation

	@echo "Creating $(ARG2) app $(ARG1)!"
	@$(DOCKER) exec php composer create-project symfony/skeleton $(ARG1)

	@echo "Configuring database from .env.local..."
	@echo $(DATABASE_URL) | @sed -i 's/database_url/$(ARG1)' > $(APPS_PATH)/$(ARG1)/.env.local

	@make down

	@echo "Creating the virtualhost..."
	@sed -E 's/xxxxxx/$(ARG1)/' ./docker/httpd/vhosts/symfony.conf.sample > ./docker/httpd/vhosts/$(ARG1).conf

	@make post-creation
else 
	@echo "It seems something's missing! Did you precise both the app name and its type?"
endif

app-delete: # Deltes an app
ifdef ARG1
	@make check

	@make up
	@sleep 5

	@echo "Deleting database for $(ARG1)..."
	@$(DOCKER) exec db mysql -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) -e "DROP DATABASE $(ARG1)"
	@make down
	
	@echo "Deleting directory $(ARG1)..."
	@rm -rf $(APP_PATH)/$(ARG1)

	@echo "Deleting virtualhost..."
	@rm -f  ./virtualhosts/$(NOM).conf

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

help: # Displays all commands
	@grep --no-filename -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
