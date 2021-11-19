# (0) Ask user for a) user override layout, b) default layouts, c) gui
#   a: sets OVERRIDE_LAYOUT=true, calls user callback
#   b: calls default functions
#   c: goes to (1)
# (1) Asks a)

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


start_menu() {
    if [ "${1}" = "" ]; then
        nextitem="."
    else
        nextitem="$1"
    fi
    options=()
    options+=("$txteditrc" "$EDITOR $rcfile")
    options+=("$txtdrives" "")
    #options+=("$txtlvm" "Logical Volume Management")
    #options+=("$txtluks" "")
    #options+=("$txtmount" "")
    #options+=("$txtstartinstall" "")
    sel=$(whiptail --backtitle "${apptitle}" --title "Main menu" --menu "" \
        --cancel-button "$txtexit" --default-item "${nextitem}" 0 0 0 \
        "${options[@]}" 3>&1 1>&2 2>&3)
    if [ "$?" = "0" ]; then
        case "$sel" in
            "$txteditrc")
                menu_editrc
                nextitem="${txtdrives}"
            ;;
            "$txtdrives")
                menu_drives
                # nextitem="${txtlvm}"
            ;;
            *) break ;;
            # "$txtlvm")
            #     nextitem="${txtluks}"
            # ;;
            # "$txtluks")
            #     nextitem="${txtmount}"
            # ;;
            # "$txtmount")
            #     nextitem="${txtstartinstall}"
            # ;;
            # "$txtstartinstall")
            #     zsh
            #     nextitem="${txtstartinstall}"
        esac
        start_menu "$nextitem"
    else
        clear
    fi
}

menu_editrc() {
    $EDITOR "${SCRIPT_DIR}/$rcfile"
    source "${SCRIPT_DIR}/$rcfile"
    set_console_keymap
    set_locale

}

menu_drives() {
    opts=$(lsblk -pndlo NAME,SIZE -e 7,11)
    options=()
    OIFS=$IFS
    IFS=$'\n'
    for opt in $opts; do
        options+=("$opt" "")
    done
    IFS=$OIFS
    sel=$(whiptail --backtitle "${apptitle}" --title "$txtdrives" --menu "" \
        0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
    if [ "$?" = "0" ]; then
        menu_partition_mode $(echo ${sel%%\ *})
    fi
}

menu_partition_mode() {
    drive="$1"
    options=()
    options+=("$txtautopartition" "")
    options+=("cfdisk" "")
    options+=("cgdisk" "")
    options+=("parted" "")
    options+=("fdisk" "")
    options+=("gdisk" "")
    sel=$(whiptail --backtitle "${apptitle}" --title "$txtpartitionmode" \
        --menu "$drive" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
    if [ "$?" = "0" ]; then
        clear

        if [[ $DRIVE =~ "nvme" ]]; then
            local part_pre="${drive}p"
        else
            local part_pre="${drive}"
        fi

        case "$sel" in
            "$txtautopartition")
                auto_partition $drive $part_pre
                ekko "System ready to be mounted for installation"
            ;;
            "$txtuserpartition")
                user_partition $drive $part_pre
                ekko "System ready to be mounted for installation"
            ;;
            *)
                drop_to_tty=true
            ;;
            # "cfdisk")
            #     cfdisk $drive
            # ;;
            # "cgdisk")
            #     cgdisk $drive
            # ;;
            # "parted")
            #     parted $drive
            # ;;
            # "fdisk")
            #     fdisk $drive
            # ;;
            # "gdisk")
            #     gdisk $drive
            # ;;
        esac
        if [ "$drop_to_tty" == "true" ]; then
            ekko ""
        fi
    fi
}

auto_partition() {
    local drive="$1"
    local part_pre="$2"
    unmount_filesystem
    create_gpt_label $drive $part_pre
    create_default_parts $drive $part_pre
    format_parts $drive $part_pre
    pressanykey
}

