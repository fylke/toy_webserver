FROM docker.io/library/erlang:26-slim

COPY .devcontainer/bash.bashrc /etc/bash.bashrc

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        git \
    && git config --system url."https://github.com/".insteadOf "git@github.com:" \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch v1.8.0 --depth 1 https://github.com/WhatsApp/erlfmt.git /tmp/erlfmt \
    && cd /tmp/erlfmt \
    && rebar3 as release escriptize \
    && install -m 755 _build/release/bin/erlfmt /usr/local/bin/erlfmt \
    && rm -rf /tmp/erlfmt

WORKDIR /workspace/toy_webserver
