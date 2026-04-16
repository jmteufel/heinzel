# Image Format Conversion

## qemu-img

```
# qcow2 → raw
qemu-img convert -f qcow2 -O raw image.qcow2 \
  image.raw

# raw → qcow2
qemu-img convert -f raw -O qcow2 image.raw \
  image.qcow2
```

## Writing to Disk

```
# Write raw image to disk or partition
dd if=image.raw of=/dev/sdX bs=4M status=progress
```

When writing to a **partition** (not a full disk),
do not `dd` a full-disk image directly — the
partition table embedded in the image will
overwrite adjacent partitions. Instead, mount the
image and extract the filesystem, or use
`qemu-img` to resize/extract the partition first.
