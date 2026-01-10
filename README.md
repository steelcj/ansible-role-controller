# ansible-role-controller
This repository provides a bootstrap entry point and supporting materials for bringing an Ansible Controller into existence.

## Create a workspace

Here we set up a space that can be used to bootstrap Ansible controller nodes

```bash
mkdir ~/projects/infra/ansible/
```

## Download and Run the venv bootstrap.sh script

This script will bootstrap an ***ephemeral*** Python venv and install the ansible-core you want to run

```bash
cd ~/projects/infra/ansible/
wget https://raw.githubusercontent.com/steelcj/ansible-role-controller/main/ansible-bootstrap.sh
```

### Bootstrap, then activate your ephemeral venv

Specify the ansible core version that you want to use as an argument or change the version in the script if you prefer.

```bash
./bootstrap.sh --ansible-core 2.20.1
```

Activate your new venv

```bash
source /tmp/ve-ansible/bin/activate
```

## Clone this role

```bash
git clone git@github.com:steelcj/ansible-role-controller.git
```

## Bootstrap Permanent Controller and Venv

 Move into the role directory you just cloned

```bash
cd ansible-role-controller
```



example 1:

```bash
ansible-playbook controller.yml \
  -e controller_env=dev \
  -e controller_ansible_core_version=2.20.0 \
  -e controller_project_root="/home/initial/projects/ansible/{{ controller_ansible_core_version }}/{{ controller_env }}"
```

example 2

```bash
ansible-playbook controller.yml \
  -e controller_env="stage" \
  -e controller_ansible_core_version="2.20.0" \
  -e controller_project_root="/home/initial/projects/ansible/2.20.0/stage" \
  -e controller_venv_root="/home/initial/.venvs/ansible/2.20.0/stage"
```

