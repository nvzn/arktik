SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

./0.sh
arch-chroot /mnt root/arktik/1.sh