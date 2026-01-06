#!/usr/bin/env bash
#
# ansible-bootstrap.sh
#
# Ephemeral Ansible bootstrap script.
#
# Provides a temporary Ansible execution environment and optionally
# runs an Ansible scaffold (controller bootstrap playbook + roles)
# to construct a persistent Ansible controller.
#
# NOTE:
# This script is NOT the controller.
# The scaffold constructs the controller and may be discarded after use.
#
# Copyright (C) 2026 Christopher Steel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See <https://www.gnu.org/licenses/>.
#

set -euo pipefail

### Configuration (explicit, minimal)

EPHEMERAL_VENV="/tmp/ve-ansible"
CONTROLLER_WORKSPACE="${HOME}/projects/tmp/ansible-controller"

BOOTSTRAP_CONTROLLER=false
CONTROLLER_ENV=""
ANSIBLE_CORE_VERSION=""

### Helpers

usage() {
  cat <<EOF
Usage:
  ansible-bootstrap.sh [options]

Options:
  --bootstrap-controller     Run Ansible scaffold to construct a controller
  --env <name>               Controller environment (default: dev)
  --ansible-core <version>   Explicit ansible-core version
  --help                     Show this help

Examples:
  ansible-bootstrap.sh
  ansible-bootstrap.sh --bootstrap-controller --env dev --ansible-core 2.20.1
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command not found: $1"
    exit 1
  }
}

suggest_latest_ansible_core() {
  python3 -m pip index versions ansible-core 2>/dev/null \
    | awk -F'[(), ]+' '/^ansible-core/ { print $2 }'
}

### Argument parsing

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap-controller)
      BOOTSTRAP_CONTROLLER=true
      shift
      ;;
    --env)
      CONTROLLER_ENV="$2"
      shift 2
      ;;
    --ansible-core)
      ANSIBLE_CORE_VERSION="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

### Prerequisite checks

require_cmd python3
python3 -m venv --help >/dev/null 2>&1 || {
  echo "Python venv support is required."
  exit 1
}

### Create ephemeral Ansible environment

if [ ! -d "${EPHEMERAL_VENV}" ]; then
  echo "Creating ephemeral Ansible environment at ${EPHEMERAL_VENV}"
  python3 -m venv "${EPHEMERAL_VENV}"
fi

# shellcheck disable=SC1091
source "${EPHEMERAL_VENV}/bin/activate"

pip install --quiet --upgrade pip
pip install --quiet ansible-core

### ansible-core version selection (explicit)

echo ""
echo "Available ansible-core versions:"
echo ""

if ! python3 -m pip index versions ansible-core; then
  echo "Unable to query ansible-core versions."
  echo "Please specify --ansible-core explicitly."
  exit 1
fi

echo ""

if [ -z "${ANSIBLE_CORE_VERSION}" ]; then
  SUGGESTED_VERSION="$(suggest_latest_ansible_core)"

  if [ -z "${SUGGESTED_VERSION}" ]; then
    echo "Unable to determine latest stable ansible-core version."
    exit 1
  fi

  echo "No ansible-core version specified."
  echo "Suggested latest stable: ${SUGGESTED_VERSION}"
  echo ""

  read -r -p "Use this version? [Y/n] " reply
  reply=${reply:-Y}

  if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
    echo "Aborted. Re-run with --ansible-core <version>."
    exit 1
  fi

  ANSIBLE_CORE_VERSION="${SUGGESTED_VERSION}"
fi

### Optional controller construction via Ansible scaffold

if [ "${BOOTSTRAP_CONTROLLER}" = "true" ]; then
  CONTROLLER_ENV="${CONTROLLER_ENV:-dev}"

  echo ""
  echo "Running Ansible scaffold to construct controller"
  echo "  environment: ${CONTROLLER_ENV}"
  echo "  ansible-core: ${ANSIBLE_CORE_VERSION}"
  echo ""

  echo "Using Ansible scaffold (controller bootstrap playbook + roles)"

  if [ ! -d "${CONTROLLER_WORKSPACE}" ]; then
    echo "Creating controller scaffold workspace: ${CONTROLLER_WORKSPACE}"
    mkdir -p "${CONTROLLER_WORKSPACE}"
  fi

  cd "${CONTROLLER_WORKSPACE}"

  if [ ! -f "create-controller.sh" ]; then
    echo "Error: create-controller.sh not found in scaffold workspace."
    echo "Clone or prepare the Ansible scaffold before running."
    exit 1
  fi

  ./create-controller.sh "${CONTROLLER_ENV}" "${ANSIBLE_CORE_VERSION}"
else
  echo ""
  echo "Bootstrap complete."
  echo "Ephemeral Ansible environment is active."
  echo ""
  echo "You may now run the controller bootstrap playbook manually, e.g.:"
  echo ""
  echo "  ansible-playbook controller.yml \\"
  echo "    -e controller_env=dev \\"
  echo "    -e controller_ansible_core_version=${ANSIBLE_CORE_VERSION}"
fi
