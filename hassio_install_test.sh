#!/usr/bin/env bash
set -e

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

warn "OK"
