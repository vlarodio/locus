# locus

[English](README.md) | [Русский](README.ru.md)

Docker sandbox.

## Requirements

- Linux;
- Docker with Compose (`docker compose` or `docker-compose`);
- `bash`, `sha256sum`;
- `make` — optional.

## Quick start

```bash
git clone <repo-url> locus
cd locus
git clone <project-url> workspace
make run
```

## Names and multiple clones

`LOCUS_ID` is 12 characters of sha256 of the sandbox's absolute path. These depend on it:

- project: `locus-<id>`;
- image: `locus-<id>:uid-<uid>`;
- volume: `locus-data-<id>`.

Different sandbox clones get different names and do not conflict. Each clone has its own volume, and authorization and sessions are separate in each clone.

## How it works

- `workspace/` is the only host directory available to the container. Inside, it is visible as `/workspace`. If the directory does not exist, the script creates it at startup.
- `/home/locus` is a separate Docker volume. It contains authorization, sessions, cache, and shell history.
- The container's root filesystem is read-only. Writing is allowed to `workspace`, `/tmp`, and the `/home/locus` volume.
- The container runs as the current user's UID/GID, not as root.
- The image is rebuilt when `Dockerfile`, `entrypoint.sh`, `tmux.conf`, `bashrc`, or UID/GID change.

## Isolation and limitations

What is not mounted into the container:

- `$HOME`, `/`, `.ssh`, `.config`;
- other projects;
- `docker.sock`.

Additionally: `cap_drop: ALL`, `no-new-privileges`, read-only rootfs, a separate PID namespace, and `tmpfs` for `/tmp`.

### Secrets and `.env`

`opencode.json` (`/etc/locus/opencode.json`) uses `OPENCODE_CONFIG_CONTENT` to require approval (`ask`) for `read`/`edit`/`bash` with `.env*`, `.envrc`, `secrets.*`, `credentials.*`, `*.pem`, `*.key`, `*id_rsa*`, `*id_ed25519*`, `.npmrc`, `.netrc`, `.git-credentials`. Templates such as `.env.example` and similar are allowed, and `grep` is not restricted. The global config in the volume is overwritten at startup.

`--auto` and "always" approve `ask`, and `bash`/`grep` can be bypassed. The only reliable way to hide secrets is to not mount them into the container.

Limitations:

- **The network is not restricted.** It is needed for the model API, but there is no allowlist/egress filter.
- **Docker shares the kernel with the host.** The agent can see Docker host resources via `/proc/meminfo`, `/proc/cpuinfo`, and `/sys`, and can also determine that the Docker host itself runs in a virtual machine.
