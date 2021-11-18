KEYMAP=gr
FONT="ter-v12n"
LOCALES=("en_IE.UTF-8" "el_GR.UTF-8")
TIMEZONE="Europe/Athens"
ROOTPASSWD=
ADDUSERS=("nvzn" "nvzn")

# Pacman config based on the TARGET filesystem
PACOPTS=("Color" "ParallelDownloads = 4")
PACCACHE="/mnt/cache/arch/pkg" # Default if empty. Doesn't ask for cache mount
CACHEMOUNT="/mnt/cache"
CACHEUUID="883EDF693EDF4F36"   # Prompt if empty. Custom cache only when $PACCACHE non-empty

# Drive Layout
# OVERRIDE_PARTS=false
# OVERRIDE_FORMAT=false
# OVERRIDE_MOUNT=false
SWAPSIZE=2G                   # "0": No swap,  "": ==memory,


# Install specific
EDITOR=vim


# Partition, LUKS, LVM
user_partition() {
    drive="$1"
    part="$2"
}
