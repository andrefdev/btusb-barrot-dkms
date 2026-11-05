#!/bin/bash
# Build btusb with the same compiler as the kernel (clang or gcc)
set -e
cd "$(dirname "$(readlink -f "$0")")"
ksrc="$1"
llvm=""
grep -q '^CONFIG_CC_IS_CLANG=y' "$ksrc/.config" && llvm="LLVM=1"
make -C "$ksrc" M="$PWD" $llvm modules
