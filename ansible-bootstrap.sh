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

#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Early argument handling (must come first, no side effects)
# ------------------------------------------------------------------------------

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<EOF
Usage: ./ansible-bootstrap.sh

This script:
  - prepares a workspace
  - ensures the controller scaffold is present
  - creates an ephemeral Ansible execution environment

It does NOT:
  - run controller.yml
  - modify controller state

Run with no arguments to begin bootstrapping.
EOF
  exit 0
fi

# ------------------------------------------------------------------------------
# Safety and shell behavior
# ------------------------------------------------------------------------------

set -euo pipefail
trap '' PIPE

# ==============================================================================
# Ansible Controller Bootstrap Script
# ==============================================================================

REPO_NAME="ansible-role-controller"
REPO_URL="https://github.com/steelcj/ansible-role-controller.git"
VENV_PATH="/tmp/ve-ansible"

WORKSPACE="$(pwd)"

echo "Workspace:"
echo "  ${WORKSPACE}"
echo

# ------------------------------------------------------------------------------
# Ensure required OS-level tools exist
# ------------------------------------------------------------------------------

for cmd in python3 git curl wget; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: Required command '${cmd}' not found in PATH."
    exit 1
  fi
done

# ------------------------------------------------------------------------------
# Ensure controller scaffold repository exists
# ------------------------------------------------------------------------------

if [ ! -d "${WORKSPACE}/${REPO_NAME}" ]; then
  echo "Controller scaffold repository not found."
  echo "Cloning ${REPO_NAME} into workspace..."
  git clone "${REPO_URL}" "${WORKSPACE}/${REPO_NAME}"
else
  echo "Controller scaffold repository already present:"
  echo "  ${WORKSPACE}/${REPO_NAME}"
fi

echo

# ------------------------------------------------------------------------------
# Create ephemeral Ansible virtual environment
# ------------------------------------------------------------------------------

if [ -d "${VENV_PATH}" ]; then
  echo "Removing existing ephemeral Ansible environment:"
  echo "  ${VENV_PATH}"
  rm -rf "${VENV_PATH}"
fi

echo "Creating ephemeral Ansible virtual environment:"
echo "  ${VENV_PATH}"
python3 -m venv "${VENV_PATH}"

# shellcheck disable=SC1091
source "${VENV_PATH}/bin/activate"

pip install --upgrade pip setuptools wheel

# ------------------------------------------------------------------------------
# ansible-core version selection
# ------------------------------------------------------------------------------

echo
echo "Available ansible-core versions:"

PIP_VERSIONS_OUTPUT="$(pip index versions ansible-core)"

echo "${PIP_VERSIONS_OUTPUT}" | sed -n '1,3p'

LATEST_VERSION="$(echo "${PIP_VERSIONS_OUTPUT}" | head -n1 | awk '{print $2}' | tr -d '()')"

if [ -z "${LATEST_VERSION}" ]; then
  echo "ERROR: Unable to determine latest ansible-core version."
  deactivate
  exit 1
fi

echo
echo "No ansible-core version specified."
echo "Suggested latest stable: ${LATEST_VERSION}"
read -r -p "Press Enter to accept, enter a version, or 'n' to abort: " response

if [[ -z "${response}" ]]; then
  SELECTED_VERSION="${LATEST_VERSION}"
elif [[ "${response}" =~ ^[nNqQ]$ ]]; then
  echo "Aborted by user."
  deactivate
  exit 1
else
  SELECTED_VERSION="${response}"
fi

pip install "ansible-core==${SELECTED_VERSION}"

echo
echo "ansible-core ${SELECTED_VERSION} installed in ephemeral environment."
echo

# ------------------------------------------------------------------------------
# Handoff
# ------------------------------------------------------------------------------

deactivate

cat <<EOF

Bootstrap complete.
Ephemeral Ansible environment has been created.

Next steps (run explicitly):

  source ${VENV_PATH}/bin/activate
  cd ${WORKSPACE}/${REPO_NAME}
  ansible-playbook controller.yml \\
    -e controller_env=dev \\
    -e controller_ansible_core_version=${LATEST_VERSION}

Notes:
- The virtual environment is ephemeral and located in /tmp
- The controller scaffold repository has not been modified
- Controller construction has NOT started yet

EOF

