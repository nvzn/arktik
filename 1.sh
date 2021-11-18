SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [ -f "${SCRIPT_DIR}/include.sh" ]; then
    source "${SCRIPT_DIR}/include.sh"
fi

if [ -f "${SCRIPT_DIR}/$rcfile" ]; then
    source "${SCRIPT_DIR}/$rcfile"
fi

if [ -f "${SCRIPT_DIR}/common.sh" ]; then
    source "${SCRIPT_DIR}/common.sh"
fi

enable_networking() {
    [[ $(pacman -Q networkmanager) ]] && systemctl enable --now NetworkManger
}

set_root_passwd() {
    usermod --password $(openssl passwd -i "toor") root
}

add_user_passwd() {
    useradd -m "$1" -G "$2"
    passwd -e "$1"
}

set_users() {
    # Enable sudo group
    sed -i 's/^# %sudo[[:blank:]]\+ALL=(ALL) ALL/%sudo ALL=(ALL) ALL/' /etc/sudoers
    groupadd sudo

    # Change default shell
    chsh -s /bin/zsh root
    sed -i 's;SHELL=.*;SHELL=/bin/zsh' /etc/default/useradd

    # Set passwords and users
    set_root_passwd
    add_user_passwd nvzn sudo
}