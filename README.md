# Alpine diskless, headless install  ![Shellcheck](https://github.com/vincentserpoul/alpine-diskless-headless/workflows/Shellcheck/badge.svg?branch=master)
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
- User maintenance created as a sudoer, to connect via ssh and sudo
- ssh only with ssh key and 2fa
- to be further secured

## Using it

```
# Usage: ./run.sh [options]
#
# The goal of this script is to create a diskless, headless install of alpine
# linux for your SBC (rpi, rockpro64...), directly from your x86 computer.
#
# Just insert a sdcard and run it with the right parameters.
#
# It has a few dependencies: qemu-user-static, chroot, parted.
#
# Example:
#   sudo sudo ./run.sh -n myalpine -f
#
# Options and environment variables:
#
#   -d HARDWARE            which SMB you are targeting.
#                          Options: rpi
#                          Default: rpi
#
#   -a ARCH                CPU architecture for the SMB.
#                          Options: x86_64, x86, aarch64, armhf, armv7, ppc64le, s390x.
#                          Default: aarch64
#
#   -m ALPINE_MIRROR...    URI of the Aports mirror to fetch packages from.
#                          Default: http://dl-cdn.alpinelinux.org/alpine
#
#   -b ALPINE_BRANCH       Alpine branch to install.
#                          Default: latest-stable
#
#   -v ALPINE_VERSION      Alpine version to install.
#                          Default: 3.11.6
#
#   -p DEVICE_NAME         Name of the device to write to.
#                          Default: /dev/sda
#
#   -n BUILD_HOSTNAME      Hostname. Must be filled
#                          No default
#
#   -t TIMEZONE            Timezone.
#                          Default: Asia/Singapore
#
#   -w NETWORKING          Networking options
#                          Options: 0 (NONE), 1 (ETHERNET), 2 (WLAN), 3 (ALL)
#                          Default: 3
#
#   -f FORCE               If true, don't ask before writing to the device.
#                          Default: false
#
#   -h                     Show this help message and exit.
#
# Each option can be also provided by environment variable. If both option and
# variable is specified and the option accepts only one argument, then the
# option takes precedence.
#
# https://github.com/vincentserpoul/alpine-diskless-headless
```

## Examples

You have a rpi3B+, hostname test-magic, and you want ethernet and wlan

```bash
sudo ./run.sh -n test-magic
```

You have a rpi0, hostname test-magic, and you only need wlan (armhf and no ethernet on rpi0)

```bash
sudo ./run.sh -n test-magic -a armhf -w 2
```

Once the rpi has booted, you should be able to ssh into it:

```bash
ssh -i ~/.ssh/id_ed25519_alpine_diskless maintenance@test-magic
```

## Troubleshooting

### Restart from scratch

```bash
    rm -f ~/.ssh/id_ed25519_alpine_diskless*
    rm -rf ./apk/secrets
```

<!-- TODO ADD MORE -->

## Future

This is a first version, working for rpis.
The next step will be to include rockpro64.
Then, we ll create a proper command cli, in order to handle configuration a bit better.

# TODO

- [ ] encrypt lbu
- [ ] switch to rust or go cli
- [ ] encrypt secrets (using [age](https://github.com/FiloSottile/age) or [sops](https://github.com/mozilla/sops) )
- [ ] [ufw](https://wiki.alpinelinux.org/wiki/Uncomplicated_Firewall)

# THANKS

- https://github.com/alpinelinux/alpine-chroot-install
- https://github.com/knoopx/alpine-raspberry-pi
- https://github.com/yangxuan8282/gen-rpi_os/blob/master/gen-alpine_rpi.sh
- https://hütter.ch/posts/pitaya-alpine/#preparations

```

```
