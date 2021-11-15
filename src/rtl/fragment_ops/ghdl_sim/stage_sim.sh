#!/usr/bin/env bash

set -e

# Write your sources here (order is resolved automaticaly)
TOP="fragment_ops"
SOURCES_BASEPATH=".."
#SOURCES="test_vertices.vhd test_vertices_fifotb.vhd"
SOURCES="fragmentops.vhd"
PACKAGES="gpu_pkg.vhd file_helper_pkg.vhd"

# Some generic defines
export TIME="100000ms"
export SHOWWAVE=0
FIFO_IN="in.fifo"
FIFO_OUT="out.fifo"

# Change directory & link fifo files
ORIGPATH=$(pwd)
cd $(dirname $0)
rm -f "$FIFO_IN" "$FIFO_OUT"
ln -s "$ORIGPATH/$3" "$FIFO_IN"
ln -s "$ORIGPATH/$4" "$FIFO_OUT"

# Prepend dir names to sources
DIRSOURCES=""
for s in $SOURCES ; do
    DIRSOURCES+="$SOURCES_BASEPATH/$s "
done

PACKAGES_BASEPATH="../../pkg"
DIRPACKAGES=""
for s in $PACKAGES ; do
    DIRPACKAGES+="$PACKAGES_BASEPATH/$s "
done

TOP=$TOP ghdl.sh $DIRPACKAGES $DIRSOURCES
