SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
COMPOSE := $(ROOT)/bin/locus-compose
RUN := $(ROOT)/locus

.PHONY: help run ps logs down reset id config compose

help:
	@printf '%s\n' \
		'make run                  запустить песочницу' \
		'make ps                   показать контейнеры песочницы' \
		'make logs                 логи' \
		'make down                 остановить и удалить контейнер, том сохранить' \
		'make reset                удалить контейнер и том (авторизация/сессии)' \
		'make id                   показать имена проекта, образа и тома' \
		'make config               показать итоговый compose-конфиг' \
		'make compose ARGS="..."   передать команду в docker compose'

run:
	"$(RUN)"

ps:
	"$(COMPOSE)" ps

logs:
	"$(COMPOSE)" logs -f

down:
	"$(COMPOSE)" down --remove-orphans

reset:
	@read -r -p 'Удалить контейнер и том с авторизацией/сессиями? [y/N] ' answer; \
	case "$$answer" in \
		[yY]|[yY][eE][sS]) ;; \
		*) echo 'Отменено.'; exit 1 ;; \
	esac; \
	"$(COMPOSE)" down --remove-orphans -v

id:
	"$(COMPOSE)" id

config:
	"$(COMPOSE)" config

compose:
	@test -n "$(ARGS)" || { echo 'Укажи ARGS, например: make compose ARGS="ps"'; exit 1; }
	"$(COMPOSE)" $(ARGS)
