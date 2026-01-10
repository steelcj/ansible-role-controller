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
# See <https://www.gnu.org/licenses/>.
#

# ------------------------------------------------------------------------------
# Early argument handling (must come first, no side effects)
# ------------------------------------------------------------------------------

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<EOF
Usage: ./ansible-bootstrap.sh [options]

Options:
  --ansible-core <version>   Explicit ansible-core version
  --bootstrap-controller     Run Ansible scaffold to construct a controller
  --env <name>               Controller environment (default: dev)
  --dry-run                  Print resolved paths and exit without changes
  --help                     Show this help and exit

Default behavior (no options):
  - Create an ephemeral Ansible virtual environment in /tmp
  - Install ansible-core
  - Exit without cloning repositories or running playbooks
EOF
  exit 0
fi

# ------------------------------------------------------------------------------
# Safety and shell behavior
# ------------------------------------------------------------------------------

set -euo pipefail
trap '' PIPE

# ------------------------------------------------------------------------------
# Variable Defaults
# ------------------------------------------------------------------------------

BOOTSTRAP_CONTROLLER=false
DRY_RUN=false
CONTROLLER_ENV="dev"
ANSIBLE_CORE_VERSION=""

REPO_NAME="ansible-role-controller"
REPO_URL="git@github.com:steelcj/ansible-role-controller.git"
#REPO_URL="https://github.com/steelcj/ansible-role-controller.git"
VENV_PATH="/tmp/ve-ansible"
WORKSPACE="$(pwd)"

# ------------------------------------------------------------------------------
# Argument Parsing
# ------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap-controller)
      BOOTSTRAP_CONTROLLER=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --env)
      CONTROLLER_ENV="${2:-}"
      shift 2
      ;;
    --ansible-core)
      ANSIBLE_CORE_VERSION="${2:-}"
      shift 2
      ;;
    --help|-h)
      shift
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      exit 1
      ;;
  esac
done

# ------------------------------------------------------------------------------
# Environment checks
# ------------------------------------------------------------------------------

for cmd in python3 git curl wget; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: Required command '${cmd}' not found in PATH."
    exit 1
  fi
done

echo "Workspace:"
echo "  ${WORKSPACE}"
echo

# ------------------------------------------------------------------------------
# Determine ansible-core version
# ------------------------------------------------------------------------------

if [[ -n "${ANSIBLE_CORE_VERSION}" ]]; then
  SELECTED_VERSION="${ANSIBLE_CORE_VERSION}"
else
  echo "ERROR: --ansible-core <version> is required (non-interactive mode enforced)."
  exit 1
fi

# ------------------------------------------------------------------------------
# Derived controller paths (declarative, no side effects)
# ------------------------------------------------------------------------------

CONTROLLER_PROJECT_ROOT="${HOME}/projects/ansible/${SELECTED_VERSION}/${CONTROLLER_ENV}"
CONTROLLER_VENV_ROOT="${HOME}/.venvs/ansible/${SELECTED_VERSION}/${CONTROLLER_ENV}"

# ------------------------------------------------------------------------------
# Print installation plan (always visible)
# ------------------------------------------------------------------------------

echo "Controller installation plan:"
echo "  Environment:           ${CONTROLLER_ENV}"
echo "  Ansible Core version:  ${SELECTED_VERSION}"
echo
echo "Ephemeral Ansible environment:"
echo "  ${VENV_PATH}"
echo
echo "Permanent controller:"
echo "  Project root: ${CONTROLLER_PROJECT_ROOT}"
echo "  Virtualenv:   ${CONTROLLER_VENV_ROOT}"
echo

# ------------------------------------------------------------------------------
# Dry-run exit (no side effects beyond printing)
# ------------------------------------------------------------------------------

if [[ "${DRY_RUN}" == true ]]; then
  echo "Dry-run mode enabled."
  echo "No virtual environments created."
  echo "No packages installed."
  echo "No Ansible playbooks executed."
  exit 0
fi

# ------------------------------------------------------------------------------
# Create ephemeral Ansible virtual environment
# ------------------------------------------------------------------------------

if [ -d "${VENV_PATH}" ]; then
  rm -rf "${VENV_PATH}"
fi

echo "Creating ephemeral Ansible virtual environment:"
echo "  ${VENV_PATH}"

python3 -m venv "${VENV_PATH}"

# shellcheck disable=SC1091
source "${VENV_PATH}/bin/activate"

pip install --upgrade pip setuptools wheel
pip install "ansible-core==${SELECTED_VERSION}"

echo
echo "ansible-core ${SELECTED_VERSION} installed in ephemeral environment."
echo

# ------------------------------------------------------------------------------
# Optional controller bootstrap
# ------------------------------------------------------------------------------

if [[ "${BOOTSTRAP_CONTROLLER}" == true ]]; then
  if [ ! -d "${WORKSPACE}/${REPO_NAME}" ]; then
    echo "Cloning controller scaffold repository..."
    git clone "${REPO_URL}" "${WORKSPACE}/${REPO_NAME}"
  fi

  cd "${WORKSPACE}/${REPO_NAME}"

  ansible-playbook controller.yml \
    -e controller_env="${CONTROLLER_ENV}" \
    -e controller_ansible_core_version="${SELECTED_VERSION}" \
    -e controller_project_root="${CONTROLLER_PROJECT_ROOT}" \
    -e controller_venv_root="${CONTROLLER_VENV_ROOT}"

  deactivate
  exit 0
fi

# ------------------------------------------------------------------------------
# Default exit / handoff
# ------------------------------------------------------------------------------

deactivate

cat <<EOF

Bootstrap complete.

Ephemeral Ansible environment created:
  ${VENV_PATH}

To use it:

  source ${VENV_PATH}/bin/activate

No controller scaffold was run.
EOF

