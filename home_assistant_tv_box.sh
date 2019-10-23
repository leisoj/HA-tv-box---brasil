#!/usr/bin/env bash
set -o errexit  # Exit script when a command exits with non-zero status
set -o errtrace # Exit on error inside any functions or sub-shells
set -o nounset  # Exit script on use of an undefined variable
set -o pipefail # Return exit status of the last command in the pipe that failed

readonly HOSTNAME="Hassio"
readonly HASSIO_INSTALLER="https://raw.githubusercontent.com/home-assistant/hassio-installer/master/hassio_install.sh"
readonly REQUIREMENTS=(
  apparmor-utils
  apt-transport-https
  avahi-daemon
  ca-certificates
  curl
  dbus
  jq
  network-manager
  socat
  software-properties-common
)

update_hostname() {
  old_hostname=$(< /etc/hostname)
  if [[ "${old_hostname}" != "${HOSTNAME}" ]]; then
    sed -i "s/${old_hostname}/${HOSTNAME}/g" /etc/hostname
    sed -i "s/${old_hostname}/${HOSTNAME}/g" /etc/hosts
    hostname "${HOSTNAME}"
    echo "Hostname will be changed on next reboot: ${HOSTNAME}"
  fi
}

install_requirements() {
  echo "Updating APT packages list..."
  apt-get install software-properties-common
  apt-get update

  echo "Ensure all requirements are installed..."
  apt-get install -y "${REQUIREMENTS[@]}"
}

install_docker() {
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
}

install_hassio() {
  echo "Installing Hass.io..."
  curl -sL "${HASSIO_INSTALLER}" | bash -s -- -m qemuarm-64
}

config_network_manager() {
  {
    echo -e "\n[device]";
    echo "wifi.scan-rand-mac-address=no";
    echo -e "\n[connection]";
    echo "wifi.clone-mac-address=preserve";
  } >> "/etc/NetworkManager/NetworkManager.conf"
}

main() {

  if [[ $EUID -ne 0 ]]; then
    echo "Você deve acessar como root."
    echo "Para isto, digite:"
    echo "su -"
    echo "e a senha criada. ok!"
    exit 1
  fi

  update_hostname
  install_requirements
  config_network_manager
  install_docker
  install_hassio

  ip_addr=$(hostname -I | cut -d ' ' -f1)
  echo "*******************HOME ASSISTANT BRASIL********************"
  echo "Tudo OK! Agora você instalou o Home Assistant em sua Tv Box."
  echo "Agora é só aguardar os 20 minutos do HA. Voce pode ver em:"
  echo "http://${ip_addr}:8123/"
  echo "by: Josiel"
  echo "Fonte: Sites chineses, russos, indianos e a da comunidade HA de Portugal"
  exit 0
}
main
