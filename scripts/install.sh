#!/bin/bash
CONFIG_FILE="$1"

# Check if first param not exist, and will auto fill it with k8s.conf
if ! [[ -n "$1" ]]; then
  CONFIG_FILE="efk.conf"
fi

check_file() {
  if [[ ! -f "$1" ]]; then
    echo "Error: File \"${1}\" does not exist."
    exit 1
  fi
}

check_file $CONFIG_FILE
source "$CONFIG_FILE"

check_file .library
source .library

main() {
  # sudo apt update -y
  # sudo apt install -y ansible default-jdk
  gen_cert_efk

  prep_hosts_list
  make_hosts_list "$lb_prefix" "$lb_fqdn"
  make_hosts_list "$es_prefix" "$es_fqdn"
  make_hosts_list "$kbn_prefix" "$kbn_fqdn"
  make_hosts_list "$fs_prefix" "$fs_fqdn"

  prepare_nft "$lb_prefix"
  prepare_nft "$es_prefix"
  prepare_nft "$kbn_prefix"
  prepare_nft "$fs_prefix"

  prep_lb_config
  gen_lb_config "$es_port" "elasticsearch" $es_hostname
  gen_lb_config "$siem_port:$kbn_port" "kibana" $kbn_hostname
  # gen_lb_config "$fleet_port" "fleet" $fs_hostname
  # gen_lb_config "9001" "paloalto" $fs_hostname
  # gen_lb_config "9004" "fortigate" $fs_hostname
  # gen_lb_config "9006" "juniper" $fs_hostname

  prep_installer
  cd .. && \
  ansible-playbook playbooks/deploy_efk.yml
}




# fresh_init() {
#   rm -rf "$FILES_DIR"
#   mkdir -p "$FILES_DIR"
#   rm -rf "$INV_DIR"
#   mkdir -p "$ES_INSTALLER_DIR"
#   cp -r ~/es-installer "$FILES_DIR"
# }

confirmation "This script will install:"
# main

# fresh_init
