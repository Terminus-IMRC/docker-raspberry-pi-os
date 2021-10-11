#!/usr/bin/env bash

set -e -u -x -o pipefail

IMAGE="$1"
URL="$2"

if [[ $IMAGE = *-armhf ]]; then
	ARCH='armhf'
	PLATFORM='linux/arm32/v6'
else
	ARCH='arm64'
	PLATFORM='linux/arm64/v8'
fi

BASENAME="${URL##*/}"
BASENAME="${BASENAME%.zip}"

curl -L 'https://www.raspberrypi.org/raspberrypi_downloads.gpg.key' | gpg --import -

curl -LO "$URL"

if curl -LO "$URL.sig"; then
	gpg --verify "$BASENAME.zip.sig" "$BASENAME.zip"
	rm "$BASENAME.zip.sig"
fi

if curl -LO "$URL.sha1"; then
	sha1sum -c "$BASENAME.zip.sha1"
	rm "$BASENAME.zip.sha1"
fi

if curl -LO "$URL.sha256"; then
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

export DOCKER_BUILDKIT=1
sudo tar Ccf mnt/ - . | docker import --change 'CMD ["/bin/bash"]' --platform "$PLATFORM" - "$IMAGE"

sudo umount mnt/boot/ mnt/
rmdir mnt/
rm "$BASENAME.img"
