#!/usr/bin/env bash
set -euo pipefail

apt install -y dpkg-dev devscripts sbuild

# if sbuild fails run this, then log ou and login again
# usermod --add-subuids 100000-165535 $USER
# usermod --add-subgids 100000-165535 $USER
# in a container that works:
# echo "root:100000:65536" > /etc/subuid
# echo "root:100000:65536" > /etc/subgid


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
  srcdir=$(ls -dt */ | while read -r d; do
      [ -f "$d/debian/changelog" ] || continue
      [ "$(dpkg-parsechangelog -l "$d/debian/changelog" -S Source)" = "$pkg" ] && echo "$d" && break
  done)
  (
    echo "ok to build $pkg in $srcdir"
    cd "$srcdir"
    dch -R -D experimental "rebuild test"
    # enumerate the .debs in ../imath
    DEBS=$(ls -1 ../imath/*.deb | tr '\n' ' ')
    ## add the .debs to the sbuild command line with --extra-package
    EXTRA_PACKAGES=""
    for deb in $DEBS; do
      EXTRA_PACKAGES="$EXTRA_PACKAGES --extra-package=$deb"
    done

    # Pin the local --extra-package repo above the archive. Our rebuilds share
    # the same base version as the archive's binNMUs (e.g. 3.4.6+ds-4 vs the
    # archive's 3.4.6+ds-4+b2), so apt's default resolver would prefer the
    # higher-versioned archive binNMU (still linked against the old imath) and
    # fail against --add-conflicts. Local file/copy repos match origin "", and
    # priority 1001 lets apt "downgrade" to our rebuilds.
    PIN_LOCAL='printf "Package: *\nPin: origin \"\"\nPin-Priority: 1001\n" > /etc/apt/preferences.d/local-rebuilds.pref'

    sbuild --no-clean-source -d experimental $EXTRA_PACKAGES \
      --chroot-setup-commands="$PIN_LOCAL" \
      --add-conflicts="libimath-3-1-29t64"  )
done
