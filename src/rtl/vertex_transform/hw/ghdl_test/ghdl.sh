#!/usr/bin/env bash

set -e

if [ -z $TIME ]; then
    TIME="1ms"
fi

# wave stuff
WAVE=wave.ghw
if [ -z "$SAVEWAVE" ]; then
    SAVEWAVE="$SHOWWAVE"
fi
if [ "$SHOWWAVE" == "1" ]; then
    WAVEOPT="--wave=$WAVE"
    SAVEWAVE="1"
fi

# import & make all files
ghdl -i --std=08 -fsynopsys "$@"
ghdl -m --std=08 -fsynopsys "$TOP"

# run simulation
set +e
ghdl -r --std=08 -fsynopsys "$TOP" $WAVEOPT --stop-time="$TIME" --ieee-asserts=disable

if [ "$SHOWWAVE" == "1" ]; then
    sleep 1
    gtkwave $WAVE
fi
