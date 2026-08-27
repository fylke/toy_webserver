FROM docker.io/library/erlang:26-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/toy_webserver
