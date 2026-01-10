#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Early argument handling (must come first, no side effects)
# ------------------------------------------------------------------------------

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<EOF
Usage: ./bootstrap.sh [options]

Options:
  --ansible-core <version>   Explicit ansible-core version
                             (default: 2.16.6)
  --dry-run                  Print actions and exit without changes
  --help                     Show this help and exit

Default behavior:
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

# ------------------------------------------------------------------------------
# Defaults
# ------------------------------------------------------------------------------

DEFAULT_ANSIBLE_CORE_VERSION="2.16.6"
ANSIBLE_CORE_VERSION=""
DRY_RUN=false

# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
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
# Apply default version if none supplied
# ------------------------------------------------------------------------------

if [[ -z "$ANSIBLE_CORE_VERSION" ]]; then
  ANSIBLE_CORE_VERSION="$DEFAULT_ANSIBLE_CORE_VERSION"
fi

# ------------------------------------------------------------------------------
# Prerequisite checks
# ------------------------------------------------------------------------------

PYTHON3="$(command -v python3 || true)"
ANSIBLE="$(command -v ansible || true)"

if [[ -n "$ANSIBLE" ]]; then
  echo "Ansible already present in PATH ($ANSIBLE). Exiting."
  exit 0
fi

if [[ -z "$PYTHON3" ]]; then
  echo "Python 3 not found. Please install python3."
  exit 1
fi

if ! python3 - <<'EOF' >/dev/null 2>&1
import venv
EOF
then
  echo "Python venv module not available. Please install python3-venv."
  exit 1
fi

VENV_DIR="/tmp/ve-ansible"

# ------------------------------------------------------------------------------
# Dry-run mode
# ------------------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN] Would create venv at: $VENV_DIR"
  echo "[DRY-RUN] Would install: ansible-core==$ANSIBLE_CORE_VERSION"
  exit 0
fi

# ------------------------------------------------------------------------------
# Create venv (idempotent)
# ------------------------------------------------------------------------------

if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv --system-site-packages "$VENV_DIR"
fi

# ------------------------------------------------------------------------------
# Install ansible-core
# ------------------------------------------------------------------------------

if [[ -f "$VENV_DIR/bin/activate" ]]; then
  # shellcheck disable=SC1091
  source "$VENV_DIR/bin/activate"

  python -m pip install --upgrade pip
  python -m pip install "ansible-core==$ANSIBLE_CORE_VERSION"

  deactivate

  cat <<EOF

Ansible has been temporarily installed to:

  $VENV_DIR

Version installed:
  ansible-core $ANSIBLE_CORE_VERSION

To activate the virtual environment:

  source $VENV_DIR/bin/activate

To verify Ansible:

  ansible --version

To exit the virtual environment:

  deactivate

EOF
else
  echo "ERROR: $VENV_DIR/bin/activate not found."
  exit 1
fi
