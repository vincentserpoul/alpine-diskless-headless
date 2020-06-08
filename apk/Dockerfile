FROM debian:buster-slim

RUN apt-get update && apt-get install -y \
    wget binfmt-support qemu-user-static ssh

# # Enable caching
# VOLUME ["/build/apk/secrets"]
# VOLUME ["/build/apk/downloads"]
# VOLUME ["/build/apk/apk-tools-static"]

# # Output dir
# VOLUME ["/build/apk/rootfs/apkovl"]

COPY ./ /build/

# ENV ARCH=
# ENV ALPINE_MIRROR=
# ENV ALPINE_BRANCH=
# ENV ALPINE_VERSION=
# ENV BUILD_HOSTNAME=
# ENV TIMEZONE=
# ENV NETWORKING=

# ENTRYPOINT /build/apk/build.sh

CMD ["/bin/bash"]

# For rpi0, as an example:
# docker run --privileged --rm -v /dev:/dev:ro \
#     -e ARCH="armhf" \
#     -e BUILD_HOSTNAME="test-rpi0-2" \
#     -e NETWORKING="2" \
#     -t vincentserpoul/alpine-diskless-headless