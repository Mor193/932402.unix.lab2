FROM alpine:3.20

RUN apk add --no-cache util-linux

COPY worker.sh /usr/local/bin/worker.sh
RUN chmod +x /usr/local/bin/worker.sh

ENTRYPOINT ["/usr/local/bin/worker.sh"]