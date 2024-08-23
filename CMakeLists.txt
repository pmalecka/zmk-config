if (NOT EXISTS "${ROOT}/config/secrets.dtsi")
    add_definitions(-DNO_SECRETS)
endif()