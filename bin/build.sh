#!/usr/bin/env bash

# IF YOU EDIT THIS FILE, THE DOCKER IMAGE NEEDS TO BE DELETED

set -eu

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date -u +"%Y%m%d%H%M")}"
COMMIT="${COMMIT:-$(echo xxxxxx)}"
build_matrix_file="${PWD}/build.json"

# West Build (left)
west build -s zmk/app -d build/left -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="$(jq -r '.include[0].shield' "${build_matrix_file}")"
# Adv360 Left Kconfig file
grep -vE '(^#|^$)' build/left/zephyr/.config
# Rename zmk.uf2
cp build/left/zephyr/zmk.uf2 "./firmware/${TIMESTAMP}-${COMMIT}-left.uf2"

# Build right side if selected
if [ "${BUILD_RIGHT}" = true ]; then
    # West Build (right)
    west build -s zmk/app -d build/right -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="$(jq -r '.include[1].shield' "${build_matrix_file}")"
    # Adv360 Right Kconfig file
    grep -vE '(^#|^$)' build/right/zephyr/.config
    # Rename zmk.uf2
    cp build/right/zephyr/zmk.uf2 "./firmware/${TIMESTAMP}-${COMMIT}-right.uf2"
fi
