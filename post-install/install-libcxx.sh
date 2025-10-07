#!/bin/bash
set -euo pipefail

# This script creates the necessary symlinks for libc++, libc++abi, and libunwind in /usr/lib
# to match the standard library layout expected by applications

ROOTFS="/staging-rootfs"

# Process libc++, libc++abi, and libunwind libraries
for pattern in "libc++*.so.*.*.*" "libc++abi*.so.*.*.*" "libunwind*.so.*.*.*"; do
    for lib in "${ROOTFS}"/usr/lib/*-linux-gnu/${pattern}; do
        # Check if the glob matched any files
        [ -e "$lib" ] || continue
        
        if [ -f "$lib" ] || [ -L "$lib" ]; then
            # Get the base name (e.g., libc++.so.1.0.20)
            libname=$(basename "$lib")
            
            # Extract the SONAME (e.g., libc++.so.1 from libc++.so.1.0.20)
            # This assumes the format is libname.so.MAJOR.MINOR.PATCH
            if [[ $libname =~ ^(.*\.so\.[0-9]+)\.[0-9]+\.[0-9]+$ ]]; then
                soname="${BASH_REMATCH[1]}"
                libdir=$(dirname "$lib")
                
                # Create symlink from SONAME to full version
                # e.g., libc++.so.1 -> libc++.so.1.0.20
                if [ ! -e "${libdir}/${soname}" ]; then
                    echo "Creating symlink: ${libdir}/${soname} -> ${libname}"
                    ln -sf "$libname" "${libdir}/${soname}"
                fi
            fi
        fi
    done
done

echo "libcxx, libc++abi, and libunwind symlinks created successfully"
