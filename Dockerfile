FROM debian:buster-slim

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    binfmt-support qemu-user-static ssh \
    parted dosfstools

# cache common downloads
COPY ./hw/rpi/predownload.sh /hw/rpi/predownload.sh
RUN /hw/rpi/predownload.sh

COPY ./scripts /scripts

COPY ./run.sh /run.sh

COPY ./apk/scripts /apk/scripts
COPY ./apk/build.sh /apk/build.sh
COPY ./apk/predownload.sh /apk/predownload.sh

# cache common downloads
RUN /apk/predownload.sh

COPY ./hw/rpi/scripts /hw/rpi/scripts
COPY ./hw/rpi/build.sh /hw/rpi/build.sh

COPY ./hw/build.sh /hw/build.sh

COPY ./device/scripts /device/scripts
COPY ./device/run.sh /device/run.sh

# config dir
VOLUME ["/apk/config/"]

#target dir
VOLUME ["/target/"]

# Additional provisioners build
VOLUME ["/apk/additional_provisioners"]

ENTRYPOINT ["/run.sh", "-c", "/apk/config/config.env", "-a", "/apk/additional_provisioners", "-t", "/target"]

CMD ["/bin/bash"]

# docker build -t vincentserpoul/alpine-diskless-headless ./ -f ./Dockerfile

# docker run -it --name alpine-diskless-headless --rm --privileged \
#     --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+,target=/apk/config \
#     --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+/target,target=/target \
#     --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+/provisioners,target=/apk/additional_provisioners,readonly \
#     --device /dev/sda \
#     vincentserpoul/alpine-diskless-headless -H rpi -d /dev/sda -f