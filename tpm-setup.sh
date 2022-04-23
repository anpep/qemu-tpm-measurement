#!/bin/sh
if [ $(id -u) -ne 0 ]
then
	echo "this script needs to be run as root"
	exit 1
fi
rm -rf /tmp/tpm0
mkdir -p /tmp/tpm0
chmod -R 777 /tmp/tpm0/
swtpm socket \
	--tpm2 \
	--tpmstate dir="/tmp/tpm0" \
	--ctrl type=unixio,path="/tmp/tpm0/swtpm-sock",uid=0,gid=0 \
	--log level=20