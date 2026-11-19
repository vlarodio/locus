# locus

[English](README.md) | [Русский](README.ru.md)

Докер-песочница.

## Требования

- Linux;
- Docker с Compose (`docker compose` или `docker-compose`);
- `bash`, `sha256sum`;
- `make` — опционально.

## Быстрый старт

```bash
git clone <repo-url> locus
cd locus
make run
```

## Имена и несколько клонов

`LOCUS_ID` — 12 символов sha256 от абсолютного пути песочницы. От него зависят:

- проект: `locus-<id>`;
- образ: `locus-<id>:uid-<uid>`;
- том: `locus-data-<id>`.

Разные клоны песочницы имеют разные имена и не конфликтуют. У каждого клона свой том, авторизация и сессии в каждом клоне отдельные.

## Как устроено

- `/mounts` — каталог, в котором появляются каталоги хоста. Каждый `make mount DIR=...` монтируется в `/mounts/<имя каталога>`. `make run` запускает tmux в `/mounts`.
- `/home/locus` — отдельный Docker-том. Внутри авторизация, сессии, кэш и история shell.
- Корневая файловая система контейнера только для чтения. Запись разрешена в смонтированные каталоги, `/tmp` и том `/home/locus`.
- Контейнер работает от UID/GID текущего пользователя, не от root.
- Образ пересобирается при изменении `Dockerfile`, `entrypoint.sh`, `tmux.conf`, `bashrc` или UID/GID.

## Дополнительные каталоги

```bash
make mount DIR=~/src/foo   # появится как /mounts/foo
make mounts
make umount DIR=~/src/foo
```

Каталог монтируется внутрь песочницы как `/mounts/<имя каталога>`. `make mount`/`make umount` перезапускают песочницу: tmux завершается, auth и сессии в томе сохраняются. Список хранится в `.locus/mounts`; системные пути вроде `/etc` и `/usr` запрещены.

## Документы

Инструменты для PDF и DOCX: `poppler-utils` (`pdftotext`, `pdfinfo`, `pdftoppm`), `qpdf`, `pandoc` и `tesseract-ocr` (`rus+eng`).

```bash
pdftotext -layout file.pdf -              # PDF -> текст
pandoc notes.md -o notes.docx             # Markdown -> DOCX
pdftoppm -png -r 300 scan.pdf /tmp/page   # скан -> картинки для OCR
tesseract /tmp/page-1.png stdout -l rus+eng
```

`pandoc` создаёт DOCX, но не PDF (нет LaTeX).

## Изоляция и ограничения

Что не монтируется в контейнер:

- `$HOME`, `/`, `.ssh`, `.config`;
- другие проекты;
- `docker.sock`.

Дополнительно: `cap_drop: ALL`, `no-new-privileges`, read-only rootfs, отдельное PID-пространство и `tmpfs` для `/tmp`.

### Секреты и `.env`

`opencode.json` (`/etc/locus/opencode.json`) через `OPENCODE_CONFIG_CONTENT` требует подтверждения (`ask`) для `read`/`edit`/`bash` с `.env*`, `.envrc`, `secrets.*`, `credentials.*`, `*.pem`, `*.key`, `*id_rsa*`, `*id_ed25519*`, `.npmrc`, `.netrc`, `.git-credentials`. Шаблоны `.env.example` и подобные разрешены, `grep` не ограничен. Глобальный конфиг в томе перезаписывается при старте.

`--auto` и «always» одобряют `ask`, `bash`/`grep` обходятся. Надёжно скрыть секреты можно только не монтируя их в контейнер.

Ограничения:

- **Сеть не ограничена.** Она нужна для API модели, но allowlist/egress-фильтра нет.
- **Docker делит ядро с хостом.** Агент видит ресурсы Docker-хоста через `/proc/meminfo`, `/proc/cpuinfo` и `/sys`, а также может определить, что сам Docker-хост запущен в виртуальной машине.
