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
    if [[ -f ${gpg_files_path}public.key && -f ${gpg_files_path}private.key ]]; then
        echo "restore GPG keys"
        gpg --import "${BACKUP_FOLDER}gpg/public.key"
        gpg --import "${BACKUP_FOLDER}gpg/private.key"
        if [[ -f ${gpg_files_path}trust.key  ]];then
            gpg --import-ownertrust "${BACKUP_FOLDER}gpg/trust.key"
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
    mkdir -p ${ssh_folder}
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

# function _fix_symlink(){
#     local path=${1}
#     local filename=${2}
#     local target=${3}

#     ls -a "${target}" | grep "${filename}"
#     if [[ ! -L "${path}/${filename}" || ! $(readlink -f "${path}/${filename}")=${target} ]];
#     then
#         if [[ -f "${target}/${filename}" ]];then
#             echo "backup existing file in ${target}/${filename}"
#             # rm "${target}/${filename}"
#         else
#             echo "${target}/${filename} do not exist"
#         fi
#         echo "create symlink to ${path}/${filename} in ${target}"
#         # ln -s "${path}/${filename}" "$target"
#     fi
# }

# function restore_crons {
#     JOURNALCTL_CRON_FILES_PATH="${PWD}/journalctl_crons"

#     _fix_symlink ${JOURNALCTL_CRON_FILES_PATH} update.service /etc/systemd/system
#     # _fix_symlink ${JOURNALCTL_CRON_FILES_PATH} update.timer /etc/systemd/system

#     # sudo sudo systemctl --user daemon-reload && sudo systemctl enable --user update.service && sudo systemctl --user enable update.timer
# }

################
# Bashrc
################
function restore_vscode {
    mkdir -p $HOME/.config/Code/User
    if [[ ! -L "$HOME/.config/Code/User/settings.json" ]]; then
        echo "Save current ${HOME}/.config/Code/User/settings.json to ${HOME}/.config/Code/User/settings.json.back"
        mv "${HOME}/.config/Code/User/settings.json" "${HOME}/.config/Code/User/settings.json.back"
    else
        rm "${HOME}/.config/Code/User/settings.json"
    fi
    
    echo "create ${HOME}/.config/Code/User/settings.json symlink"
    ln -s ${PWD}/vscode/settings.json ${HOME}/.config/Code/User/
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
    echo "Create the docker group if it does not exist"
    sudo groupadd docker
    echo "Add your user to the docker group."
    sudo usermod -aG docker $USER
    echo "check that user is in group"
    groups ${USER}
    
    echo "Log in to the new docker group (to avoid having to log out / log in again)"
    newgrp docker
    sudo su ${USER}
    echo "Enable and start docker"
    sudo systemctl enable docker
    echo "!! restart required"
}


################
# SYSTEM
################
function restore_system {
    # echo "update arch mirror list"
    # sudo reflector --save /etc/pacman.d/mirrorlist --country France,Germany,Belgium,Netherland --protocol https --latest 10
    
    echo "restore installed packages"
    yay -Syyu
    yay --noconfirm -Sy $(grep -Ev ^'(#|$)' "${PWD}/pacman.txt")
}


################
# SYSTEMD
################
function restore_startup_services {
    echo "enable services"
    sudo systemctl enable bluetooth.service
    sudo systemctl enable docker.service
}

function restore_starship {
    CONFIG_PATH="${HOME}/.config"
    DOTFILES_STARSHIP_CONFIG_FILE_PATH="${PWD}/.config/starship.toml"
    if [ ! -d "${N_PATH}" ];
    then
        mkdir -p "${CONFIG_PATH}"
    fi
    
    STARSHIP_CONFIG_FILE="starship.toml"
    if [ -f "${CONFIG_PATH}/${STARSHIP_CONFIG_FILE}" ];
    then
        if [ ! -L "${CONFIG_PATH}/${STARSHIP_CONFIG_FILE}" ];
        then
            echo "backup existing starship config to ${CONFIG_PATH}/${STARSHIP_CONFIG_FILE}.back"
            mv "${CONFIG_PATH}/${STARSHIP_CONFIG_FILE}" "${CONFIG_PATH}/${STARSHIP_CONFIG_FILE}.back"
            echo "create new symlink to ${DOTFILES_STARSHIP_CONFIG_FILE_PATH} in ${CONFIG_PATH}"
            ln -s ${DOTFILES_STARSHIP_CONFIG_FILE_PATH} ${CONFIG_PATH}
        else
            if [ ! $(readlink -f "${CONFIG_PATH}/${STARSHIP_CONFIG_FILE}")=${DOTFILES_STARSHIP_CONFIG_FILE_PATH} ]
            then
                echo "fix symlink"
                ln -sf ${DOTFILES_STARSHIP_CONFIG_FILE_PATH} ${CONFIG_PATH}
            else
                echo "symlink to dotfiles is ok, nothing to do"
            fi
        fi
    else
        echo "create new symlink to ${DOTFILES_STARSHIP_CONFIG_FILE_PATH} in ${CONFIG_PATH}"
        ln -s ${DOTFILES_STARSHIP_CONFIG_FILE_PATH} ${CONFIG_PATH}
    fi
    
    
}

################
# GCLOUD
################
function init_gcloud {
    gcloud init
    gcloud auth application-default login
    gcloud auth configure-docker
    gcloud components install gke-gcloud-auth-plugin
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
    restore_docker
    restore_startup_services
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
