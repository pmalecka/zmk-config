#!/usr/bin/env bash

# IF YOU EDIT THIS FILE, THE DOCKER IMAGE NEEDS TO BE DELETED

set -eu

PWD=$(pwd)
TIMESTAMP="${TIMESTAMP:-$(date +"%Y%m%d-%H%M%S-%Z")}"
COMMIT="${COMMIT:-$(echo xxxxxx)}"

yaml2json "${PWD}/build.yaml" | jq -c '.include[]' | while read -r item; do
  board=$(echo "$item" | jq -r '.board')
  shield=$(echo "$item" | jq -r '.shield')
  cmake_args=$(echo "$item" | jq -r '.["cmake-args"] // empty')
  artifact_name=$(echo "$item" | jq -r '.["artifact-name"] // empty')
  snippet=$(echo "$item" | jq -r '.["snippet"] // empty')
  tags=$(echo "$item" | jq -r '.["tags"] // empty')

  echo "Board: $board"
  echo "Shield: $shield"
  if [[ -n "$cmake_args" ]]; then
    echo "CMake Args: $cmake_args"
  fi
  if [[ -n "$snippet" ]]; then
    echo "Snippet: $snippet"
  fi

  artifact_name=${artifact_name:-${shield:+$(echo "${shield}" | cut -d ' ' -f1)-}${board}-zmk}
  extra_cmake_args=${shield:+-DSHIELD=$shield}
  expanded_cmake_args=""
  if [ -n "${cmake_args}" ]; then
    eval "expanded_cmake_args=($cmake_args)"
  fi

  extra_west_args=""
  if [ -n "${snippet}" ]; then
    extra_west_args="-S ${snippet}"
  fi

  # Split tags string into an array by spaces
  if [[ -n "$tags" ]]; then
    # Read tags into an array splitting on spaces
    read -r -a tags_array <<< "$tags"

    echo "Tags: $tags"
    for tag in "${tags_array[@]}"; do
      uppercase_tag=$(echo "$tag" | tr '[:lower:]' '[:upper:]')
      env_var_name="BUILD_$uppercase_tag"
      if [ "${!env_var_name:-}" = true ] || [ "${BUILD_ALL:-}" = true ] ; then
        echo "Found - $tag, building.."
        west update
        # West Build (dynamic)
        # west build -p=always -s zmk/app -d "build/${artifact_name}" -b "${board}" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield}" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi"
        echo west build -p=always -s zmk/app -d "build/${artifact_name}" -b "${board}" "${extra_west_args}" -- -DZMK_CONFIG="${PWD}/config" "${extra_cmake_args}" "${expanded_cmake_args}"
        west build -p=always -s zmk/app -d "build/${artifact_name}" -b "${board}" "${extra_west_args}" -- -DZMK_CONFIG="${PWD}/config" "${extra_cmake_args}" "${expanded_cmake_args}"
        # Left Kconfig file
        grep -vE '(^#|^$)' "build/${artifact_name}/zephyr/.config"
        # Rename zmk.uf2
        cp "build/${artifact_name}/zephyr/zmk.uf2" "./firmware/$(echo "${shield}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-${artifact_name}.uf2"
        # don't build again, it is sufficient if only one tag matches..
        break
      fi
    done
  fi

#   # West Build (dynamic)
#   # west build -p=always -s zmk/app -d "build/${artifact_name}" -b "${board}" -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield}" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi"
#   west build -p=always -s zmk/app -d "build/${artifact_name}" -b "${board}" "${extra_west_args}" -- -DZMK_CONFIG="${PWD}/config" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi" "${extra_cmake_args}" "${cmake-args}"
#   # Left Kconfig file
#   grep -vE '(^#|^$)' "build/${artifact_name}/zephyr/.config"
#   # Rename zmk.uf2
#   cp "build/${artifact_name}/zephyr/zmk.uf2" "./firmware/$(echo "${shield}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-left.uf2"

  echo "------end of buid ${artifact_name}------"
done

# # Build left side if selected
# if [ "${BUILD_LEFT}" = true ]; then
#     # West Build (left)
#     west build -p=always -s zmk/app -d build/left -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_left}" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi" # -DZMK_EXTRA_MODULES="${PWD}"
#     # Left Kconfig file
#     grep -vE '(^#|^$)' build/left/zephyr/.config
#     # Rename zmk.uf2
#     cp build/left/zephyr/zmk.uf2 "./firmware/$(echo "${shield_left}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-left.uf2"
# fi

# # Build right side if selected
# if [ "${BUILD_RIGHT}" = true ]; then
#     # West Build (right)
#     west build -p=always -s zmk/app -d build/right -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_right}" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi"
#     # Right Kconfig file
#     grep -vE '(^#|^$)' build/right/zephyr/.config
#     # Rename zmk.uf2
#     cp build/right/zephyr/zmk.uf2 "./firmware/$(echo "${shield_right}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-right.uf2"
# fi

# # Build settings reset if selected
# if [ "${BUILD_SETTINGS_RESET_KBD}" = true ]; then
#     # West Build (right)
#     west build -s zmk/app -d build/settings_reset_kbd -b nice_nano_v2 -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_settings_reset_kbd}"
#     # Right Kconfig file
#     grep -vE '(^#|^$)' build/settings_reset_kbd/zephyr/.config
#     # Rename zmk.uf2
#     cp build/settings_reset_kbd/zephyr/zmk.uf2 "./firmware/$(echo "${shield_settings_reset_kbd}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-kbd-settings_reset.uf2"
# fi

# # Build settings reset if selected
# if [ "${BUILD_SETTINGS_RESET_DONGLE}" = true ]; then
#     # West Build (right)
#     west build -s zmk/app -d build/settings_reset_dongle -b seeeduino_xiao_ble -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_settings_reset_dongle}"
#     # Adv360 Right Kconfig file
#     grep -vE '(^#|^$)' build/settings_reset_dongle/zephyr/.config
#     # Rename zmk.uf2
#     cp build/settings_reset_dongle/zephyr/zmk.uf2 "./firmware/$(echo "${shield_settings_reset_dongle}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-dongle-settings_reset.uf2"
# fi

# # Build dongle if selected
# if [ "${BUILD_DONGLE}" = true ]; then
#     # West Build (dongle), with usb logging
#     west update
#     west build -p always -s zmk/app -d build/dongle -b seeeduino_xiao_ble -S zmk-usb-logging -- -DZMK_CONFIG="${PWD}/config" -DSHIELD="${shield_dongle}" -DEXTRA_DTC_OVERLAY_FILE="${PWD}/config/secrets.dtsi"
#     # Adv360 Right Kconfig file
#     grep -vE '(^#|^$)' build/dongle/zephyr/.config
#     # Rename zmk.uf2
#     cp build/dongle/zephyr/zmk.uf2 "./firmware/$(echo "${shield_dongle}" | cut -d ' ' -f1)-${TIMESTAMP}-${COMMIT}-dongle.uf2"
# fi
