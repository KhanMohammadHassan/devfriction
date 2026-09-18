#!/usr/bin/env bash

classify_binding() {
    local binding="$1"

    # Normalize common address formatting.
    binding="${binding#[}"
    binding="${binding%]}"
    binding="${binding%%\%*}"

    case "$binding" in
        127.*|::1|localhost)
            printf '%s\n' "loopback"
            ;;

        0.0.0.0|::|\*)
            printf '%s\n' "all-interfaces"
            ;;

        169.254.*|fe80:*|FE80:*)
            printf '%s\n' "link-local"
            ;;

        "")
            printf '%s\n' "unknown"
            ;;

        *)
            printf '%s\n' "interface-bound"
            ;;
    esac
}