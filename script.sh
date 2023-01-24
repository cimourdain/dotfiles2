#!/bin/bash

# source .env folder
set -a; source .env; set +a


################
# GPG
################
function backup_gpg {
    echo "Backup gpg keys"
    rm -rf ${BACKUP_FOLDER}gpg
    mkdir -p ${BACKUP_FOLDER}gpg
    gpg --export --export-options backup --output "${BACKUP_FOLDER}gpg/public.gpg"
    gpg --export-secret-keys --export-options backup --output "${BACKUP_FOLDER}gpg/private.gpg"
    gpg --export-ownertrust > "${BACKUP_FOLDER}gpg/trust.gpg"
}

function restore_gpg {
    gpg_files_path="${BACKUP_FOLDER}gpg/"
    if [[ -f ${gpg_files_path}public.gpg && -f ${gpg_files_path}private.gpg ]]; then
        echo "restore GPG keys"
        gpg --import "${BACKUP_FOLDER}gpg/public.gpg"
        gpg --import "${BACKUP_FOLDER}gpg/private.gpg"
        if [[-f ${gpg_files_path}trust.gpg  ]];then
            gpg --import-ownertrust "${BACKUP_FOLDER}gpg/trust.gpg"
        else
            echo "WARNING: no gpg trust file found in ${gpg_files_path}"
        fi
    else
        echo "ERROR: No key files found in ${gpg_files_path}"
    fi
    
}


################
# SSH
################
function backup_ssh {
  echo "Backup ssh keys"
  rm -rf ${BACKUP_FOLDER}ssh
  mkdir -p ${BACKUP_FOLDER}ssh
  cp ${HOME}/.ssh/id_rsa* ${BACKUP_FOLDER}ssh
  cp ${HOME}/.ssh/config ${BACKUP_FOLDER}ssh
}

function restore_ssh {
    ssh_files_path="${BACKUP_FOLDER}ssh/"
    ssh_folder=${HOME}/.ssh
    cp -r ${ssh_files_path}* ${ssh_folder}
    chmod 700 ${ssh_folder}
    chmod 644 ${ssh_folder}/config
    chmod 600 ${ssh_folder}/id_*
    chmod 644 ${ssh_folder}/*.pub
}

################
# Bashrc
################
function restore_bashrc {

    if [[ ! -L "$HOME/.bashrc" ]]; then
        echo "Save current .bashrc to $HOME/.bashrc.bak"
        mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
    else
        rm "$HOME/.bashrc"
    fi
    
    echo "create bashrc symlink"
    ln -s ${PWD}/bashrc/.bashrc ${HOME}
}

################
# GIT Config
################
function restore_git {
    if [[ -f ${HOME}/.gitignore_global ]];then
        echo "backup existing gitignore_global"
        mv ${HOME}/.gitignore_global ${HOME}/.gitignore_global.bak
    elif [[ -L ${HOME}/.gitignore_global ]];then
        echo  "delete existing gitignore_global symbolic link"
        rm ${HOME}/.gitignore_global
    else
        echo "no existing file ${HOME}/.gitignore_global"
    fi

    if [[ -f ${HOME}/.gitconfig ]];then
        echo "backup existing gitconfig"
        mv ${HOME}/.gitconfig ${HOME}/.gitconfig.bak
    elif [[ -L ${HOME}/.gitconfig ]];then
        echo  "delete existing gitconfig symbolic link"
        rm ${HOME}/.gitconfig
    else
        echo "no existing file ${HOME}/.gitconfig"
    fi

    echo "create new symlinks to current dotfiles"
    ln -s ${PWD}/gitfiles/.gitignore_global ${HOME}
    ln -s ${PWD}/gitfiles/.gitconfig ${HOME}
}

################
# Docker
################
function restore_docker {
    echo "enable docker to current user"
    # Create the docker group if it does not exist
    sudo groupadd docker
    # Add your user to the docker group.
    sudo usermod -aG docker $USER
    # Log in to the new docker group (to avoid having to log out / log in again)
    newgrp docker
}


################
# SYSTEM
################
function restore_system {
    echo "update arch mirror list"
    sudo reflector --save /etc/pacman.d/mirrorlist --country France,Germany,Finland,Netherland --protocol https --latest 10

    echo "restore installed packages"
    pacman -Syyu
    pacman --noconfirm -Sy $(grep -Ev ^'(#|$)' "${PWD}/pacman.txt")
}


################
# SYSTEMD
################
function restore_startup_services {
    echo "enable services"
    sudo systemctl enable bluetooth.service
    sudo systemctl enable docker.service
}

################
# GCLOUD
################
function init_gcloud {
    gcloud init
    gcloud auth application-default login
    gcloud auth configure-docker
}


################
# MAIN
################
function backup {
  backup_gpg
  backup_ssh
}

function restore {
    restore_system
    restore_bashrc
    restore_git
    restore_gpg
    restore_ssh
}


function init {
    init_gcloud
}

# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi