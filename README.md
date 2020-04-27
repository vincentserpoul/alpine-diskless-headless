# Alpine diskless, headless install

These scripts will help you build and write a headless install of alpine linux for SBC.

```
# Usage: ./run.sh [options]
#
# The goal of this script is to create a diskless, headless install of alpine
# linux for your SBC (rpi, rockpro64...), directly from your x86 computer.
#
# Just insert a sdcard and run it with the right parameters.
#
# It has a few dependencies: qemu, chroot, parted.
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

# Examples

You have a rpi3B+, hostname test-magic, and you want ethernet and wlan

```bash
sudo ./run.sh -n test-magictest-magic
```

You have a rpi0, hostname test-magic, and you only need wlan (armhf and no ethernet on rpi0)

```bash
sudo ./run.sh -n test-magictest-magic -a armhf -w 2
```

# TODO

- [ ] fix wlan dhcp
- [ ] encrypt lbu
- [ ] switch to rust or go cli
- [ ] encrypt secrets (using [age](https://github.com/FiloSottile/age)?)
- [ ] [ufw](https://wiki.alpinelinux.org/wiki/Uncomplicated_Firewall)

# THANKS

- https://github.com/alpinelinux/alpine-chroot-install
- https://github.com/knoopx/alpine-raspberry-pi
- https://github.com/yangxuan8282/gen-rpi_os/blob/master/gen-alpine_rpi.sh
- https://hütter.ch/posts/pitaya-alpine/#preparations

```

```
