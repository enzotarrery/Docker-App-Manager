include .env
export

SHELL = /bin/sh

UID = $(shell id -u)

COMMANDS := app dump rename delete
