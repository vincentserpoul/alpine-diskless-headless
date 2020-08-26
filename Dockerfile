FROM debian:buster-slim

RUN apt-get update && apt-get install -y \
    wget binfmt-support qemu-user-static ssh parted

COPY ./apk/scripts /apk/scripts
COPY ./apk/build.sh /apk/build.sh

COPY ./hw/rpi/scripts /hw/rpi/scripts
COPY ./hw/rpi/build.sh /hw/rpi/build.sh
COPY ./hw/build.sh /hw/build.sh

COPY ./dev/scripts /dev/scripts
COPY ./dev/run.sh /dev/run.sh

COPY ./scripts /scripts

COPY ./run.sh /run.sh

# config dir
VOLUME ["/apk/config/"]

#target dir
VOLUME ["/target/"]

# Additional provisioners build
VOLUME ["/apk/additional_provisioners"]

ENTRYPOINT ["/run.sh", "-c", "/apk/config/config.env", "-a", "/apk/additional_provisioners", "-t", "/target"]

CMD ["/bin/bash"]

# docker build -t vincentserpoul/funicular ./ -f ./Dockerfile

# docker run -it --name funicular-apk-build --rm --privileged \
#     --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+,target=/apk/config \
#     --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+/target,target=/target \
#     --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+/provisioners,target=/apk/additional_provisioners,readonly \
#     --device /dev/sda \
#     vincentserpoul/funicular -w rpi -d /dev/sda -f