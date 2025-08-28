#!/bin/bash

# source .env folder
set -a; source .env; set +a

# source "./scripts/utils/symlinks"


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
function install_docops {
    local dl_dir=".vendors/docopts"
    mkdir "${dl_dir}"
    cd "${dl_dir}"

    required_files=("get_docopts.sh" "docopts.sh" "VERSION")
    for filename in $required_files
    do
        curl 'https://raw.githubusercontent.com/docopt/docopts/refs/heads/master/${filename}' > ${filename}
    done

    sudo chmod +x get_docopts.sh
    ./get_docopts.sh

    sudo cp docopts docopts.sh /usr/local/bin

    cd -
}

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
# Nvim
################
function setup_nvim {
    local symlink_path="$HOME/.config/nvim"
    local symlink_target="${PWD}/bashrc/tools/nvim"

    upsert_symlink "${symlink_path}" "${symlink_target}"
}

function setup_lvim {
    setup_nvim

    local symlink_path="$HOME/.config/lvim"
    local symlink_target="${PWD}/bashrc/tools/lvim"

    upsert_symlink "${symlink_path}" "${symlink_target}"
}



# function restore_crons {
#     JOURNALCTL_CRON_FILES_PATH="${PWD}/journalctl_crons"

#     _fix_symlink ${JOURNALCTL_CRON_FILES_PATH} update.service /etc/systemd/system
#     # _fix_symlink ${JOURNALCTL_CRON_FILES_PATH} update.timer /etc/systemd/system

#     # sudo sudo systemctl --user daemon-reload && sudo systemctl enable --user update.service && sudo systemctl --user enable update.timer
# }

################
# VsCode
################
function restore_vscode {
    echo "# Create symlink to dotfiles settings"
    local vscode_settings_folder="$HOME/.config/Code/User"
    local vscode_settings_filename="settings.json"
    local vscode_settings_source="${PWD}/vscode/${vscode_settings_filename}"
    upsert_symlink "${vscode_settings_folder}/${vscode_settings_filename}" "${vscode_settings_source}"

    echo "# Create symlink to dotfiles extensions"
    local vscode_extensions_folder="${vscode_settings_folder}/extensions"
    local vscode_extensions_filename="extensions.json"
    local vscode_extensions_source="${PWD}/vscode/${vscode_extensions_filename}"
    upsert_symlink "${vscode_extensions_folder}/${vscode_extensions_filename}" "${vscode_extensions_source}"
}


################
# GIT Config
################
function restore_git {
    local gitignore_global_system_path="${HOME}/.gitignore_global"
    local gitignore_global_symlink_target="${PWD}/gitfiles/.gitignore_global"

    local git_files=(".gitignore_global" ".gitconfig")
    for git_file in ${git_files[@]}; do
        upsert_symlink "${HOME}/${git_file}" "${PWD}/gitfiles/${git_file}"
    done
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
    source "./bashrc/cloudproviders/gcloud"

    gcloud_config
}



################
# TFEnv
################
function init_tfenv {
    echo "Add current user to TfEnv"
    sudo usermod -a -G tfenv ${USER}
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
    init_tfenv
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
