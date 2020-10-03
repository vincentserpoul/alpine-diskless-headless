FROM alpine:3.12

RUN apk update && apk add openrc alpine-conf --no-cache

CMD ["/bin/sh"]

# docker build -t vincentserpoul/alpine-diskless-headless-test ./ -f ./tests/Dockerfile