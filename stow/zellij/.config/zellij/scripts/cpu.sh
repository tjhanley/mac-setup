#!/bin/sh
cores=$(sysctl -n hw.ncpu)
ps -A -o %cpu | awk -v c="$cores" 'NR>1{s+=$1}END{printf "%3d%%",s/c}'
