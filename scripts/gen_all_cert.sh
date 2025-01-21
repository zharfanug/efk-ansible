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
  # sudo apt install -y default-jdk
  gen_cert_efk
}

confirmation "This script will generate certificates for:"