set_console_keymap() {
    ekko "Setting console keymap and font..."
    setfont $FONT
    loadkeys $KEYMAP
    cat <<EOF > /etc/vconsole.conf
KEYMAP=$KEYMAP
FONT=$FONT
EOF
}

set_locale() {
    ekko "Setting locales..."
    for locale in "${LOCALES[@]}"; do
        sed -i "s/^#$locale/$locale/" /etc/locale.gen
    done
    ekko "> locale-gen"
    locale-gen
    timedatectl --no-ask-password set-timezone "$TIMEZONE"
    timedatectl --no-ask-password set-ntp true
    if [[ "$ZSH_VERSION" ]]; then
        localectl --no-ask-password set-locale LANG="${LOCALES[1]}"
        export LANG="${LOCALES[1]}"
    else
        localectl --no-ask-password set-locale LANG="${LOCALES[0]}"
        export LANG="${LOCALES[0]}"
    fi
    pressanykey
}
