ARG ALPINE_VERSION=3.13.5

FROM alpine:${ALPINE_VERSION}

ARG ALPINE_VERSION

RUN apk update && \
    apk add git gzip \
    alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso squashfs-tools sudo

WORKDIR /src

RUN git clone https://github.com/alpinelinux/aports.git --depth 1

RUN chmod +x aports/scripts/mkimage.sh

RUN addgroup root abuild
RUN abuild-keygen -a -i

WORKDIR /build

ENV ALPINE_VERSION=$ALPINE_VERSION

CMD /src/aports/scripts/mkimage.sh \
    --tag $(ALPINE_VERSION) \
    --arch aarch64 \
    --repository http://dl-cdn.alpinelinux.org/alpine/v$(echo $ALPINE_VERSION | cut -f1,2 -d".")/main \
    --extra-repository http://dl-cdn.alpinelinux.org/alpine/v$(echo $ALPINE_VERSION | cut -f1,2 -d".")/community \
    --profile rpi