FROM alpine:latest

#Create Working Dir
RUN mkdir -p /tmp_store

RUN apk -U --no-cache add \
	sudo \
	bash \
	tar

RUN addgroup -g 1080 mc_user && \
    adduser -D -u 1080 -G mc_user -s /bin/sh mc_user

COPY --chmod=755 scripts/ /usr/bin/
RUN mkdir /mc-bk && mkdir /restore && chown -R 1080:1080 /mc-bk /usr/bin /restore

USER mc_user

ENTRYPOINT [ "/bin/bash" ]
CMD ["/usr/bin/restore.sh"]
