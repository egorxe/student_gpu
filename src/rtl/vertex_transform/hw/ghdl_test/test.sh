#!/usr/bin/env bash

set -e

# Write your sources here (order is resolved automaticaly)
TOP="vertex_transform_trivial_tb"
SOURCES_BASEPATH=".."
SOURCES="../pkg/*.vhd */*.vhd *.vhd"

# Some generic defines
export TIME="15us"
export SHOWWAVE=1

# Prepend dir names to sources
DIRSOURCES=""
for s in $SOURCES ; do
    DIRSOURCES+="$SOURCES_BASEPATH/$s "
done

TOP=$TOP ghdl.sh $DIRSOURCES