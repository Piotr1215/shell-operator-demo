FROM ghcr.io/flant/shell-operator:latest
COPY hooks /hooks
RUN chmod +x /hooks/*

