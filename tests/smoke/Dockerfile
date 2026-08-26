# syntax=docker/dockerfile:1
# Dockerfile - isolated VS Code Remote - SSH smoke-test images.
#
# Inputs:
# - VSCODE_VERSION and REMOTE_SSH_VERSION pin the downloaded client software.
# - TARGETARCH selects the matching official VS Code Debian package.
#
# Side effects:
# - The client build downloads VS Code and the Remote - SSH extension.
# - Runtime state remains inside disposable Compose containers and volumes.
# - A test-local code wrapper disables Chromium's namespace sandbox because it
#   cannot initialize inside default Docker isolation; the container stays
#   non-root and receives no additional host capabilities.
#
# Related files:
# - tests/smoke/compose.yml
# - tests/smoke/client.sh
# - tests/smoke/server.sh

ARG DEBIAN_VERSION=bookworm-slim

FROM debian:${DEBIAN_VERSION} AS ssh-server

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        gzip \
        libstdc++6 \
        openssh-server \
        procps \
        tar \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /bin/bash smoke \
    && passwd --delete smoke \
    && install -d -m 0755 /run/sshd /workspace \
    && chown smoke:smoke /workspace \
    && rm -f /etc/ssh/ssh_host_*

COPY server.sh /usr/local/bin/cgenv-smoke-server
COPY --chown=smoke:smoke workspace/ /workspace/

RUN chmod 0755 /usr/local/bin/cgenv-smoke-server

EXPOSE 22

HEALTHCHECK --interval=2s --timeout=2s --start-period=5s --retries=30 \
    CMD pgrep --exact sshd >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/cgenv-smoke-server"]

FROM debian:${DEBIAN_VERSION} AS vscode-client

ARG TARGETARCH
ARG VSCODE_VERSION=1.134.0
ARG REMOTE_SSH_VERSION=0.126.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        dbus-x11 \
        fonts-dejavu-core \
        openssh-client \
        openbox \
        procps \
        scrot \
        tini \
        x11-utils \
        xdotool \
        xvfb \
    && case "${TARGETARCH}" in \
        amd64) vscode_arch=x64 ;; \
        arm64) vscode_arch=arm64 ;; \
        *) printf 'unsupported Docker architecture: %s\n' "${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl --fail --location --show-error \
        "https://update.code.visualstudio.com/${VSCODE_VERSION}/linux-deb-${vscode_arch}/stable" \
        --output /tmp/code.deb \
    && apt-get install -y --no-install-recommends /tmp/code.deb \
    && rm -f /tmp/code.deb \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 --shell /bin/bash vscode \
    && install -d -m 0700 -o vscode -g vscode \
        /home/vscode/.config/Code/User \
        /home/vscode/.ssh \
        /home/vscode/.vscode/extensions \
        /tmp/vscode-runtime \
    && chown -R vscode:vscode \
        /home/vscode/.config \
        /home/vscode/.vscode \
        /tmp/vscode-runtime

RUN install -d -m 1777 /tmp/.X11-unix

USER vscode

ENV CGENV_SMOKE_VSCODE_VERSION=${VSCODE_VERSION} \
    CGENV_SMOKE_REMOTE_SSH_VERSION=${REMOTE_SSH_VERSION} \
    DISPLAY=:99 \
    HOME=/home/vscode \
    LANG=C.UTF-8 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    XDG_RUNTIME_DIR=/tmp/vscode-runtime

RUN for attempt in 1 2 3; do \
        code --install-extension \
            "ms-vscode-remote.remote-ssh@${REMOTE_SSH_VERSION}" --force \
            && break; \
        if [ "$attempt" -eq 3 ]; then exit 1; fi; \
        sleep 2; \
    done \
    && code --list-extensions --show-versions \
        | grep --fixed-strings --line-regexp \
            "ms-vscode-remote.remote-ssh@${REMOTE_SSH_VERSION}"

USER root

COPY --chown=vscode:vscode settings.json /home/vscode/.config/Code/User/settings.json
COPY client.sh /usr/local/bin/cgenv-smoke-client
COPY code-wrapper.sh /opt/cgenv-smoke/bin/code

RUN chmod 0755 \
        /opt/cgenv-smoke/bin/code \
        /usr/local/bin/cgenv-smoke-client

USER vscode

ENTRYPOINT ["/usr/bin/tini", "--", "dbus-run-session", "--", "/usr/local/bin/cgenv-smoke-client"]
