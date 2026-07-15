#!/usr/bin/env bash
set -euo pipefail

apt install -y dpkg-dev devscripts sbuild
usermod --add-subuids 100000-165535 $USER
usermod --add-subgids 100000-165535 $USER

PACKAGES=(
  alembic-graphics
  openexr
  pink-pony
  calligra
  exactimage
  field3d
  freeimage
  gmic
  gst-plugins-bad1.0
  kf6-kimage-format
  krita
  libvigraimpex
  openvdb
  povray
  swayimg
  synfig
  darktable
  hugin
  opencolorio
  openimageio
  slic3r-prusa
  blender
)

for pkg in "${PACKAGES[@]}"; do
  echo "=== $pkg ==="
  # apt source downloads and unpacks in one step.
  apt-get source -t testing "$pkg"
  # The unpacked tree is the newest dir holding debian/changelog.
  srcdir=$(ls -dt */ | while read -r d; do [ -f "$d/debian/changelog" ] && echo "$d" && break; done)
  (
    echo "ok to build $pkg in $srcdir"
    cd "$srcdir"
    apt build-dep -y ./
    dch -i -D experimental "rebuild test"
    sbuild -d experimental
  )
done
