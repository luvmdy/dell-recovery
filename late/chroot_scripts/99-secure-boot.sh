#!/bin/sh

EFI_APP=/usr/lib/dell/x86_64/MokSBStateSet.efi

#test if SB is enabled
efi_vars_dir=/sys/firmware/efi/vars
EFI_GLOBAL_VARIABLE=8be4df61-93ca-11d2-aa0d-00e098032b8c
SB="$efi_vars_dir/SecureBoot-$EFI_GLOBAL_VARIABLE/data"
if [ -e "$SB" ] && \
   [ "$(( $(printf 0x%x \'"$(cat $SB | cut -b1)") & 1 ))" = 1 ]; then
    SECURE_BOOT="1"
fi

#if DKMS was installed and we don't already have secure boot on
#disable module verification
if dpkg-query -l dkms >/dev/null 2>&1 && \
   [ -z "$SECURE_BOOT" ] && \
   [ -f "$EFI_APP" ]; then
    cp "$EFI_APP" /boot/efi/EFI/ubuntu/
    PARTITION_NODE=$(mount | sed '/\/boot\/efi/!d; s, .*,,; s,/dev/,,;')
    DEVICE=$(readlink /sys/class/block/$PARTITION_NODE | sed 's,/$PARTITION_NODE,,; 's,.*/,,'')
    PARTITION_NUMBER=$(cat /sys/class/block/$PARTITION_NODE/partition)
    efibootmgr -C -l '\EFI\ubuntu\MokSBStateSet.efi' -L 'MokSBStateSet' -d /dev/$DEVICE -p $PARTITION_NUMBER
    BOOTNUM=$(efibootmgr | sed '/MokSBStateSet/!d; s,\* .*,,; s,Boot,,')
    efibootmgr -n $BOOTNUM
fi