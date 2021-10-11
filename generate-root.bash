#!/usr/bin/env bash

set -e -u -x -o pipefail

URL_ARMHF="$1"
URL_ARM64="$2"

for URL in "$URL_ARMHF" "$URL_ARM64"; do

	if [ -z "$URL" ]; then
		continue
	fi

	if [ "$URL" = "$URL_ARMHF" ]; then
		ARCH='armhf'
	else
		ARCH='arm64'
	fi

	BASENAME="${URL##*/}"
	BASENAME="${BASENAME%.zip}"

	curl -LO "$URL"

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
	rm "$BASENAME.zip"

	partx -bs "$BASENAME.img"
	PART1_START=$(partx -bgr -o START -n 1 "$BASENAME.img")
	PART2_START=$(partx -bgr -o START -n 2 "$BASENAME.img")
	PART1_SIZE=$(partx -bgr -o SIZE -n 1 "$BASENAME.img")
	PART2_SIZE=$(partx -bgr -o SIZE -n 2 "$BASENAME.img")

	mkdir mnt/
	sudo mount -o "ro,loop,offset=$((PART2_START * 512)),sizelimit=$PART2_SIZE" -t ext4 "$BASENAME.img" mnt/
	sudo mount -o "ro,loop,offset=$((PART1_START * 512)),sizelimit=$PART1_SIZE" -t vfat "$BASENAME.img" mnt/boot/

	sudo tar Ccf mnt/ - . > "root-$ARCH.tar"

	sudo umount mnt/boot/ mnt/
	rmdir mnt/
	rm "$BASENAME.img"

done
