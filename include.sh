gekko() {
    echo -ne "$@"
}

nekko() {
    gekko "$@"
    gekko "\n"
}

ekko() {
    local c0
    local c1
    if [[ "$1" == "-c" ]]; then
        c0=$2;
        c1=$c0
        shift; shift
    else
        c0="$bold$lblu"
        c1="$bold$lwht"
    fi
    nekko "$c0::$rs $c1$@ $c0$rs"
}

ekko_title() {
    nekko "------------------------------------------------------------------------"
    ekko -c "$bold$lgrn" $@
    nekko "------------------------------------------------------------------------"
}

ekko_prompt() {
    local style0="$lblu$bold"
    local style1="$lwht$bold"
    gekko "$style0::$rs $style1$@$rs "
}

ekko_exit_continue() {
    ekko_prompt "$@"
	[[ $BASH_VERSION ]] && read -sn1 key
    [[ $ZSH_VERSION ]] && read -sk key
    nekko
    case $key in
        $'\e') return 1;;
        *) return 0;;
    esac
}

ekko_style() {
    local style="$1"; shift
    ekko -c "$style" "$style$@$rs"
}

ekko_success() {
    local style="$lgrn$bold"
    ekko_style "$style" "$@"
}

ekko_warn() {
    local style="$lyel$bold"
    ekko_style "$style" "$@"
}

ekko_error() {
    local style="$lred$bold"
    ekko_style "$style" "$@"
}

pressanykey() {
    ekko_prompt "Press any key to continue..."
	[[ $BASH_VERSION ]] && read -sn1
    [[ $ZSH_VERSION ]] && read -sk
    nekko
}

set_color_strings()
{
    local P=$1  # zsh: %{
    local S=$2  # zsh: %}

    # export TERM=xterm-256color

    export bold="${P}$(tput bold)${S}" # Bold mode
    export dim="${P}$(tput dim)${S}"   # Dim mode
    export rev="${P}$(tput rev)${S}"   # Reverse mode
    export smul="${P}$(tput smul)${S}" # Set mode Underline
    export rmul="${P}$(tput rmul)${S}" # Reset mode Underline
    export smso="${P}$(tput smso)${S}" # Set mode Standout
    export rmso="${P}$(tput rmso)${S}" # Reset mode Standout
    export sgr0="${P}$(tput sgr0)${S}" # Reset

    export rs=${sgr0}
    export hc=${bold}
    export inv=${rev}
    export sul=${smul}
    export rul=${rmul}
    export sso=${smso}
    export rso=${rmso}

    export blk="${P}$(tput setaf 0)${S}"
    export red="${P}$(tput setaf 1)${S}"
    export grn="${P}$(tput setaf 2)${S}"
    export yel="${P}$(tput setaf 3)${S}"
    export blu="${P}$(tput setaf 4)${S}"
    export mag="${P}$(tput setaf 5)${S}"
    export cyn="${P}$(tput setaf 6)${S}"
    export wht="${P}$(tput setaf 7)${S}"

    export lblk="${P}$(tput setaf 8)${S}"
    export lred="${P}$(tput setaf 9)${S}"
    export lgrn="${P}$(tput setaf 10)${S}"
    export lyel="${P}$(tput setaf 11)${S}"
    export lblu="${P}$(tput setaf 12)${S}"
    export lmag="${P}$(tput setaf 13)${S}"
    export lcyn="${P}$(tput setaf 14)${S}"
    export lwht="${P}$(tput setaf 15)${S}"

    export bblk="${P}$(tput setab 0)${S}"
    export bred="${P}$(tput setab 1)${S}"
    export bgrn="${P}$(tput setab 2)${S}"
    export byel="${P}$(tput setab 3)${S}"
    export bblu="${P}$(tput setab 4)${S}"
    export bmag="${P}$(tput setab 5)${S}"
    export bcyn="${P}$(tput setab 6)${S}"
    export bwht="${P}$(tput setab 7)${S}"

    export blblk="${P}$(tput setab 8)${S}"
    export blred="${P}$(tput setab 9)${S}"
    export blgrn="${P}$(tput setab 10)${S}"
    export blyel="${P}$(tput setab 11)${S}"
    export blblu="${P}$(tput setab 12)${S}"
    export blmag="${P}$(tput setab 13)${S}"
    export blcyn="${P}$(tput setab 14)${S}"
    export blwht="${P}$(tput setab 15)${S}"
}

function set_color_strings_ansi
{
    export CPRE=$1
    export CSUF=$2
    export rs="${CPRE}\033[0m${CSUF}"    # reset
    export hc="${CPRE}\033[1m${CSUF}"    # hicolor
    export ul="${CPRE}\033[4m${CSUF}"    # underline
    export inv="${CPRE}\033[7m${CSUF}"   # inverse background and foreground
    export blk="${CPRE}\033[30m${CSUF}" # foreground black
    export red="${CPRE}\033[31m${CSUF}" # foreground red
    export grn="${CPRE}\033[32m${CSUF}" # foreground green
    export yel="${CPRE}\033[33m${CSUF}" # foreground yellow
    export blu="${CPRE}\033[34m${CSUF}" # foreground blue
    export mag="${CPRE}\033[35m${CSUF}" # foreground magenta
    export cyn="${CPRE}\033[36m${CSUF}" # foreground cyan
    export wht="${CPRE}\033[37m${CSUF}" # foreground white
    export bblk="${CPRE}\033[40m${CSUF}" # background black
    export bred="${CPRE}\033[41m${CSUF}" # background red
    export bgrn="${CPRE}\033[42m${CSUF}" # background green
    export byel="${CPRE}\033[43m${CSUF}" # background yellow
    export bblu="${CPRE}\033[44m${CSUF}" # background blue
    export bmag="${CPRE}\033[45m${CSUF}" # background magenta
    export bcyn="${CPRE}\033[46m${CSUF}" # background cyan
    export bwht="${CPRE}\033[47m${CSUF}" # background white
    export lblk="${CPRE}\033[30;1m${CSUF}" # foreground black
    export lred="${CPRE}\033[31;1m${CSUF}" # foreground red
    export lgrn="${CPRE}\033[32;1m${CSUF}" # foreground green
    export lyel="${CPRE}\033[33;1m${CSUF}" # foreground yellow
    export lblu="${CPRE}\033[34;1m${CSUF}" # foreground blue
    export lmag="${CPRE}\033[35;1m${CSUF}" # foreground magenta
    export lcyn="${CPRE}\033[36;1m${CSUF}" # foreground cyan
    export lwht="${CPRE}\033[37;1m${CSUF}" # foreground white

}



set_strings() {
    apptitle="Nina's Arktik Installer"
    rcfile="rc.sh"

    txteditrc="Edit RC file"
    txtdrives="Modify Drives"
    txtlvm="LVM"
    txtluks="Encryption"
    txtmount="Mountpoints"
    txtstartinstall="Start Installation"

    txtpartitionmode="Select partition method"
    txtautopartition="Auto partition"
    txtuserpartition="User override partition"

    txtexit="Exit"

}

set_defaults() {
    KEYMAP=us
    FONT=ter-v16n
    LOCALES=("en_IE.UTF-8" "el_US.UTF-8")
    TIMEZONE="UTC"

    EDITOR=vim

    pkgsneeded=()
}

initialize() {
    set_color_strings_ansi
    set_strings
    set_defaults
}

initialize

