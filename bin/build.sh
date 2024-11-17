#!/usr/bin/env bash

# IF YOU EDIT THIS FILE, THE DOCKER IMAGE NEEDS TO BE DELETED

set -eu

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date +"%Y%m%d-%H%M%S-%Z")}"
COMMIT="${COMMIT:-$(echo xxxxxx)}"
build_matrix_json=$(yaml2json "${PWD}/build.yaml" | jq)
shield_left=$(echo "$build_matrix_json" | jq -r '.include[0].shield')
shield_right=$(echo "$build_matrix_json" | jq -r '.include[1].shield')
shield_settings_reset=$(echo "$build_matrix_json" | jq -r '.include[2].shield')

# Build left side if selected
if [ "${BUILD_LEFT}" = true ]; then
    # West Build (left)
    west build -p=always -s zmk/app -d build/left -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_left}" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi"
    # Adv360 Left Kconfig file
    grep -vE '(^#|^$)' build/left/zephyr/.config
    # Rename zmk.uf2
    cp build/left/zephyr/zmk.uf2 "./firmware/$(echo "${shield_left}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-left.uf2"
fi

# Build right side if selected
if [ "${BUILD_RIGHT}" = true ]; then
    # West Build (right)
    west build -p=always -s zmk/app -d build/right -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_right}" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi"
    # Adv360 Right Kconfig file
    grep -vE '(^#|^$)' build/right/zephyr/.config
    # Rename zmk.uf2
    cp build/right/zephyr/zmk.uf2 "./firmware/$(echo "${shield_right}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-right.uf2"
fi

# Build settings reset if selected
if [ "${BUILD_SETTINGS_RESET}" = true ]; then
    # West Build (right)
    west build -s zmk/app -d build/settings_reset -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_settings_reset}"
    # Adv360 Right Kconfig file
    grep -vE '(^#|^$)' build/settings_reset/zephyr/.config
    # Rename zmk.uf2
    cp build/settings_reset/zephyr/zmk.uf2 "./firmware/$(echo "${shield_settings_reset}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-settings_reset.uf2"
fi