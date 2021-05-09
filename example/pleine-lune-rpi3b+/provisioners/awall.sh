#!/usr/bin/env sh

set -eu

#==============================================================================#

#===============================  e n v  v a r s  =============================#

# example PROVISIONER_AWALL_JSON_CONFIG
# {
#   "description": "Home firewall",
#   "zone": {
#     "internet": { "iface": "wlan0" }
#   },
#   "policy": [{ "in": "internet", "action": "drop" }, { "action": "reject" }],
#   "filter": [
#     {
#       "in": "_fw",
#       "out": "internet",
#       "service": ["dns", "http", "https", "ssh", "ntp", "ping"],
#       "action": "accept"
#     },
#     {
#       "in": "internet",
#       "service": "ping",
#       "action": "accept",
#       "flow-limit": { "count": 10, "interval": 6 }
#     },
#     {
#       "in": "internet",
#       "out": "_fw",
#       "service": "ssh",
#       "action": "accept",
#       "conn-limit": { "count": 3, "interval": 60 }
#     },
#     {
#       "in": "internet",
#       "out": "_fw",
#       "service": ["http", "https"],
#       "action": "accept"
#     }
#   ]
# }

# user config
: "${PROVISIONER_AWALL_JSON_CONFIG?Need to set PROVISIONER_AWALL_JSON_CONFIG}"

#=================================  a w a l l  ================================#

provisioner_awall_install_pkg() {
  apk add ip6tables iptables
  apk add -u awall

  provisioner_awall_modloop_fix
  provisioner_awall_kernel_download
  provisioner_awall_modloop_rc

  # modprobe -v ip_tables ip6_tables # IPv4
  # modprobe -v ip6_tables           # if IPv6 is used

  rc-update add iptables
  rc-update add ip6tables

  # echo "$PROVISIONER_AWALL_JSON_CONFIG" >/etc/awall/optional/policies.json

  awall translate --verify
  # for all config files
  # awall enable policies
  awall activate

  lbu add /usr/share/awall
  lbu add /etc/awall
}

provisioner_awall_modloop_fix_alpine_doc() {
  apk add squashfs-tools                      # install squashfs tools to unpack modloop
  unsquashfs -d /root/squash /lib/modloop-lts # unpack modloop to root dir
  umount /.modloop                            # unmount existing modloop
  mount /root/squash/ /.modloop/              # mount unpacked modloop
}

provisioner_awall_modloop_fix() {
  echo "fix"

  mkdir -p /lib/modules
  modprobe overlay
  mkdir -p /.modloop.lower /.modloop.upper /.modloop.workdir
  mount /dev/loop0 /.modloop.lower
  umount /.modloop/
  mount -t overlay -o lowerdir=/.modloop.lower,upperdir=/.modloop.upper,workdir=/.modloop.workdir none /.modloop
  lbu add /.modloop.upper
}

provisioner_awall_kernel_download() {
  echo "download"

  cd /tmp
  pkgname=$(apk list | grep awall | cut -d " " -f 1)
  wget http://dl-cdn.alpinelinux.org/alpine/v3.13/community/aarch64/$pkgname.apk
  mkdir /tmp/$pkgname
  tar -xzf $pkgname.apk -C /tmp/$pkgname
  mkdir -p /lib/modules/$(uname -r)/extra/
  cp /tmp/$pkgname/lib/modules/$(uname -r)/extra/awall.ko \
    /lib/modules/$(uname -r)/extra/
  rm -fr /tmp/$pkgname /tmp/$pkgname.apk
  depmod
}

provisioner_awall_modloop_rc() {
  echo "overlay"

  cat >/etc/init.d/modloopoverlay <<EOF
#!/sbin/openrc-run

depend() {
    before networking
    need modules
}

start() {
    ebegin "Starting modloop overlay"
    modprobe overlay
    mkdir -p /.modloop.lower /.modloop.upper /.modloop.workdir
    if [ ! -d /.modloop.lower/modules ]; then
        mount /dev/loop0 /.modloop.lower
    fi
    umount /.modloop
    mount -t overlay -o lowerdir=/.modloop.lower,upperdir=/.modloop.upper,workdir=/.modloop.workdir none /.modloop
    eend 0
}
EOF
  chmod +x /etc/init.d/modloopoverlay
  /etc/init.d/modloopoverlay restart
  rc-update add modloopoverlay boot
  lbu add /etc/init.d/modloopoverlay
}

#==============================================================================#

printf "\n> awall setup\n"

provisioner_awall_install_pkg

# https://lists.alpinelinux.org/~alpine/users/%3CCAEhkKgV-OdZ8y406_yynrH7tcxjgXkKzSc6dCSZ_a6CUPUfBiA%40mail.gmail.com%3E
# https://hütter.ch/posts/pitaya-alpine/
# http://allanrbo.blogspot.com/2020/06/wireguard-kernel-module-for-alpine.html
# https://gitlab.alpinelinux.org/alpine/aports
