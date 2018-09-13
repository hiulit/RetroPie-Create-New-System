#!/usr/bin/env bash
# retropie-create-new-system.sh
#
# RetroPie Create New System
# A tool for RetroPie to create new systems for EmulationStation.
#
# Author: hiulit
# Repository: https://github.com/hiulit/RetroPie-Create-New-System
# License: MIT License https://github.com/hiulit/RetroPie-Create-New-System/blob/master/LICENSE
#
# Requirements:
# - RetroPie 4.x.x

# Globals ####################################################################

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"

home="$(eval echo ~$user)"

readonly RP_DIR="$home/RetroPie"
readonly RP_CONFIG_DIR="/opt/retropie/configs"
readonly RP_ROMS_DIR="$RP_DIR/roms"
readonly ES_SYSTEMS_CFG="/etc/emulationstation/es_systems.cfg"
readonly USER_ES_SYSTEM_CFG="$RP_CONFIG_DIR/all/emulationstation/es_systems.cfg"

readonly SCRIPT_VERSION="0.0.1"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_TITLE="RetroPie Homebrew and Hacks"
readonly SCRIPT_DESCRIPTION="[SCRIPT_DESCRIPTION]"


# Variables ##################################################################

SYSTEM_NAME="hh"
SYSTEM_FULLNAME="Homebrew and Hacks"
SYSTEM_PATH="$RP_ROMS_DIR/hh"
SYSTEM_EXTENSION=".nes .zip .NES .ZIP"
SYSTEM_COMMAND="/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ hh %ROM%"
SYSTEM_PLATFORM=""
system_theme="hh"

SYSTEM_PROPERTIES=(
    "name $SYSTEM_NAME"
    "fullname $SYSTEM_FULLNAME"
    "path $SYSTEM_PATH"
    "extension $SYSTEM_EXTENSION"
    "command $SYSTEM_COMMAND"
    "platform $SYSTEM_PLATFORM"
    "theme $system_theme"
)

emulators=("nes" "snes")


# Functions ##################################################################

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
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
    echo "USAGE: $0 [OPTIONS]"
    echo
    echo "Use '$0 --help' to see all the options."
}


function underline() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a message as an argument!" >&2
        exit 1
    fi
    local dashes
    local message="$1"
    echo "$message"
    for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
}


function copy_es_systems_cfg() {
    echo
    echo "> Copying '$(basename "$ES_SYSTEMS_CFG")' ..."
    if [[ ! -f "$USER_ES_SYSTEM_CFG" ]]; then
        cp "$ES_SYSTEMS_CFG" "$USER_ES_SYSTEM_CFG"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "$(basename "$ES_SYSTEMS_CFG") copied successfully!"
        else
            echo "ERROR: Couldn't copy $(basename "$ES_SYSTEMS_CFG")" >&2
        fi
    else
        echo "Custom '$(basename "$USER_ES_SYSTEM_CFG")' already exists ... Move along!"
    fi
}


function update_system() {
    echo
    echo "> Updating values for system '$SYSTEM_NAME' ..."
    local message="New values for '$SYSTEM_NAME':"
    underline "$message"
    for system_property in "${SYSTEM_PROPERTIES[@]}"; do
        key="$(echo $system_property | grep  -Eo "^[^ ]+")"
        value="$(echo $system_property | grep -Po "(?<= ).*")"
        if [[ -n "$value" ]]; then
            xmlstarlet ed -L -u "/systemList/system[name='$SYSTEM_NAME']/$key" -v "$value" "$USER_ES_SYSTEM_CFG"
        fi
        echo "$key: $value"
    done
    dashes=
    for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
}


function create_system_roms_dir() {
    echo
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a path as an argument!" >&2
        exit 1
    fi
    local path="$1"
    echo "> Creating '$path' ..."
    if [[ ! -d "$path" ]]; then
        mkdir -p "$value"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "'$path' created successfully!"
        else
            echo "ERROR: Couldn't create '$path'." >&2
        fi
    else
        echo "'$path' already exists ... Move along!"
    fi
}


