#!/bin/bash
set -e -o nounset

DST_DIR="$1"
VERSION="$2"

mkdir -p "$DST_DIR"

SRC_DIR="src/"

NESTED_FILES=("c25519/f25519" "c25519/fprime" "c25519/sha512" "c25519/c25519" "c25519/ed25519" "c25519/edsign" )
COMPACT_FILES=(compact_x25519 compact_ed25519 compact_wipe)


DST_HEADER="$DST_DIR/compact25519.h"
DST_SOURCE="$DST_DIR/compact25519.c"

function remove_header_guard() {
    # we reverse lines so that it is easier to detect the last endif to drop
    tac | \
        awk '
        BEGIN{LAST_END_FOUND=0;} 
        /#endif/ && !LAST_END_FOUND { LAST_END_FOUND=1; next; } 
        /#.*_H_*$/ { next; }
        42
        ' | \
        tac
}

function remove_local_imports() {
    sed 's/#include ".*h"//'
}

function merge_includes() {
    awk '
    /#include .*/ { includes[$0] = 1; next;}
    { other[NR] = $0; next; }
    END {
        for (i in includes) {
            print i;
        }
        for (i in other) {
            print other[i];
        }
    }
    '
}

function remove_double_blank_lines() {
    cat -s
}

echo "// compact25519 $VERSION
// Licensed under CC0-1.0
// Based on Daniel Beer's Public Domain C25519 implementation
#ifndef __COMPACT_25519_H
#define __COMPACT_25519_H
" > "$DST_HEADER"

for h in "${COMPACT_FILES[@]}"; do 
    cat "$SRC_DIR/$h.h" | remove_header_guard 
done | merge_includes | remove_double_blank_lines >> "$DST_HEADER" 

echo "#endif" >> "$DST_HEADER"


echo "// compact25519 $VERSION
// Licensed under CC0-1.0
// Based on Daniel Beer's Public Domain C25519 implementation
#include \"compact25519.h\"
" > "$DST_SOURCE"

for h in "${NESTED_FILES[@]}"; do 
    echo "// ******* BEGIN: $h.h ********" >> "$DST_SOURCE"
    cat "$SRC_DIR/$h.h" | remove_header_guard | remove_local_imports | remove_double_blank_lines>> "$DST_SOURCE"
    echo "// ******* END:   $h.h ********" >> "$DST_SOURCE"
done

for h in "${NESTED_FILES[@]}"; do 
    echo "// ******* BEGIN: $h.c ********" >> "$DST_SOURCE"
    cat "$SRC_DIR/$h.c" | remove_local_imports | remove_double_blank_lines >> "$DST_SOURCE"
    echo "// ******* END:   $h.c ********" >> "$DST_SOURCE"
done


for h in "${COMPACT_FILES[@]}"; do 
    echo "// ******* BEGIN: $h.c ********" >> "$DST_SOURCE"
    cat "$SRC_DIR/$h.c" | remove_local_imports | remove_double_blank_lines >> "$DST_SOURCE"
    echo "// ******* END: $h.c ********" >> "$DST_SOURCE"
done