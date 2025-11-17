#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
WORKSPACE_DIR=$(dirname "$SCRIPT_DIR")

cd "$WORKSPACE_DIR" || exit 1

cat <<EOF > ansible.cfg
[defaults]
inventory = inventory/hosts
roles_path = roles
filter_plugins = filter_plugins
host_key_checking = False
EOF

mkdir -p .vscode
# mkdir -p files
mkdir -p filter_plugins
mkdir -p inventory
mkdir -p inventory/group_vars
mkdir -p inventory/host_vars
mkdir -p playbooks
mkdir -p roles

touch inventory/hosts
touch inventory/host_vars/all.yml
touch inventory/group_vars/all.yml
# touch playbooks/main.yml

repo_update=0

if command -v sudo >/dev/null 2>&1; then
  apt()    { sudo apt -y "$@" || exit 1; }
  yum()    { sudo yum -y "$@" || exit 1; }
  dnf()    { sudo dnf -y "$@" || exit 1; }
  zypper() { sudo zypper -y "$@" || exit 1; }
else
  apt()    { command apt -y "$@" || exit 1; }
  yum()    { command yum -y "$@" || exit 1; }
  dnf()    { command dnf -y "$@" || exit 1; }
  zypper() { command zypper -y "$@" || exit 1; }
fi

do_repo_update() {
  repo_update=1
  if command -v apt >/dev/null 2>&1; then
    apt update
  elif command -v dnf >/dev/null 2>&1; then
    dnf makecache
  elif command -v yum >/dev/null 2>&1; then
    yum makecache
  elif command -v zypper >/dev/null 2>&1; then
    zypper refresh
  else
    repo_update=0
    echo "Error: No supported package manager found (apt, dnf, yum, zypper)"
  fi
}

install_pkg() {
  if [ "$repo_update" -eq 0 ]; then
    do_repo_update
  fi

  if command -v apt >/dev/null 2>&1; then
    apt install "$1"
  elif command -v dnf >/dev/null 2>&1; then
    dnf install "$1"
  elif command -v yum >/dev/null 2>&1; then
    yum install "$1"
  elif command -v zypper >/dev/null 2>&1; then
    zypper install "$1"
  else
    echo "Error: No supported package manager found (apt, dnf, yum, zypper)"
    if [ "$2" = "true" ]; then
      exit 1
    fi
  fi
}

install_if_not_exist() {
  if command -v dpkg >/dev/null 2>&1; then
    if ! dpkg -s "$1" >/dev/null 2>&1; then
      echo "$1 not installed — installing..."
      install_pkg "$1"
    fi
  elif command -v rpm >/dev/null 2>&1; then
    if ! rpm -q "$1" >/dev/null 2>&1; then
      echo "$1 not installed — installing..."
      install_pkg "$1"
    fi
  else
    echo "Error: No supported package query tool found (dpkg, rpm)"
  fi
}

install_if_not_exist jq
install_if_not_exist python3
install_if_not_exist python3-venv
# install_if_not_exist apt-cacher-ng

if ! [ -f ".vscode/settings.json" ]; then
  echo "{}" > .vscode/settings.json
fi
grep -v '^\s*//' .vscode/settings.json | \
grep -v '^\s*$' | \
jq '.["files.associations"] = (.["files.associations"] // {}) + {
  "**/playbooks/*.yml": "ansible",
  "**/roles/**/*.yml": "ansible",
  "*.yml": "yaml"
}' > .vscode/settings.tmp && mv .vscode/settings.tmp .vscode/settings.json

# ----- extensions.json -----
[ -f .vscode/extensions.json ] || echo "{}" > .vscode/extensions.json

grep -v '^\s*//' .vscode/extensions.json | grep -v '^\s*$' | \
jq '.["recommendations"] = ((.["recommendations"] // []) + [
  "ms-python.python",
  "redhat.ansible",
  "samuelcolvin.jinjahtml"
] | unique)' \
> .vscode/extensions.tmp && mv .vscode/extensions.tmp .vscode/extensions.json


[ ! -d "venv" ] && python3 -m venv venv
if [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
  pip install -r requirements.txt
  echo "Run these scripts:"
  echo "source venv/bin/activate"
  # echo "pip install -r requirements.txt"
else
  echo "Error: Virtual environment activation script not found."
  exit 1
fi

jq '.["ansible.python.interpreterPath"] = "'$WORKSPACE_DIR'/venv/bin/python"' .vscode/settings.json > .vscode/settings.tmp && mv .vscode/settings.tmp .vscode/settings.json