unmount_filesystem() {
    ekko "Unmounting everything on /mnt..."
    umount -R /mnt
    local swapdev="$(lsblk -o PATH,MOUNTPOINTS | grep "\[SWAP\]" | awk '{print $1}')"
    [[ $swapdev ]] && swapoff $swapdev
}

create_gpt_label() {
    drive="$1"
    [ -z "$drive" ] && return
    ekko "Creating new GPT label on ${drive}..."
    sgdisk -Z "$1"
    sgdisk -o "$1"
}

create_default_parts() {
    drive="$1"
    part_pre="$2"

    ekko "Creating default partition scheme on ${drive}..."
    # sgdisk --new=partn:start:end --typecode=partnum:(hex|GUID) --change-name=partn:name
    # sgdisk -n 1::+1M -t 1:ef02 -c 1:"BIOS" ${drive}  # Optional BIOS partition for GRUB
    # if [[ ! -d "/sys/firmware/efi" ]]; then
    #     sgdisk -A 1:set:2 ${DISK}  # Set BIOS bootable flag
    # fi
    sgdisk -n 1::512M  -t 1:ef00 -c 1:"EFI"  ${drive}
    sgdisk -n 2::+512M -t 2:8300 -c 2:"boot" ${drive}

    rootnum=3
    if [[ ! "$SWAPSIZE" == "0" ]]; then
        memsize=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')
        swapsize="$((${memsize}/1000/1000*1024))M"
        [[ "$SWAPSIZE" ]] && swapsize="$SWAPSIZE"

        ekko "Creating $swapsize swap partition..."
        sgdisk -n 3::+${swapsize} -t 3:8300 -c 3:"arch" ${drive}

        swappart="${part_pre}3" && swaplabel="swap"
        rootnum=4
    fi

    sgdisk -n ${rootnum}:: -t ${rootnum}:8300 -c ${rootnum}:"arch" ${drive}

    efipart="${part_pre}1" && efilabel="EFI"
    bootpart="${part_pre}2" && bootpartfs="btrfs" && bootlabel="boot"
    rootpart="${part_pre}${rootnum}" && rootpartfs="btrfs" && rootlabel="arch"
}

prompt_wifi() {
    try_again=false
    while true; do
        if $try_again; then
            ekko_error "Try again!"
        fi
        try_again=true

        nekko "${lblu}" && iwctl device list
        nekko "${lblu}" && iwctl station list
        ekko_prompt "Wireless adapter/station:"
        read wl
        nekko "${lblu}" && iwctl station "$wl" scan || continue
        nekko "${lblu}" && iwctl station "$wl" get-networks || continue
        ekko_prompt "Network:"
        read nw
        nekko "${lblu}" && iwctl station "$wl" connect "$nw" || continue
        break
    done
}

# Requires:
# efipart, efilabel
# bootpart, bootpartfs, bootlabel
# rootpart, rootpartfs, rootlabel
format_parts() {
    drive="$1"
    part_pre="$2"

    ekko "Formatting $rootpart as $rootpartfs..."
    format_as $rootpartfs $rootpart $rootlabel

    if [ "$efipart" ]; then
        ekko "Formatting $efipart as fat32..."
        format_as fat32 $efipart $efilabel
    fi

    if [ "$bootpart" ]; then
        ekko "Formatting $bootpart as $bootpartfs..."
        format_as $bootpartfs $bootpart $bootlabel
    fi

    if [ "$swappart" ]; then
        ekko "Setting up [SWAP] on $swappart..."
        mkswap $swappart -L $swaplabel
    fi
}

format_root_btrfs() {
    mount "$1" /mnt
    btrfs subvolume create /mnt/@
    umount /mnt
}

format_as() {
    local fsfmt="$1"
    local partition="$2"
    local label="$3"

    case "$fsfmt" in
        fat32|vfat|fat)
            mkfs.vfat -F32 -n "$label" "$partition"
        ;;
        btrfs)
            mkfs.btrfs -f -L "$label" "$partition"
            pkgsneeded="${pkgsneeded} btrfs-progs"
            if [[ "$rootpart" == "$partition" ]]; then
                format_root_btrfs "$partition"
            fi
        ;;
        ext4)
            mkfs.ext4 -L "$label" "$partition"
        ;;
    esac
}

