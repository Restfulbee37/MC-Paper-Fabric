FROM alpine:latest AS builder

LABEL maintainer="Restfulbee37"
LABEL org.opencontainers.image.source="https://github.com/Restfulbee37/MC-Paper-Fabric"

ARG TARGETARCH="amd"
ARG TARGETVARIANT="64"

RUN mkdir -p /opt

ARG RCON_CLI_VERSION=1.6.7

ADD https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_${TARGETARCH}${TARGETVARIANT}.tar.gz /tmp/rcon-cli.tar.gz

RUN tar x -f /tmp/rcon-cli.tar.gz -C /opt/ && \
    chmod +x /opt/rcon-cli

ARG MC_MONITOR_VERSION=0.12.8

ADD https://github.com/itzg/mc-monitor/releases/download/${MC_MONITOR_VERSION}/mc-monitor_${MC_MONITOR_VERSION}_linux_${TARGETARCH}${TARGETVARIANT}.tar.gz /tmp/mc-monitor.tar.gz

RUN tar x -f /tmp/mc-monitor.tar.gz -C /opt/ && \
    chmod +x /opt/mc-monitor

ARG DEMOTER_VERSION=0.4.2

ADD https://github.com/itzg/entrypoint-demoter/releases/download/v${DEMOTER_VERSION}/entrypoint-demoter_${DEMOTER_VERSION}_Linux_${TARGETARCH}${TARGETVARIANT}.tar.gz /tmp/entrypoint-demoter.tar.gz

RUN tar x -f /tmp/entrypoint-demoter.tar.gz -C /opt/ && \
    chmod +x /opt/entrypoint-demoter


FROM alpine:latest

RUN apk -U --no-cache add \
    bash \
    coreutils \
    curl \
    iputils-ping \
    openssh-client \
    tar \
    tzdata \
    rsync \
    zstd


RUN addgroup -g 1080 mc_user && \
    adduser -D -u 1080 -G mc_user -s /bin/sh mc_user

COPY --from=builder /opt/rcon-cli /opt/rcon-cli

RUN ln -s /opt/rcon-cli /usr/bin
RUN chmod 777 /opt/rcon-cli
RUN chmod -R 777 /opt

COPY --from=builder /opt/mc-monitor /opt/mc-monitor

RUN ln -s /opt/mc-monitor /usr/bin

COPY --from=builder /opt/entrypoint-demoter /opt/entrypoint-demoter

RUN ln -s /opt/entrypoint-demoter /usr/bin

COPY --chmod=755 scripts/ /opt/
COPY --chmod=755 scripts/ /usr/bin/

RUN mkdir /mc-bk
RUN chown -R 1080:1080 /opt /usr/bin /mc-bk

USER mc_user

VOLUME ["/data", "/backups"]
WORKDIR "/backups"

ENTRYPOINT ["/usr/bin/backup.sh"]
