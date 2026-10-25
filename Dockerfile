FROM node:22-bookworm-slim

ARG OPENCODE_VERSION=1.19.3

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git ripgrep tmux \
 && rm -rf /var/lib/apt/lists/*

RUN npm install --global "opencode-ai@${OPENCODE_VERSION}" \
 && npm cache clean --force

ARG LOCUS_UID=1000
ARG LOCUS_GID=1000

RUN set -eux; \
    userdel --remove node 2>/dev/null || true; \
    groupdel node 2>/dev/null || true; \
    groupadd --gid "${LOCUS_GID}" locus; \
    useradd --create-home --uid "${LOCUS_UID}" --gid "${LOCUS_GID}" --shell /bin/bash locus; \
    mkdir -p /home/locus/.config/opencode /home/locus/.local/share /home/locus/.local/state /home/locus/.cache; \
    printf '%s\n' '{"autoupdate":false}' > /home/locus/.config/opencode/opencode.json; \
    chown -R locus:locus /home/locus; \
    chmod 0777 /home/locus /home/locus/.config /home/locus/.config/opencode /home/locus/.local /home/locus/.local/share /home/locus/.local/state /home/locus/.cache; \
    chmod 0644 /home/locus/.config/opencode/opencode.json

RUN git config --system --add safe.directory /workspace

COPY entrypoint.sh /usr/local/bin/locus-entrypoint
COPY bashrc /etc/locus/bashrc
COPY tmux.conf /etc/locus/tmux.conf
RUN chmod 0755 /usr/local/bin/locus-entrypoint

ARG BUILD_HASH=dev
LABEL org.locus.build-hash="${BUILD_HASH}"

ENV HOME=/home/locus \
    XDG_CONFIG_HOME=/home/locus/.config \
    XDG_DATA_HOME=/home/locus/.local/share \
    XDG_STATE_HOME=/home/locus/.local/state \
    XDG_CACHE_HOME=/home/locus/.cache

USER locus

ENTRYPOINT ["/usr/local/bin/locus-entrypoint"]
