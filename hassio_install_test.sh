#!/usr/bin/env bash
#set -e

function error { echo -e "[Error] $*"; exit 1; }
function warn  { echo -e "[Warning] $*"; }

ARCH=$(uname -m)
DOCKER_BINARY=/usr/bin/docker
DOCKER_REPO=homeassistant
DOCKER_SERVICE=docker.service
URL_VERSION="https://version.home-assistant.io/stable.json"
URL_BIN_HASSIO="https://raw.githubusercontent.com/home-assistant/hassio-installer/master/files/hassio-supervisor"
URL_BIN_APPARMOR="https://raw.githubusercontent.com/home-assistant/hassio-installer/master/files/hassio-apparmor"
URL_SERVICE_HASSIO="https://raw.githubusercontent.com/home-assistant/hassio-installer/master/files/hassio-supervisor.service"
URL_SERVICE_APPARMOR="https://raw.githubusercontent.com/home-assistant/hassio-installer/master/files/hassio-apparmor.service"
URL_APPARMOR_PROFILE="https://version.home-assistant.io/apparmor.txt"

# Check env
#command -v systemctl > /dev/null 2>&1 || error "Only systemd is supported!"
command -v docker > /dev/null 2>&1 || error "Please install docker first"
command -v jq > /dev/null 2>&1 || error "Please install jq first"
command -v curl > /dev/null 2>&1 || error "Please install curl first"
command -v avahi-daemon > /dev/null 2>&1 || error "Please install avahi first"
command -v dbus-daemon > /dev/null 2>&1 || error "Please install dbus first"
command -v nmcli > /dev/null 2>&1 || warn "No NetworkManager support on host."
command -v apparmor_parser > /dev/null 2>&1 || warn "No AppArmor support on host."


# Check if Modem Manager is enabled
#if systemctl list-unit-files ModemManager.service | grep enabled; then
    #warn "ModemManager service is enabled. This might cause issue when using serial devices."
#fi

# Detect if running on snapped docker
if snap list docker >/dev/null 2>&1; then
    DOCKER_BINARY=/snap/bin/docker
    DATA_SHARE=/root/snap/docker/common/hassio
    CONFIG=$DATA_SHARE/hassio.json
    DOCKER_SERVICE="snap.docker.dockerd.service"
fi

# Parse command line parameters
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in
        -m|--machine)
            MACHINE=$2
            shift
            ;;
        -d|--data-share)
            DATA_SHARE=$2
            shift
            ;;
        -p|--prefix)
            PREFIX=$2
            shift
            ;;
        -s|--sysconfdir)
            SYSCONFDIR=$2
            shift
            ;;
        *)
            error "Unrecognized option $1"
            ;;
    esac
    shift
done

PREFIX=${PREFIX:-/usr}
SYSCONFDIR=${SYSCONFDIR:-/etc}
DATA_SHARE=${DATA_SHARE:-$PREFIX/share/hassio}
CONFIG=$SYSCONFDIR/hassio.json

# Generate hardware options
case $ARCH in
    "i386" | "i686")
        MACHINE=${MACHINE:=qemux86}
        HOMEASSISTANT_DOCKER="$DOCKER_REPO/$MACHINE-homeassistant"
        HASSIO_DOCKER="$DOCKER_REPO/i386-hassio-supervisor"
    ;;
    "x86_64")
        MACHINE=${MACHINE:=qemux86-64}
        HOMEASSISTANT_DOCKER="$DOCKER_REPO/$MACHINE-homeassistant"
        HASSIO_DOCKER="$DOCKER_REPO/amd64-hassio-supervisor"
    ;;
    "arm" |"armv6l")
        if [ -z $MACHINE ]; then
            error "Please set machine for $ARCH"
        fi
        HOMEASSISTANT_DOCKER="$DOCKER_REPO/$MACHINE-homeassistant"
        HASSIO_DOCKER="$DOCKER_REPO/armhf-hassio-supervisor"
    ;;
    "armv7l")
        if [ -z $MACHINE ]; then
            error "Please set machine for $ARCH"
        fi
        HOMEASSISTANT_DOCKER="$DOCKER_REPO/$MACHINE-homeassistant"
        HASSIO_DOCKER="$DOCKER_REPO/armv7-hassio-supervisor"
    ;;
    "aarch64")
        if [ -z $MACHINE ]; then
            error "Please set machine for $ARCH"
        fi
        HOMEASSISTANT_DOCKER="$DOCKER_REPO/$MACHINE-homeassistant"
        HASSIO_DOCKER="$DOCKER_REPO/aarch64-hassio-supervisor"
    ;;
    *)
        error "$ARCH unknown!"
    ;;
esac

if [ -z "${HOMEASSISTANT_DOCKER}" ]; then
    error "Found no Home Assistant Docker images for this host!"
fi

if [[ ! "intel-nuc odroid-c2 odroid-n2 odroid-xu qemuarm qemuarm-64 qemux86 qemux86-64 raspberrypi raspberrypi2 raspberrypi3 raspberrypi4 raspberrypi3-64 raspberrypi4-64 tinker" = *"${MACHINE}"* ]]; then
    error "Unknown machine type ${MACHINE}!"
fi

warn "OK"
