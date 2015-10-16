#!ipxe
# /var/lib/tftpboot/smartos.ipxe.tpl
kernel /smartos/$release/platform/i86pc/kernel/amd64/unix -B smartos=true
initrd /smartos/$release/platform/i86pc/amd64/boot_archive
boot