mount_parts() {
    ekko "Mounting $rootpart to /mnt..."
    mount $rootpart /mnt

    if [ "$efipart" ]; then
        ekko "Mounting $efipart to /mnt/efi..."
        mkdir /mnt/efi && mount $efipart /mnt/efi
    fi

    if [ "$bootpart" ]; then
        ekko "Mounting $bootpart to /mnt/boot..."
        mkdir /mnt/boot && mount $bootpart /mnt/boot
    fi

    if [ "$swappart" ]; then
        ekko "Enabling [SWAP] on $bootpart..."
        swapon $swappart
    fi
}

configure_pacman() {
    # Tries to find the minimum possible match, and uncomments it
    # This makes it possible to change an option's value
    for opt in "${PACOPTS[@]}"; do
        for i in `seq 1 ${#opt}`; do
            local mtch="$(cat /etc/pacman.conf | grep "^#${opt:0:$i}")"
            if [ "$(echo "$mtch" | wc -l)" == "1" ]; then
                [[ "${mtch}" ]] && sed -i "s;^${mtch}.*;${opt};" /etc/pacman.conf
                break
            fi
        done
    done
    retry=true
    while $retry; do
        retry=false
        if [[ -n "$PACCACHE" ]]; then
            if [[ -n "$CACHEUUID" ]]; then
                DEVPATH=$(lsblk --output PATH,UUID | awk "/$CACHEUUID/ {print  \$1}")
                if [[ "$DEVPATH" == "" ]]; then
                    ekko_error "Cache device with UUID=$CACHEUUID not found!"
                    retry=true
                    ekko_exit_continue "Press any key to retry, Esc key to exit"
                    if [ "$?" == "1"]; then
                        retry=false
                    fi
		else
		    ekko "Mounting cache device (UUID=$CACHEUUID) to /mnt$CACHEMOUNT..."
                    mkdir -p "/mnt$CACHEMOUNT"
                    mount "$DEVPATH" "/mnt$CACHEMOUNT"
                fi
            fi
	    ekko "Setting pacman CacheDir=/mnt$PACCACHE"
            #sed -i "s|^\(#\(CacheDir    \)= .*\)|\1\n\2= /mnt$PACCACHE|" /etc/pacman.conf
	    sed -i "s;^#\(CacheDir    \)= .*;\1= /mnt$PACCACHE;" /etc/pacman.conf
        fi
    done
}

bootstrap_target() {
    pkgs=($(cat "${SCRIPT_DIR}/pacstrap.pkgs" | awk -F '#' '{print $1}'))
    pkgs+=($(echo $pkgsneeded))

    pacflags="$pacflags -c"
    ekko "Installing base system packages to new root..."
    ekko "pacstrap ${pacflags} /mnt "${pkgs[@]}" --needed --noconfirm"
    pacstrap ${pacflags} /mnt "${pkgs[@]}" --needed --noconfirm
    ekko "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab

    #>TODO copy script to /mnt/root
    ekko "Copying script files to /mnt/root/arktik..."
    mkdir -p /mnt/root/arktik
    cp -r ${SCRIPT_DIR}/* /mnt/root/arktik/
    ekko "Copying host mirrorlist to new root..."
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
}

main() {
    set_console_keymap
    setlocale

    start_menu

    mount_parts
    #prompt_wifi
    configure_pacman
    bootstrap_target
}

main


DONTRUN() {
    asdfasdfasdf=$1
    # dmsetup ls --target crypt
    # curl -LJO https:/.../.git LJO
    #https://github.com/MatMoul/archfi/blob/master/archfi
}


# start_menu
#     menu_editrc
#     menu_drives
#         menu_partition_mode
#             auto_partition
#             user_partition
#             (cfdisk,...)
# format_parts
# mount_parts
# set_console_keymap
# edit_
