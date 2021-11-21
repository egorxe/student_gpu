#!/usr/bin/env bash

set -e

# Write your sources here (order is resolved automaticaly)
TOP="M4_mul_V4_tb"
SOURCES_BASEPATH=".."
SOURCES="fpu100.vhd M4_mul_V4_pack.vhd M4_mul_V4.vhd M4_mul_V4_tb.vhd"

# Some generic defines
export TIME="1us"
export SHOWWAVE=1

# Prepend dir names to sources
DIRSOURCES=""
for s in $SOURCES ; do
    DIRSOURCES+="$SOURCES_BASEPATH/$s "
done

TOP=$TOP ghdl.sh $DIRSOURCES