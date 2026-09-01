FROM docker.io/library/erlang:26-slim

COPY bash.bashrc /etc/bash.bashrc

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        git \
    && git config --system url."https://github.com/".insteadOf "git@github.com:" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/toy_webserver
