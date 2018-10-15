#!/usr/bin/env bash
# base.sh

# Functions ###########################################

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function is_sudo() {
    [[ "$(id -u)" -eq 0 ]]
}


function check_dependencies() {
    local pkg
    for pkg in "${DEPENDENCIES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" | awk '{print $3}' | grep -q "^installed$"; then
            echo "WHOOPS! The '$pkg' package is not installed!"
            echo "Would you like to install it now?"
            local options=("Yes" "No")
            local option
            select option in "${options[@]}"; do
                case "$option" in
                    Yes)
                        if ! which apt-get > /dev/null; then
                            log "ERROR: Can't install '$pkg' automatically. Try to install it manually." >&2
                            exit 1
                        else
                            if sudo apt-get install "$pkg"; then
                                log "YIPPEE! The '$pkg' package installation was successfull!"
                            fi
                            break
                        fi
                        ;;
                    No)
                        log "ERROR: Can't launch the script if the '$pkg' package is not installed." >&2
                        exit 1
                        ;;
                    *)
                        echo "Invalid option. Choose a number between 1 and ${#options[@]}." >&2
                        ;;
                esac
            done
        fi
    done
}


function restart_ES() {
    local restart_file="/tmp/es-restart"
    touch "$restart_file"
    chown -R "$user":"$user" "$restart_file"
    kill $(pidof emulationstation)
}


function log() {
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        echo "$*" >> "$LOG_FILE"
    else
        echo "$*"
    fi
}


function check_argument() {
    # This method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Try '$0 --help' for more info." >&2
        echo >&2
        return 1
    fi
}


function usage() {
    echo
    underline "$SCRIPT_TITLE"
    echo "$SCRIPT_DESCRIPTION"
    echo
    echo
    echo "USAGE: sudo $0 [OPTIONS]"
    echo
    echo "Use 'sudo $0 --help' to see all the options."
    echo
    exit 0
}


function underline() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a string as an argument!" >&2
        exit 1
    fi
    local dashes
    local message="$1"
    [[ "$GUI_FLAG" -eq 1 ]] && log "$message" || echo "$message"
    for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done
    [[ "$GUI_FLAG" -eq 1 ]] && log "$dashes" || echo "$dashes"
}


function trim() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a string as an argument!" >&2
        exit 1
    fi
    local string="$1"
    echo "${string}" | sed -e 's/^[[:space:]]*//'
}


function is_mandatory_field() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a string as an argument!" >&2
        exit 1
    fi
    [[ "$1" == "name" || "$1" == "path" || "$1" == "extension" || "$1" == "command"  ]] && return 0
}


function has_space {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a string as an argument!" >&2
        exit 1
    fi
    [[ "$1" != "${1%[[:space:]]*}" ]] && return 0 || return 1
}


function join_by() {
    #Usage example: join_by , a b c
    local IFS="$1"
    shift
    echo "$*"
}
