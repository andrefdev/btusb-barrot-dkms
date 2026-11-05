#!/bin/bash
# Fetch btusb.c for a kernel version and apply the Barrot patch.
#
#   fetch-src.sh KVER             (DKMS PRE_BUILD) leave a patched btusb.c here
#   fetch-src.sh --prefetch KVER  only store the sources in the cache
#
# pacman runs its hooks, and DKMS with them, without network access. That is
# why 60-btusb-barrot-fetch.hook, which is allowed network access, calls
# --prefetch first, and the DKMS build takes the exact sources from the cache.
#
# If they are not cached: kernel.org (stable and torvalds trees), the GitHub
# mirror of the stable tree (gregkh), and as a last resort a cached copy from
# the same series (7.3.x for a 7.3.y kernel). Never from another series:
# btintel.h, btrtl.h, etc. must match the kernel's modules, and their exported
# functions can change between series.
set -e
prefetch=
[ "$1" = --prefetch ] && { prefetch=1; shift; }
here="$(dirname "$(readlink -f "$0")")"
kver="$1"
ver="${kver%%-*}"         # 7.2.8-arch1-1 -> 7.2.8
tag="v${ver%.0}"          # 7.3.0 -> v7.3
[[ $kver =~ -(rc[0-9]+) ]] && tag="$tag-${BASH_REMATCH[1]}"   # 7.4.0-rc2-1-mainline -> v7.4-rc2
series="${ver%.*}"        # 7.3.1 -> 7.3
cache=/var/cache/btusb-barrot
files="btusb.c btintel.h btbcm.h btrtl.h btmtk.h"
urls=(
	"https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/bluetooth/%s?h=$tag"
	"https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/drivers/bluetooth/%s?h=$tag"
	"https://raw.githubusercontent.com/gregkh/linux/$tag/drivers/bluetooth/%s"
)

download() {
	local url f
	for url in "${urls[@]}"; do
		for f in $files; do
			curl -sfL --retry 3 --retry-all-errors --connect-timeout 20 \
				-o "$f" "$(printf "$url" "$f")" || continue 2
		done
		return 0
	done
	return 1
}

save_cache() {
	mkdir -p "$cache/$tag" && cp $files "$cache/$tag/" && echo "$tag" > "$cache/$tag/VERSION"
}

# Copy the sources from the first directory that has all of them
use_copy() {
	local d f v
	for d in "$@"; do
		[ -f "$d/btusb.c" ] || continue
		for f in $files; do cp "$d/$f" .; done
		v=$(cat "$d/VERSION" 2>/dev/null || basename "$d")
		if [ "$v" = "$tag" ]; then
			echo "btusb-barrot: using $tag sources from $d"
		else
			echo "btusb-barrot: offline, using NON-EXACT copy $v for $tag (rebuilt with the exact one on the next boot with network)"
		fi
		return 0
	done
	return 1
}

if [ -n "$prefetch" ]; then
	if [ -f "$cache/$tag/btusb.c" ]; then
		echo "btusb-barrot: $tag sources already cached"
		exit 0
	fi
	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' EXIT
	cd "$tmp"
	download || { echo "btusb-barrot: could not download the $tag sources" >&2; exit 1; }
	save_cache
	echo "btusb-barrot: $tag sources cached"
	exit 0
fi

cd "$here"
if ! use_copy "$cache/$tag"; then
	if download; then
		save_cache 2>/dev/null || true
	else
		same_series=$(ls -d "$cache/v$series" "$cache/v$series".* 2>/dev/null | sort -rV)
		use_copy $same_series || {
			echo "btusb-barrot: could not download btusb.c for $tag and there is no cached $series copy" >&2
			exit 1
		}
	fi
fi

# Once the kernel ships its own Barrot fix, build btusb unpatched (same as the
# stock module) and let btusb-barrot-fix --hook say the package is obsolete.
if grep -qE '& *BTUSB_BARROT|BTUSB_BARROT *\||\| *BTUSB_BARROT' btusb.c; then
	echo "btusb-barrot: $tag already includes upstream Barrot support; building btusb unpatched"
else
	patch -p1 --forward --no-backup-if-mismatch < barrot.patch
fi