function create_new_system() {
    echo
    echo "> Creating system '$SYSTEM_NAME' ..."
    # Check if <system> exists
    if xmlstarlet sel -t -v "/systemList/system[name='$SYSTEM_NAME']" "$USER_ES_SYSTEM_CFG" > /dev/null; then
        echo "System '$SYSTEM_NAME' already exists in custom '$(basename "$USER_ES_SYSTEM_CFG")'."
        echo
        local message="Current '$SYSTEM_NAME' values:"
        underline "$message"
        for system_property in "${SYSTEM_PROPERTIES[@]}"; do
            key="$(echo $system_property | grep  -Eo "^[^ ]+")"
            value="$(echo $system_property | grep -Po "(?<= ).*")"
            #~ if [[ -n "$value" ]]; then
                echo "$key: $value"
            #~ fi
        done
        dashes=
        for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
        echo
        echo "Would you like to update '$SYSTEM_NAME' values?"
        local options=("Yes" "No")
        local option
        select option in "${options[@]}"; do
            case "$option" in
                Yes)
                    update_system
                    local return_value
                    return_value="$?"
                    if [[ "$return_value" -eq 0 ]]; then
                        echo "Values for '$SYSTEM_NAME' updated successfully!"
                    else
                        echo "ERROR: Couldn't update values for '$SYSTEM_NAME'" >&2
                    fi
                    break
                    ;;
                No)
                    break
                    ;;
                *)
                    echo "Invalid option. Choose a number between 1 and ${#options[@]}."
                    ;;
            esac
        done
    else
        # Create a new <system> called "newSystem"
        xmlstarlet ed -L -s "/systemList" -t elem -n "newSystem" -v "" "$USER_ES_SYSTEM_CFG"
        # Add subnodes to <newSystem>
        for system_property in "${SYSTEM_PROPERTIES[@]}"; do
            local key
            local value
            key="$(echo $system_property | grep  -Eo "^[^ ]+")"
            value="$(echo $system_property | grep -Po "(?<= ).*")"
            # Check for missing name, path, extension or command.
            if [[ "$key" == "name" || "$key" == "path" || "$key" == "extension" || "$key" == "command"  ]]; then
                if [[ -z "$key" ]]; then
                    echo "ERROR: System '$SYSTEM_NAME' is missing name, path, extension or command!" >&2
                    xmlstarlet ed -L -d "/systemList/newSystem"  "$USER_ES_SYSTEM_CFG"
                    exit 1
                fi
            fi
            if [[ -n "$value" ]]; then
                xmlstarlet ed -L -s "/systemList/newSystem" -t elem -n "$key" -v "$value" "$USER_ES_SYSTEM_CFG"
                if [[ "$key" == "path" ]]; then
                    create_system_roms_dir "$value"
                fi
            fi
        done
        # Rename <newSystem> to <system>
        xmlstarlet ed -L -r "/systemList/newSystem" -v "system" "$USER_ES_SYSTEM_CFG"
        echo
        echo "System '$SYSTEM_NAME' created successfully!"
    fi
}

function remove_system() {
    echo
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a system as an argument!" >&2
        exit 1
    fi
    local system="$1"
    echo "> Removing '$system' ..."
    if xmlstarlet sel -t -v "/systemList/system[name='$system']" "$USER_ES_SYSTEM_CFG" > /dev/null; then
        xmlstarlet ed -d "//system[name='$system']" "$USER_ES_SYSTEM_CFG"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "System '$system' removed successfully!"
        else
            echo "ERROR: Couldn't remove system '$system'."
        fi
    else
        echo "ERROR: Couldn't remove system '$system'. It doesn't exist!" >&2
    fi
}

#~ xmlstarlet sel -t -v "/systemList/system[name='hh']" "$USER_ES_SYSTEM_CFG"
#~ exit

#~ remove_system "hh"
#~ exit


#~ function create_symbolic_link() {
    #~ ln -s "$RP_ROMS_DIR/$system/$rom" "$RP_ROMS_DIR/$user_system/$rom"
#~ }


#~ function update_system_emulators_cfg() {
    
#~ }


function create_system_emulators_cfg() {
    echo
    echo "> Creating '$RP_CONFIG_DIR/$SYSTEM_NAME' ..."
    if [[ ! -d "$RP_CONFIG_DIR/$SYSTEM_NAME" ]]; then
        mkdir -p "$RP_CONFIG_DIR/$SYSTEM_NAME"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "'$RP_CONFIG_DIR/$SYSTEM_NAME' created successfully!"
        else
            echo "ERROR: Couldn't create '$RP_CONFIG_DIR/$SYSTEM_NAME'." >&2
        fi
        
        touch "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "'$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg' created successfully!"
        else
            echo "ERROR: Couldn't create '$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg'." >&2
        fi
    else
        echo "'$RP_CONFIG_DIR/$SYSTEM_NAME' already exists ... Move along!"
    fi
}


function add_emulators_to_system_emulators_cfg() {
    echo
    echo "> Adding emulators to '$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg' ..."
    for emulator in "${emulators[@]}"; do
        echo "> Adding '$emulator' ..."
        cat "$RP_CONFIG_DIR/$emulator/emulators.cfg" >> "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "'$emulator' added successfully!"
        else
            echo "ERROR: Couldn't add '$emulator'." >&2
        fi
        # Remove 'default' emulators
        sed -i '/default/d' "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
    done
    # Remove duplicated lines
    local remove_duplicates
    remove_duplicates="$(awk '!a[$0]++' "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg")"
    echo "$remove_duplicates" > "$RP_CONFIG_DIR/$SYSTEM_NAME/emulators.cfg"
}


copy_es_systems_cfg
create_new_system
create_system_emulators_cfg
add_emulators_to_system_emulators_cfg
exit


function get_options() {
    if [[ -z "$1" ]]; then
        usage
        exit 0
    else
        case "$1" in
#H -h, --help                   Print the help message and exit.
            -h|--help)
                echo
                underline "$SCRIPT_TITLE"
                echo "$SCRIPT_DESCRIPTION"
                echo
                echo "USAGE: $0 [OPTIONS]"
                echo
                echo "OPTIONS:"
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H -v, --version                Show script version.
            -v|--version)
                echo "$SCRIPT_VERSION"
                ;;
            *)
                echo "ERROR: invalid option '$1'" >&2
                exit 2
                ;;
        esac
    fi
}

function main() {
    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi

    check_dependencies

    get_options "$@"
}

main "$@"
