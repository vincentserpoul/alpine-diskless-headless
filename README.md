# Alpine diskless, headless install ![Shellcheck](https://github.com/vincentserpoul/alpine-diskless-headless/workflows/Shellcheck/badge.svg?branch=main)

/ ! \ THIS IS ALPHA, TO USE AT YOUR OWN RISKS / ! \

## Goal

The goal of this repo is to deploy a diskless configured alpine linux on sdcards destined to SBCs (single board computer, like a raspberry pi or rock pro 64).
Sdcard reliablity tends to be an issue in the long run with SBCs.
I decided to leverage the [diskless version of alpine linux](https://wiki.alpinelinux.org/wiki/Alpine_newbie_install_manual#diskless_mode) (running all in RAM) combined with the capability of [local backups, lbu for alpine](https://wiki.alpinelinux.org/wiki/Alpine_local_backup) to build a configured, running in RAM install of alpine linux!
On top of this, leveraging qemu and chroot, you can build the filesystem directly from your powerful x86_64 workstation, without even touching a SBC.

Once the sdcard is ready, you simply have to put it in your SBC and power it on.
Once booted, you should be able to ssh into it (see examples below).

## Decisions taken (security oriented)

- No root access from ssh
- ssh only with ssh key and, if you add the provider, 2fa
- to be further secured

## using it with docker

```bash
docker run -it --name alpine-diskless-headless-apk-build --rm --privileged \
    --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+,target=/apk/config \
    --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+/target,target=/target \
    --mount type=bind,source="$(pwd)"/example/pleine-lune-rpi3b+/provisioners,target=/apk/additional_provisioners,readonly \
    --device /dev/sda \
    vincentserpoul/alpine-diskless-headless -H rpi -d /dev/sda -f
```

### building it

```bash
docker build -t vincentserpoul/alpine-diskless-headless ./ -f ./Dockerfile
```

## Using it without docker

```
#!/usr/bin/env bash
#---help---
# Usage: ./run.sh [options]
#
# The goal of this script is to create a diskless, headless install of alpine
# linux for your SBC (rpi, rockpro64...), directly from your x86 computer.
#
# Just insert a sdcard and run it with the right parameters.
#
# It has a few dependencies: wget, binfmt-support, qemu-user-static, ssh, parted, dosfstools
#
# Example:
#   sudo ./run.sh -c "$(pwd)"/example/pleine-lune-rpi3b+/config.env -t "$(pwd)"/example/pleine-lune-rpi3b+/target -H rpi -d /dev/sda -f
#
# Options and environment variables:
#
#   -c CONFIG_FILE_PATH         path of the config.env file
#
#   -a ADDITIONAL_PROVISIONERS  path of the folder containing additional provisioner scripts
#                               Default: empty
#
#   -t TARGET_DIR               dir where tar.gz will be created
#                               Default: config dir
#
#   -H TARGET_HW                which SMB you are targeting.
#                               Options: rpi
#                               Default: rpi
#
#   -d DEVICE_NAME              name of the device to write to. for example /dev/sda
#                               Default: empty
#
#   -f FORCE_DEV_WRITE          if true, don't ask before writing to the device.
#                               Default: false
#
#   -h                          show this help message and exit.
#
# Each option can be also provided by environment variable. If both option and
# variable is specified and the option accepts only one argument, then the
# option takes precedence.
#
# https://github.com/vincentserpoul/alpine-diskless-headless
#---help---
```

## Examples

### rpi3b+

You have a rpi3B+, you want to set it with a hostname "pleine-lune" and want to use ethernet connection only (you can add the wlan with provisioners), look into [pleine-lune example config](./example/pleine-lune-rpi3b+)

modify accordingly and run

```bash
sudo ./run.sh -c "$(pwd)"/example/pleine-lune-rpi3b+/config.env -t "$(pwd)"/example/pleine-lune-rpi3b+/target -H rpi -d /dev/sda -f
```

### rpi0

You have a rpi0, you want to set it with a hostname "pleine-lune" and can only use wlan (notice the provisioner), look into [pleine-lune example config](./example/pleine-lune-rpi0)

modify accordingly and run

```bash
sudo ./run.sh -c "$(pwd)"/example/pleine-lune-rpi0/config.env -t "$(pwd)"/example/pleine-lune-rpi0/target -H rpi -d /dev/sda -f
```

### Accessing the rpi

Once the rpi has booted, you should be able to ssh into it, with one of the keys you configured in BASE_SSH_AUTHORIZED_KEYS, in the config you specified

```bash
ssh -i ~/.ssh/id_ed25519_alpine_diskless maintenance@pleine-lune
```

## Troubleshooting

### ssh tries to connect with IPV6

Find out the ipv4 IP your rpi has been attributed and replace your hostname with it.

```bash
ssh -i ~/.ssh/id_ed25519_alpine_diskless maintenance@192.168.1.102
```

## Future

This is a first version, working for rpis.

Then, we ll create a proper command cli, in order to handle configuration a bit better.

# TODO

- [x] use docker
- [ ] [ufw](https://wiki.alpinelinux.org/wiki/Uncomplicated_Firewall)
- [ ] encrypt lbu
- [ ] build with alpine, ofc
- [ ] try fakechroot
- [x] use a rust cli (see vincentserpoul/funicular)
- [ ] encrypt secrets (using [age](https://github.com/FiloSottile/age) or [sops](https://github.com/mozilla/sops) )

# THANKS

- https://github.com/alpinelinux/alpine-chroot-install
- https://github.com/knoopx/alpine-raspberry-pi
- https://github.com/yangxuan8282/gen-rpi_os/blob/master/gen-alpine_rpi.sh
- https://hütter.ch/posts/pitaya-alpine/#preparations
