#!/usr/bin/env bash

set -e -u -x -o pipefail

URL="$1"
BASENAME="${URL##*/}"
BASENAME="${BASENAME%.zip}"

#curl -LO "$URL"

if curl -LO "$URL.sig"; then
	curl -LO 'https://www.raspberrypi.org/raspberrypi_downloads.gpg.key'
	gpg --import 'raspberrypi_downloads.gpg.key'
	gpg --verify "$BASENAME.zip.sig" "$BASENAME.zip"
fi

if curl -LO "$URL.sha1"; then
	sha1sum -c "$BASENAME.zip.sha1"
fi

if curl -LO "$URL.sha256"; then
	sha256sum -c "$BASENAME.zip.sha256"
fi

unzip "$BASENAME.zip"

PART1_START=$(partx -bgr -o START -n 1 "$BASENAME.img")
PART2_START=$(partx -bgr -o START -n 2 "$BASENAME.img")
PART1_SIZE=$(partx -bgr -o SIZE -n 1 "$BASENAME.img")
PART2_SIZE=$(partx -bgr -o SIZE -n 2 "$BASENAME.img")

mkdir mnt/
mount -o "ro,loop,offset=$PART2_START,sizelimit=$PART2_SIZE" "$BASENAME.img" mnt/
mount -o "ro,loop,offset=$PART1_START,sizelimit=$PART1_SIZE" "$BASENAME.img" mnt/boot/

tar Ccf mnt/ - . > root.tar

umount mnt/boot/ mnt/
