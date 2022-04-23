# TPM measurement under QEMU with OVMF and `swtpm`
## Introduction
Measured boot is a security mechanism which leverages the TPM on a hardware
platform in order to detect unwanted modifications of the platform configuration,
which could potentially lead to degraded security and trust in the software
environment.

Linux allows for the measurement of boot configuration by exposing the TPM event
log in the `securityfs` root at `/sys/kernel/security`.

## Environment setup
In order to test measured boot on QEMU, the following software dependencies are
required:
- A recent version of QEMU. In this document, we are assuming version `6.2.0`
  (the one we tested against) is used.
- The `swtpm` TPM emulator software.
- The `ovmf` package, which contains a port of the Tianocore firmware for QEMU.
  This package places the `OVMF.fd` firmware image on `/usr/share/ovmf/`
- A Linux-based image compiled with TPM support. We downloaded the
  [latest Ubuntu Core stable image](https://cdimage.ubuntu.com/ubuntu-core/20/stable/current/)
  and booted it directly.

We can trivially install this dependencies with `apt`:
```
$ sudo apt install qemu-system-x86 swtpm
```

## The `tpm-setup.sh` script
This script will create a virtual TPM 2.0 module with its state directory at
`/tmp/tpm0` and start listening for control commands in a UNIX domain socket.
> Because we are binding to UNIX domain sockets, you will need to execute this
> script as `root`.

Simply issue the following command to start the `swtpm` daemon:
```
# ./tpm-setup.sh
```

## The `start-qemu.sh` script
This script simply contains the command-line arguments to properly start the
Ubuntu Core VM. The important bits are:
- `-bios /usr/share/ovmf/OVMF.fd`: don't use the default BIOS image (SeaBIOS),
  and boot Tianocore instead.
- `-hda ubuntu-core-20-amd64.img`: boot from this disk image (we downloaded
  and `unxz`'d the latest Ubuntu Core stable image). You might get a warning
  from QEMU because we are allowing write operations on this image; however,
  the OS won't overwrite anything in the first sector so it can be ignored.
- `-chardev socket,id=chrtpm,path=/tmp/tpm0/swtpm-sock`: bind the UNIX socket
  for TPM control commands to a character device (`chrtpm`).
- `-tpmdev emulator,id=tpm0,chardev=chrtpm`: use a TPM emulator which we can
  send control commands to through the `chrtpm` character device.
- `-device tpm-tis,tpmdev=tpm0`: create the TPM hardware interface.

Since we are writing commands to the `root`-owned TPM control socket, we need
to execute this script as `root`:
```
# ./start-qemu.sh
```

> ### Note for Ubuntu Core
> The first time you issue this command, the OS will reboot a few times. After
> that, you can configure Ubuntu Core by entering your Ubuntu One e-mail address.
> This is done in order to fetch your public SSH keys, which will be put in the
> authorized keys list automatically after boot.

After the OS is configured and booted up, open a SSH session (we are redirecting
the SSHd port to `localhost:2222`) and you'll be able to verify the measured boot
was performed successfully:
![Screenshot showing a successful measured boot](https://github.com/anpep/qemu-tpm-measurement/blob/trunk/screenshot.png)

> ### Note for Ubuntu Core
> Since this is a Snap-only Ubuntu distribution, you won't find the `strings`
> program nor will be able to install the `binutils` package where it is included.
> In our test environment, we copied over the remote file using `scp` and analyzed
> its contents in the host OS.
