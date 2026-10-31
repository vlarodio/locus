SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
COMPOSE := $(ROOT)/bin/locus-compose
RUN := $(ROOT)/locus

.PHONY: help run ps logs down reset id config compose

help:
	@printf '%s\n' \
		'make run                  start the sandbox' \
		'make ps                   show sandbox containers' \
		'make logs                 logs' \
		'make down                 stop and remove the container, keep the volume' \
		'make reset                remove the container and volume (auth/sessions)' \
		'make id                   show project, image, and volume names' \
		'make config               show the resulting compose config' \
		'make compose ARGS="..."   pass a command to docker compose'

run:
	"$(RUN)"

ps:
	"$(COMPOSE)" ps

logs:
	"$(COMPOSE)" logs -f

down:
	"$(COMPOSE)" down --remove-orphans

reset:
	@read -r -p 'Remove the container and the volume with auth/sessions? [y/N] ' answer; \
	case "$$answer" in \
		[yY]|[yY][eE][sS]) ;; \
		*) echo 'Cancelled.'; exit 1 ;; \
	esac; \
	"$(COMPOSE)" down --remove-orphans -v

id:
	"$(COMPOSE)" id

config:
	"$(COMPOSE)" config

compose:
	@test -n "$(ARGS)" || { echo 'Specify ARGS, e.g.: make compose ARGS="ps"'; exit 1; }
	"$(COMPOSE)" $(ARGS)
