#!/bin/sh
if [ $(id -u) -ne 0 ]
then
	echo "this script needs to be run as root"
	exit 1
fi
qemu-system-x86_64 \
	-bios /usr/share/ovmf/OVMF.fd \
	-hda ubuntu-core-20-amd64.img \
	-net nic \
	-net user,hostfwd=tcp::2222-:22 \
	--enable-kvm \
	-cpu host \
	-m 512M \
	-chardev socket,id=chrtpm,path=/tmp/tpm0/swtpm-sock \
	-tpmdev emulator,id=tpm0,chardev=chrtpm \
	-device tpm-tis,tpmdev=tpm0
