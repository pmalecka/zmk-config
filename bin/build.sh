#!/usr/bin/env bash

# IF YOU EDIT THIS FILE, THE DOCKER IMAGE NEEDS TO BE DELETED

set -eu

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date +"%Y%m%d-%H%M%S-%Z")}"
COMMIT="${COMMIT:-$(echo xxxxxx)}"
build_matrix_file="${PWD}/build.json"
shield_left=$(jq -r '.include[0].shield' "${build_matrix_file}")
shield_right=$(jq -r '.include[1].shield' "${build_matrix_file}")

# West Build (left)
west build -s zmk/app -d build/left -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_left}"
# Adv360 Left Kconfig file
grep -vE '(^#|^$)' build/left/zephyr/.config
# Rename zmk.uf2
cp build/left/zephyr/zmk.uf2 "./firmware/$(echo "${shield_left}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-left.uf2"

# Build right side if selected
if [ "${BUILD_RIGHT}" = true ]; then
    # West Build (right)
    west build -s zmk/app -d build/right -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_right}"
    # Adv360 Right Kconfig file
    grep -vE '(^#|^$)' build/right/zephyr/.config
    # Rename zmk.uf2
    cp build/right/zephyr/zmk.uf2 "./firmware/$(echo "${shield_right}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-right.uf2"
fi
