#!/usr/bin/env bash

set -e -u -x -o pipefail

ARCH="$1"
URL="$2"

BASENAME="${URL##*/}"
BASENAME="${BASENAME%.zip}"

curl -fLO "$URL"

if curl -fLO "$URL.sig"; then
	gpg --verify "$BASENAME.zip.sig" "$BASENAME.zip"
	rm "$BASENAME.zip.sig"
fi

if curl -fLO "$URL.sha1"; then
	sha1sum -c "$BASENAME.zip.sha1"
	rm "$BASENAME.zip.sha1"
fi

if curl -fLO "$URL.sha256"; then
	sha256sum -c "$BASENAME.zip.sha256"
	rm "$BASENAME.zip.sha256"
fi

unzip "$BASENAME.zip"
rm "$BASENAME.zip"

partx -bs "$BASENAME.img"
PART1_START=$(partx -bgr -o START -n 1 "$BASENAME.img")
PART2_START=$(partx -bgr -o START -n 2 "$BASENAME.img")
PART1_SIZE=$(partx -bgr -o SIZE -n 1 "$BASENAME.img")
PART2_SIZE=$(partx -bgr -o SIZE -n 2 "$BASENAME.img")

mkdir mnt/
sudo mount -o "ro,loop,offset=$((PART2_START * 512)),sizelimit=$PART2_SIZE" -t ext4 "$BASENAME.img" mnt/
sudo mount -o "ro,loop,offset=$((PART1_START * 512)),sizelimit=$PART1_SIZE" -t vfat "$BASENAME.img" mnt/boot/

sudo tar Ccf mnt/ "root-$ARCH.tar" .

sudo umount mnt/boot/ mnt/
rmdir mnt/
rm "$BASENAME.img"
